$ErrorActionPreference = "Stop"

# ---- Paths
$ROOT    = "$env:USERPROFILE\Desktop\ONYX"
$STAMP   = Get-Date -Format 'yyyyMMdd_HHmmss'
$REVROOT = Join-Path $ROOT "reviews"
$OUT     = Join-Path $REVROOT ("mason_review_{0}" -f $STAMP)
$OUTLOG  = Join-Path $OUT "logs"
$OUTCFG  = Join-Path $OUT "configs"
$OUTTXT  = Join-Path $OUT "text"
$OUTSEC  = Join-Path $OUT "security"
$OUTSBOM = Join-Path $OUT "sbom"
$OUTTASK = Join-Path $OUT "tasks"

New-Item -ItemType Directory -Path $REVROOT,$OUT,$OUTLOG,$OUTCFG,$OUTTXT,$OUTSEC,$OUTSBOM,$OUTTASK -EA SilentlyContinue | Out-Null

# ---- Include (no heavy deps)
$INCLUDE_DIRS = @("mason-sidecar","onyx-backend","onyx-web","tools","security","VAULT\digest")

# ---- Ignore patterns
$Ignore     = '(?i)[\\/](node_modules|dist|build|\.venv|\.git|coverage|out|\.next|__pycache__|cache)([\\/]|$)'
$IgnoreFile = '(?i)\.(env|pem|key|pfx|p12|jks)$'
$IgnoreName = '(?i)(secret|token|password|credential|api[_-]?key)'

