param(
    [string]$Key,
    [switch]$ApplyOnyxTasks
)

# -------------------------------
# Bootstrap Mason base + logging
# -------------------------------
$scriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$parentDir  = Split-Path -Path $scriptRoot -Parent

$baseLib    = Join-Path $parentDir "lib\Mason.Base.psm1"
$logLib     = Join-Path $parentDir "lib\Mason.Logging.psm1"

if (Test-Path $baseLib) {
    Import-Module $baseLib -Force
    $MasonBase = Get-MasonBase -FromPath $scriptRoot
    Set-Location $MasonBase
} else {
    # Fallback if library is missing
    $MasonBase = Join-Path $env:USERPROFILE "Desktop\Mason2"
    Set-Location $MasonBase
}

if (Test-Path $logLib) {
    Import-Module $logLib -Force
}

# Fallback logger if Out-MasonJsonl is not available
if (-not (Get-Command Out-MasonJsonl -ErrorAction SilentlyContinue)) {
    function Out-MasonJsonl {
        param(
            [string]$Kind,
            [string]$Event,
            [string]$Level,
            [hashtable]$Data
        )
        Write-Host "[$Level] $Kind/$Event :: $(($Data | ConvertTo-Json -Compress))"
    }
}

$reportsDir      = Join-Path $MasonBase "reports"
$tasksRoot       = Join-Path $MasonBase "tasks"
$pendingOnyxDir  = Join-Path $tasksRoot "pending\onyx"
$appliedOnyxDir  = Join-Path $tasksRoot "applied\onyx"

if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}

$summary = @{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    mason_base       = $MasonBase
    mode             = $null
    total_applied    = 0
    applied_tasks    = @()
    key_mode         = $null
    key_exit_code    = $null
}

# Decide default mode: if nothing passed, default to Onyx tasks
if (-not $Key -and -not $ApplyOnyxTasks) {
    $ApplyOnyxTasks = $true
}

# -------------------------------
# Mode 1: legacy config key self-heal
# -------------------------------
if ($Key) {
    $summary.mode     = "config_key"
    $summary.key_mode = $Key

    $catPath = Join-Path $MasonBase "config\selfheal.json"

    if (-not (Test-Path $catPath)) {
        $default = @{
            actions = @(
                @{ match = "server7001:down";   run = "schtasks /Run /TN `"`"Mason2-FileServer-7001`"`"" },
                @{ match = "urlacl:wildcard";   run = "netsh http delete urlacl url=`"`"http://+:7001/`"`"" }
            )
        }
        $default | ConvertTo-Json -Depth 5 | Set-Content -Path $catPath -Encoding UTF8
    }

    $cat = Get-Content $catPath -Raw | ConvertFrom-Json

    $hit = $cat.actions | Where-Object { $_.match -eq $Key } | Select-Object -First 1

    if ($null -eq $hit) {
        Out-MasonJsonl -Kind 'selfheal' -Event 'miss' -Level 'INFO' -Data @{ key = $Key }
        $summary.key_exit_code = "no_match"
    } else {
        Out-MasonJsonl -Kind 'selfheal' -Event 'run' -Level 'WARN' -Data @{ key = $Key; cmd = $hit.run }

        $LASTEXITCODE = 0
        cmd.exe /c $hit.run | Out-Null
        $code = $LASTEXITCODE
        $summary.key_exit_code = $code

        if ($code -ne 0) {
            $deadRoot = Join-Path $reportsDir "deadletter"
            if (-not (Test-Path $deadRoot)) {
                New-Item -ItemType Directory -Path $deadRoot -Force | Out-Null
            }
            $fname = "selfheal_{0}.json" -f (Get-Date).ToString("yyyyMMdd_HHmmss")
            $fpath = Join-Path $deadRoot $fname
            @{
                key  = $Key
                cmd  = $hit.run
                code = $code
            } | ConvertTo-Json -Compress | Set-Content -Path $fpath -Encoding UTF8

            Out-MasonJsonl -Kind 'selfheal' -Event 'failed' -Level 'ERROR' -Data @{ key = $Key; code = $code }
        }
    }
}

# -------------------------------
# Mode 2: apply Onyx fix tasks
# -------------------------------
if ($ApplyOnyxTasks) {
    $summary.mode = if ($summary.mode) { $summary.mode + "+onyx_tasks" } else { "onyx_tasks" }

    if (-not (Test-Path $pendingOnyxDir)) {
        Out-MasonJsonl -Kind 'selfheal' -Event 'no_pending_dir' -Level 'INFO' -Data @{ dir = $pendingOnyxDir }
    }
    else {
        $files = Get-ChildItem $pendingOnyxDir -Filter *.json -File -ErrorAction SilentlyContinue

        foreach ($file in $files) {
            try {
                $raw  = Get-Content $file.FullName -Raw
                $task = $raw | ConvertFrom-Json
            }
            catch {
                Out-MasonJsonl -Kind 'selfheal' -Event 'task_parse_error' -Level 'ERROR' -Data @{
                    file  = $file.FullName
                    error = $_.Exception.Message
                }
                continue
            }

            # Only apply tasks that are auto_apply = true and not already applied
            if (-not $task.auto_apply -or $task.auto_apply -ne $true) {
                continue
            }

            if ($task.status -and $task.status -ne "pending") {
                continue
            }

            $task.status          = "applied"
            $task.applied_at_utc  = (Get-Date).ToUniversalTime().ToString("o")

            # Ensure applied dir exists
            if (-not (Test-Path $appliedOnyxDir)) {
                New-Item -ItemType Directory -Path $appliedOnyxDir -Force | Out-Null
            }

            # Rewrite the JSON file, then move it
            $task | ConvertTo-Json -Depth 10 | Set-Content -Path $file.FullName -Encoding UTF8
            $destPath = Join-Path $appliedOnyxDir $file.Name
            Move-Item -Path $file.FullName -Destination $destPath -Force

            Out-MasonJsonl -Kind 'selfheal' -Event 'apply_task' -Level 'INFO' -Data @{
                id    = $task.id
                area  = $task.area
                risk  = $task.risk
                file  = $destPath
            }

            $summary.total_applied++
            $summary.applied_tasks += $task.id
        }
    }
}

# -------------------------------
# Write summary
# -------------------------------
$summaryPath = Join-Path $reportsDir "mason_selfheal_summary.json"
$summary | ConvertTo-Json -Depth 10 | Set-Content -Path $summaryPath -Encoding UTF8

Write-Host "Mason self-heal summary written to $summaryPath"
