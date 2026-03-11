# day0-secure.ps1
# Purpose: Day-0 hardening for the ONYX workspace.
# - Quarantine obvious plaintext secrets
# - Run a gitleaks scan
# - Set up SOPS + age for encrypted secrets
# - Create canary files
# - Scaffold SBOM and vuln scan helper
# Tested with Windows PowerShell 5.1

$ErrorActionPreference = "Stop"

# --- Paths --------------------------------------------------------------------
$ROOT    = Join-Path $env:USERPROFILE "Desktop\ONYX"
$TOOLS   = Join-Path $ROOT "tools"
$SECRETS = Join-Path $ROOT "secrets"
$SCAN    = Join-Path $ROOT "security"
$QUAR    = Join-Path $SCAN "quarantine"
$CANARY  = Join-Path $SCAN "canaries"

New-Item -ItemType Directory -Path $TOOLS,$SECRETS,$SCAN,$QUAR,$CANARY -ErrorAction SilentlyContinue | Out-Null

# --- Helper -------------------------------------------------------------------
function Try-Run($cmd, $onFail){
  try { & $cmd | Out-Null } catch { Write-Host $onFail -ForegroundColor DarkYellow }
}

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'

# --- 0) Tooling (best effort via Scoop) ---------------------------------------
try {
  Try-Run { scoop install git sops age gitleaks trivy syft cosign } "Scoop install skipped or failed (continuing)."
  Try-Run { scoop update  sops age gitleaks trivy syft cosign }     "Scoop update skipped or failed (continuing)."
} catch {}

# --- 1) Quarantine obvious plaintext keys -------------------------------------
$hits = Get-ChildItem $ROOT -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
  $_.Name -match '(?i)(key|secret|token|credentials|password|env)\.(txt|json|yaml|yml|env)$' -or
  $_.FullName -match '(?i)ALLkeys\.txt'
}

foreach($f in $hits){
  $dest = Join-Path $QUAR ($f.Name.Replace('.','_') + "_$stamp")
  try { Move-Item $f.FullName $dest -Force } catch {}
}

Write-Host ("Quarantined plaintext files: {0} -> {1}" -f $hits.Count, $QUAR)

# --- 2) Gitleaks scan (repo dir, even if not a git repo) ----------------------
$rep = Join-Path $SCAN ("gitleaks_{0}.json" -f $stamp)
try {
  # --no-git scans the file system instead of git history (avoids .git required error)
  gitleaks detect -s "$ROOT" --no-git -f json -r "$rep" | Out-Null
  Write-Host "Gitleaks report: $rep"
} catch {
  Write-Host "Gitleaks not available or failed (continuing)." -ForegroundColor DarkYellow
}

# --- 3) SOPS + age keys -------------------------------------------------------
$AgeDir = Join-Path $env:APPDATA "sops\age"
New-Item -ItemType Directory -Path $AgeDir -ErrorAction SilentlyContinue | Out-Null
$AgeKey = Join-Path $AgeDir "keys.txt"

$pubKey = $null
if(-not (Test-Path $AgeKey)){
  try {
    $gen = & age-keygen 2>$null
    if(-not $gen){ throw "age-keygen produced no output" }
    $gen | Out-File -Encoding ASCII $AgeKey
    $pubKey = ($gen | Select-String "Public key:" | ForEach-Object { $_.ToString().Split(":")[-1].Trim() }) | Select-Object -First 1
    Write-Host "Created age key at $AgeKey"
  } catch {
    Write-Host "Could not generate age key (continuing)." -ForegroundColor DarkYellow
  }
} else {
  try {
    $pubKey = (Get-Content $AgeKey | Select-String "public key:" | ForEach-Object { $_.ToString().Split(":")[-1].Trim() }) | Select-Object -First 1
  } catch {}
}

if(-not $pubKey){ Write-Host "Warning: No age public key found. SOPS encryption will not work until this is fixed." -ForegroundColor Yellow }

# --- 4) .sops.yaml with actual recipient --------------------------------------
$SopsYaml = Join-Path $ROOT ".sops.yaml"
if($pubKey){
  @"
# SOPS config for ONYX
creation_rules:
  - path_regex: secrets/.*\.sops\.(ya?ml|json)$
    key_groups:
      - age:
          - $pubKey
"@ | Set-Content -Encoding UTF8 $SopsYaml
  Write-Host "Wrote SOPS config: $SopsYaml"
} else {
  if(-not (Test-Path $SopsYaml)){
    @"
# SOPS config could not be completed because no age public key was detected.
# After you generate a key (age-keygen) and note the 'public key: age1...' line,
# set it here as a recipient:
#
# creation_rules:
#   - path_regex: secrets/.*\.sops\.(ya?ml|json)$
#     key_groups:
#       - age:
#           - age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
"@ | Set-Content -Encoding UTF8 $SopsYaml
    Write-Host "Wrote placeholder SOPS config: $SopsYaml"
  }
}

