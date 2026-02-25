Param(
    # How often Mason should run a UE learning cycle (default: 180 minutes = 3 hours)
    [int]$IntervalMinutes = 180
)

$ErrorActionPreference = "Stop"

# Mason2 base dir = parent of tools
$root = Split-Path $PSScriptRoot -Parent

$topicsPath  = Join-Path $root "learn\learn_topics_mason.json"
$logDir      = Join-Path $root "logs\ue"
$stateFile   = Join-Path $root "state\knowledge\ue_mason_state.json"
$learnScript = Join-Path $root "tools\Mason_Learn_From_Web.ps1"

# Make sure log + state dirs exist
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
New-Item -ItemType Directory -Path (Split-Path $stateFile -Parent) -Force | Out-Null

Write-Host "[UE] Mason UE loop (area=mason) starting..."
Write-Host "     Root: $root"
Write-Host "     Topics: $topicsPath"
Write-Host "     Interval: $IntervalMinutes minute(s)"

while ($true) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logFile = Join-Path $logDir ("Mason_UE_Mason_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".log")

    try {
        if (-not (Test-Path $topicsPath)) {
            $msg = "[$timestamp] [ERROR] learn_topics_mason.json not found at $topicsPath"
            $msg | Tee-Object -FilePath $logFile -Append
            break
        }

        if (-not (Test-Path $learnScript)) {
            $msg = "[$timestamp] [ERROR] Mason_Learn_From_Web.ps1 not found at $learnScript"
            $msg | Tee-Object -FilePath $logFile -Append
            break
        }

        $configJson = Get-Content $topicsPath -Raw
        $config = $configJson | ConvertFrom-Json

        # IMPORTANT:
        # Your learn_topics_mason.json does NOT have "enabled" or "area".
        # So for now we treat ALL topics in this file as Mason topics.
        $topics = $config.topics

        if (-not $topics -or $topics.Count -eq 0) {
            $msg = "[$timestamp] [WARN] No topics found in learn_topics_mason.json"
            $msg | Tee-Object -FilePath $logFile -Append
        }
        else {
            # Round-robin through topics so Mason gradually deepens all of them
            $idx = 0
            if (Test-Path $stateFile) {
                try {
                    $state = Get-Content $stateFile -Raw | ConvertFrom-Json
                    if ($state.lastIndex -ne $null) {
                        $idx = [int]$state.lastIndex
                    }
                } catch {
                    # ignore bad state and start at 0
                    $idx = 0
                }
            }

            $topic = $topics[$idx % $topics.Count]

            # Pick something reasonable for the search "topic key"
            $topicKey = if ($topic.key) { 
                $topic.key 
            } elseif ($topic.id) { 
                $topic.id 
            } else { 
                "mason_topic_$idx" 
            }

            $msg = "[$timestamp] [INFO] UE loop learning topic '$topicKey'..."
            $msg | Tee-Object -FilePath $logFile -Append

            # IMPORTANT: pass Topic + Area so there are NO interactive prompts
            & $learnScript -Topic $topicKey -Area "mason" |
                Tee-Object -FilePath $logFile -Append

            # Save next index for round-robin
            $newState = @{ lastIndex = ($idx + 1) % $topics.Count }
            $newState | ConvertTo-Json | Set-Content $stateFile -Encoding UTF8
        }
    }
    catch {
        ("[$timestamp] [ERROR] " + $_.Exception.Message) |
            Tee-Object -FilePath $logFile -Append
    }

    $sleepMsg = "[$timestamp] [INFO] Sleeping $IntervalMinutes minute(s) before next UE cycle..."
    $sleepMsg | Tee-Object -FilePath $logFile -Append

    # PowerShell supports only -Seconds / -Milliseconds, so we convert minutes -> seconds
    Start-Sleep -Seconds ($IntervalMinutes * 60)
}