function Copy-SafeFolder {
  param([string]$BaseRel)
  $src = Join-Path $ROOT $BaseRel
  if(-not (Test-Path $src)){ return }
  $dest = Join-Path $OUT $BaseRel
  New-Item -ItemType Directory -Path $dest -EA SilentlyContinue | Out-Null
  Get-ChildItem -Path $src -Recurse -File -EA SilentlyContinue |
    Where-Object { $_.FullName -notmatch $Ignore -and $_.Name -notmatch $IgnoreName -and $_.Name -notmatch $IgnoreFile } |
    ForEach-Object {
      $rel = $_.FullName.Substring($src.Length).TrimStart('\','/')
      $to  = Join-Path $dest $rel
      New-Item -ItemType Directory -Path (Split-Path $to -Parent) -EA SilentlyContinue | Out-Null
      Copy-Item $_.FullName $to -Force
    }
}

foreach($d in $INCLUDE_DIRS){ Copy-SafeFolder $d }

# ---- Top-level control files
$TopKeep = @("flags.yaml","start-all.ps1","tools\start-all-lite.ps1","tools\MasonTray.ps1","mason-events.jsonl")
foreach($t in $TopKeep){
  $src = Join-Path $ROOT $t
  if(Test-Path $src){
    $dst = Join-Path $OUT $t
    New-Item -ItemType Directory -Path (Split-Path $dst -Parent) -EA SilentlyContinue | Out-Null
    Copy-Item $src $dst -Force
  }
}

# ---- Secrets listing only
$secretsDir = Join-Path $ROOT "secrets"
if(Test-Path $secretsDir){
  $list = Get-ChildItem $secretsDir -Recurse -File | ForEach-Object { $_.FullName.Substring($ROOT.Length+1) }
  $outList = Join-Path $OUTSEC "SECRETS_LIST_ONLY.txt"
  $list | Set-Content $outList -Encoding UTF8
}

# ---- Security bits
$canDir = Join-Path $ROOT "security\canaries"
if(Test-Path $canDir){
  $dst = Join-Path $OUTSEC "canaries"
  New-Item -ItemType Directory -Path $dst -EA SilentlyContinue | Out-Null
  Get-ChildItem $canDir -File | Copy-Item -Destination $dst -Force
}
$sops = Join-Path $ROOT ".sops.yaml"; if(Test-Path $sops){ Copy-Item $sops (Join-Path $OUTSEC ".sops.yaml") -Force }
$gitignore = Join-Path $ROOT ".gitignore"; if(Test-Path $gitignore){ Copy-Item $gitignore (Join-Path $OUTSEC ".gitignore") -Force }

# ---- Gitleaks summary (paths + rule only)
$gl = Get-ChildItem (Join-Path $ROOT "security") -Filter "gitleaks_*.json" | Sort-Object Name | Select-Object -Last 1
if($gl){
  try{
    $j = Get-Content $gl.FullName -Raw | ConvertFrom-Json
    $summary = @()
    if($j -and $j.findings){
      $summary += "Findings: " + ($j.findings.Count)
      $summary += ""
      $summary += ($j.findings | Select-Object -First 50 | ForEach-Object { "- $($_.File) :: $($_.RuleID)" })
    } else { $summary += "No structured findings or empty report." }
    $summary | Set-Content (Join-Path $OUTSEC "gitleaks_summary.txt") -Encoding UTF8
  } catch { Copy-Item $gl.FullName (Join-Path $OUTSEC $gl.Name) -Force }
}

# ---- SBOM / Trivy outputs if present (<20MB each)
$sb = Join-Path $ROOT "security\sbom"
if(Test-Path $sb){ Get-ChildItem $sb -File | Where-Object { $_.Length -lt 20MB } | Copy-Item -Destination $OUTSBOM -Force }

# ---- Tree + manifest
function Add-TreeAndManifest {
  param([string[]]$Roots, [string]$OutPrefix)
  $files = @()
  foreach($r in $Roots){
    $full = Join-Path $ROOT $r
    if(Test-Path $full){
      $files += Get-ChildItem -Path $full -Recurse -File -EA SilentlyContinue |
        Where-Object { $_.FullName -notmatch $Ignore -and $_.Name -notmatch $IgnoreFile -and $_.Name -notmatch $IgnoreName }
    }
  }
  $treePath = Join-Path $OUTTXT ("{0}_tree.txt" -f $OutPrefix)
  $files | ForEach-Object { $_.FullName.Substring($ROOT.Length+1) | Split-Path } |
    Sort-Object -Unique | Set-Content $treePath -Encoding UTF8
  $manifest = $files | ForEach-Object {
    [pscustomobject]@{ path=$_.FullName.Substring($ROOT.Length+1); bytes=$_.Length; sha256=(Get-FileHash -Algorithm SHA256 -Path $_.FullName).Hash; mtime=$_.LastWriteTimeUtc.ToString('s') }
  }
  $manPath = Join-Path $OUTTXT ("{0}_manifest.json" -f $OutPrefix)
  $manifest | ConvertTo-Json -Depth 4 | Set-Content $manPath -Encoding UTF8
}
Add-TreeAndManifest -Roots @("mason-sidecar","onyx-backend","onyx-web","tools") -OutPrefix "core"

# ---- Flags snapshot
$flags = Join-Path $ROOT "flags.yaml"; if(Test-Path $flags){ Copy-Item $flags (Join-Path $OUTCFG "flags.yaml") -Force }

# ---- Service status + versions
function PortPid($p){ (Get-NetTCPConnection -LocalPort $p -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty OwningProcess) }
function PStatus($p){ if(PortPid $p){ "up" } else { "down" } }
$svc = @"
Service Status:
- API :8000 = $(PStatus 8000)
- Web :5175 = $(PStatus 5175)
- Side:7000 = $(PStatus 7000)

Processes by port:
- 8000 PID: $(PortPid 8000)
- 5175 PID: $(PortPid 5175)
- 7000 PID: $(PortPid 7000)

Scheduled Tasks (name contains Snapshot/Watchdog):
$(schtasks /Query /FO LIST | Select-String -Pattern "Onyx_Daily_Snapshot|Projects_Daily_Snapshot|Watchdog|Mason" | ForEach-Object { $_.ToString() })
"@
$svc | Set-Content (Join-Path $OUTTXT "SERVICE_STATUS.txt") -Encoding UTF8

$vers = @()
try { $vers += "Python:  " + (& py -3 --version 2>$null) } catch {}
try { $vers += "Node:    " + (& node -v 2>$null) } catch {}
try { $vers += "NPM:     " + (& npm -v 2>$null) } catch {}
try { $vers += "SOPS:    " + (& sops --version 2>$null) } catch {}
try { $vers += "Gitleaks:" + (& gitleaks version 2>$null) } catch {}
try { $vers += "Syft:    " + ((& syft version 2>$null | Select-String -First 1).ToString()) } catch {}
try { $vers += "Trivy:   " + ((& trivy --version 2>$null | Select-String -First 1).ToString()) } catch {}
$vers | Set-Content (Join-Path $OUTTXT "VERSIONS.txt") -Encoding UTF8

# ---- Log tails (fixed: parentheses per element)
$LogCandidates = @(
  (Join-Path $ROOT "mason-sidecar\logs"),
  (Join-Path $ROOT "mason-sidecar"),
  (Join-Path $ROOT "mason-events.jsonl")
)
foreach($lc in $LogCandidates){
  if(Test-Path $lc){
    if(Test-Path $lc -PathType Container){
      Get-ChildItem $lc -File | Sort-Object LastWriteTime -Descending | Select-Object -First 5 | ForEach-Object {
        $tail = Get-Content $_.FullName -Tail 400
        $dest = Join-Path $OUTLOG ($_.Name + ".tail.txt")
        $tail | Set-Content $dest -Encoding UTF8
      }
    } else {
      $tail = Get-Content $lc -Tail 400
      $dest = Join-Path $OUTLOG ((Split-Path $lc -Leaf) + ".tail.txt")
      $tail | Set-Content $dest -Encoding UTF8
    }
  }
}

# ---- Quick summary
$sum = @()
$sum += "# Mason Review Summary"
$sum += ""
$sum += ("When: {0}" -f (Get-Date))
$sum += "Dirs included: mason-sidecar, onyx-backend, onyx-web, tools, security (no secrets content), VAULT\digest"
$sum += ""
$sum += "- See SERVICE_STATUS.txt for ports and tasks"
$sum += "- See VERSIONS.txt for tool versions"
$sum += "- See logs/*.tail.txt for last 400 lines"
$sum += "- See core_tree.txt and core_manifest.json"
$sum += "- Gitleaks summary under security/"
$sum | Set-Content (Join-Path $OUT "SUMMARY.md") -Encoding UTF8

# ---- Zip
$ZIP = Join-Path $REVROOT ("MasonReviewPack_{0}.zip" -f $STAMP)
if(Test-Path $ZIP){ Remove-Item $ZIP -Force }
Compress-Archive -Path $OUT -DestinationPath $ZIP

Write-Host "Pack ready:"
Write-Host "  $ZIP"
Write-Host ""
Write-Host "Attach the ZIP here. If upload is too big, paste:"
Write-Host "  $($OUT)\SUMMARY.md"
