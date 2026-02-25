Param()

# --- paths ---
$MasonBase   = Resolve-Path (Join-Path $PSScriptRoot "..")
$ReportsDir  = Join-Path $MasonBase "reports"
$LogsDir     = Join-Path $MasonBase "logs"
$OutSummary  = Join-Path $ReportsDir "onyx_health_summary.json"
$OutFull     = Join-Path $ReportsDir "onyx_health.json"
$LogFile     = Join-Path $LogsDir "onyx_smoketest.log"

New-Item -ItemType Directory -Force -Path $ReportsDir | Out-Null
New-Item -ItemType Directory -Force -Path $LogsDir    | Out-Null

$OnyxBase = "http://127.0.0.1:5353"
$ts = (Get-Date).ToString("o")

function Test-Get {
  param(
    [Parameter(Mandatory=$true)][string]$Url,
    [int]$TimeoutSec = 5
  )

  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  try {
    $resp = Invoke-WebRequest -Uri $Url -Method Get -UseBasicParsing -TimeoutSec $TimeoutSec
    $sw.Stop()
    return @{
      ok        = $true
      url       = $Url
      status    = [int]$resp.StatusCode
      ms        = [int]$sw.ElapsedMilliseconds
      ctype     = ($resp.Headers["Content-Type"] | Select-Object -First 1)
      bytes     = ($resp.Content | Out-String).Length
      snippet   = (($resp.Content | Out-String) -replace "\s+"," ").Substring(0, [Math]::Min(180,(($resp.Content|Out-String).Length)))
    }
  } catch {
    $sw.Stop()
    return @{
      ok     = $false
      url    = $Url
      status = $null
      ms     = [int]$sw.ElapsedMilliseconds
      error  = $_.Exception.Message
    }
  }
}

# --- checks (use GET, not HEAD) ---
$checkRoot   = Test-Get "$OnyxBase/"
$checkBoot   = Test-Get "$OnyxBase/flutter_bootstrap.js"

# Optional: verify bootstrap references main.dart.js (without downloading the full JS bundle)
$bootHasMain = $false
if ($checkBoot.ok -and $checkBoot.snippet) {
  # snippet may not include it, so also inspect full content if small enough
  try {
    $bootText = (Invoke-WebRequest -Uri "$OnyxBase/flutter_bootstrap.js" -Method Get -UseBasicParsing -TimeoutSec 5).Content
    $bootHasMain = ($bootText -match "main\.dart\.js")
  } catch { $bootHasMain = $false }
}

$overallOk = ($checkRoot.ok -and $checkBoot.ok -and $bootHasMain)

$payload = [ordered]@{
  timestamp     = $ts
  onyxBaseUrl   = $OnyxBase
  healthOpinion = $(if ($overallOk) { "healthy" } else { "unhealthy" })
  checks        = @(
    [ordered]@{ name="GET /"; ok=$checkRoot.ok; status=$checkRoot.status; ms=$checkRoot.ms; ctype=$checkRoot.ctype; bytes=$checkRoot.bytes; error=$checkRoot.error }
    [ordered]@{ name="GET /flutter_bootstrap.js"; ok=$checkBoot.ok; status=$checkBoot.status; ms=$checkBoot.ms; ctype=$checkBoot.ctype; bytes=$checkBoot.bytes; error=$checkBoot.error }
    [ordered]@{ name="bootstrap references main.dart.js"; ok=$bootHasMain; status=$null; ms=$null; ctype=$null; bytes=$null; error=$(if($bootHasMain) { $null } else { "Did not detect main.dart.js reference in flutter_bootstrap.js" }) }
  )
}

# Write both files for compatibility with older readers
($payload | ConvertTo-Json -Depth 6) | Set-Content -Encoding UTF8 -Path $OutSummary
($payload | ConvertTo-Json -Depth 6) | Set-Content -Encoding UTF8 -Path $OutFull

# Append a small log line
"[$ts] Onyx smoketest: $($payload.healthOpinion) (root=$($checkRoot.ok), bootstrap=$($checkBoot.ok), mainref=$bootHasMain)" |
  Add-Content -Encoding UTF8 -Path $LogFile

Write-Host "[Onyx_SmokeTest] Wrote:"
Write-Host "  $OutSummary"
Write-Host "  $OutFull"
Write-Host "[Onyx_SmokeTest] Result: $($payload.healthOpinion)"
