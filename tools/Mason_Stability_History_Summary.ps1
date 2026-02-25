# Mason_Stability_History_Summary.ps1
# Summarize everything in queue\applied so Chris can see what Mason actually ran.

$ErrorActionPreference = "Stop"

# Figure out Mason2 root from this script's location
$base = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $base

$queueDir   = Join-Path $root "queue"
$appliedDir = Join-Path $queueDir "applied"
$reportDir  = Join-Path $root "reports"
$reportPath = Join-Path $reportDir "stability_history.json"

foreach ($d in @($queueDir, $appliedDir, $reportDir)) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d | Out-Null
    }
}

$tasks = @()

if (Test-Path $appliedDir) {
    $files = Get-ChildItem $appliedDir -Filter "*.json" -File -ErrorAction SilentlyContinue

    foreach ($f in $files) {
        $obj = $null
        try {
            $raw = Get-Content $f.FullName -Raw
            $obj = $raw | ConvertFrom-Json
        }
        catch {
            # If JSON is weird, we still want a record
            $obj = $null
        }

        $id        = if ($obj -and $obj.id)       { $obj.id }       else { [IO.Path]::GetFileNameWithoutExtension($f.Name) }
        $area      = if ($obj -and $obj.area)     { $obj.area }     else { "unknown" }
        $risk      = if ($obj -and $obj.risk)     { $obj.risk }     else { "unknown" }
        $autoApply = if ($obj -and ($obj.PSObject.Properties.Name -contains "auto_apply")) {
            [bool]$obj.auto_apply
        } else {
            $false
        }
        $createdAt = if ($obj -and $obj.created_at) { $obj.created_at } else { $null }

        $tasks += [ordered]@{
            id          = $id
            area        = $area
            risk        = $risk
            auto_apply  = $autoApply
            file_name   = $f.Name
            created_at  = $createdAt
            applied_at  = $f.LastWriteTime.ToString("o")
        }
    }
}

$summary = [ordered]@{
    generatedAt       = (Get-Date).ToString("o")
    appliedDir        = $appliedDir
    totalAppliedTasks = $tasks.Count
    tasks             = $tasks | Sort-Object applied_at
}

$summary | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath -Encoding UTF8

Write-Host "Stability history written to $reportPath"