# --- 5) Create encrypted secrets placeholders ---------------------------------
$svc = @("mason-core","mason-tests","mason-deployer")
foreach($name in $svc){
  $file = Join-Path $SECRETS "$name.secrets.sops.yaml"
  if(-not (Test-Path $file)){
@"
# This file will be encrypted with SOPS. Put dummy values now; edit safely later with:
#   sops $file
OPENAI_API_KEY: "replace-me"
GITHUB_TOKEN: "replace-me"
"@ | Set-Content -Encoding UTF8 $file

    if($pubKey){
      try {
        Push-Location $ROOT
        sops -e -i $file
        Pop-Location
        Write-Host "Encrypted secrets file: $file"
      } catch {
        Write-Host "Could not encrypt $file now. You can run: sops -e -i `"$file`"" -ForegroundColor DarkYellow
      }
    } else {
      Write-Host "Skipped encryption for $file (no age public key yet)." -ForegroundColor DarkYellow
    }
  }
}

# --- 6) .gitignore safety -----------------------------------------------------
$gi = Join-Path $ROOT ".gitignore"
$lines = @"
# Secrets safety
*.env
secrets/*.decrypted.*
security/quarantine/
security/reports/
**/id_rsa
"@
if(Test-Path $gi){
  Add-Content -Path $gi -Value $lines
} else {
  Set-Content -Path $gi -Value $lines -Encoding UTF8
}
Write-Host "Updated .gitignore with secrets safety entries."

# --- 7) Canary files ----------------------------------------------------------
$canaryFiles = @(
  (Join-Path $CANARY "backup_canary.txt"),
  (Join-Path $CANARY "logs_canary.txt")
)

foreach($cf in $canaryFiles){
  if(-not (Test-Path $cf)){
    "CANARY: unexpected read/access should alert. Created $stamp" | Set-Content -Encoding UTF8 $cf
  }
}
$canaryList = (($canaryFiles | ForEach-Object { Split-Path $_ -Leaf }) -join ', ')
Write-Host ("Canaries ready in {0} : {1}" -f $CANARY, $canaryList)

# --- 8) SBOM and vuln scan helper --------------------------------------------
$SbomDir  = Join-Path $SCAN "sbom"
New-Item -ItemType Directory -Path $SbomDir -ErrorAction SilentlyContinue | Out-Null

$MakeSbom = Join-Path $TOOLS "make-sbom.ps1"
@'
$ErrorActionPreference="Stop"
$ROOT = Join-Path $env:USERPROFILE "Desktop\ONYX"
$OUT  = Join-Path $ROOT "security\sbom"
New-Item -ItemType Directory -Path $OUT -EA SilentlyContinue | Out-Null

# Syft: SPDX JSON for workspace
try {
  syft dir:$ROOT -o spdx-json > (Join-Path $OUT "workspace.spdx.json")
  Write-Host "SBOM written: $($OUT)\workspace.spdx.json"
} catch { Write-Warning "Syft failed (install via scoop syft)"; }

# Trivy: vuln + secret + config scan
try {
  trivy fs --scanners vuln,secret,config --severity HIGH,CRITICAL --exit-code 0 $ROOT `
    | Tee-Object -FilePath (Join-Path $OUT "trivy_fs_latest.txt") | Out-Null
  Write-Host "Trivy report: $($OUT)\trivy_fs_latest.txt"
} catch { Write-Warning "Trivy failed (install via scoop trivy)"; }
'@ | Set-Content -Path $MakeSbom -Encoding UTF8

Write-Host ""
Write-Host "Day-0 security completed:"
Write-Host (" - Quarantined plaintext secrets: {0}" -f $hits.Count)
Write-Host (" - Gitleaks report: {0}" -f $(if(Test-Path $rep){$rep}else{"not generated"}))
Write-Host (" - SOPS config: {0}" -f $SopsYaml)
Write-Host (" - Secrets placeholders: {0}" -f (($svc | ForEach-Object { "secrets\{0}.secrets.sops.yaml" -f $_ }) -join ', '))
Write-Host (" - Canaries: {0}" -f $canaryList)
Write-Host (" - SBOM helper: {0}" -f $MakeSbom)
Write-Host ""
Write-Host "Next:"
Write-Host "  1) Rotate real credentials outside the repo."
Write-Host "  2) Edit an encrypted file safely:  sops secrets\mason-core.secrets.sops.yaml"
Write-Host "  3) Generate SBOM and vuln scan:  powershell -File `"$MakeSbom`""
