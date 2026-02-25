param()

# Mason Docs Indexer
# Scans plans\docs and plans\onyx for documentation files and writes reports\docs_index.json
# Safe: read-only scan + one JSON output.

$ErrorActionPreference = "Stop"

# Resolve Mason base folder (one level up from tools\)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$baseDir   = Split-Path -Parent $scriptDir

$logsDir    = Join-Path $baseDir "logs"
$reportsDir = Join-Path $baseDir "reports"

if (-not (Test-Path $logsDir))    { New-Item -ItemType Directory -Path $logsDir    | Out-Null }
if (-not (Test-Path $reportsDir)) { New-Item -ItemType Directory -Path $reportsDir | Out-Null }

$logFile = Join-Path $logsDir "docs_index.log"

function Write-Log {
    param(
        [string]$Level,
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp][$Level][Mason_Docs_Index] $Message"
    Add-Content -Path $logFile -Value $line
}

try {
    Write-Log "INFO" "Starting docs index scan."

    $docs = @()

    $pathsToScan = @(
        @{ Path = Join-Path $baseDir "plans\docs";  Component = "generic" },
        @{ Path = Join-Path $baseDir "plans\onyx";  Component = "onyx"    },
        @{ Path = Join-Path $baseDir "plans\mason"; Component = "mason"   },
        @{ Path = Join-Path $baseDir "plans\athena";Component = "athena"  }
    )

    foreach ($entry in $pathsToScan) {
        $path = $entry.Path
        $componentDefault = $entry.Component

        if (-not (Test-Path $path)) {
            continue
        }

        $files = Get-ChildItem $path -File -Include *.md, *.txt -Recurse -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            $component = $componentDefault

            if ($file.Name -match "mason")  { $component = "mason"  }
            elseif ($file.Name -match "onyx")   { $component = "onyx"   }
            elseif ($file.Name -match "athena"){ $component = "athena" }

            $relativePath = $file.FullName.Replace($baseDir + "\","")

            $docs += [PSCustomObject]@{
                id        = ($file.BaseName.ToLowerInvariant())
                component = $component
                title     = $file.BaseName
                path      = $file.FullName
                relative  = $relativePath
                extension = $file.Extension
                sizeBytes = $file.Length
            }
        }
    }

    $output = [PSCustomObject]@{
        generated_at = (Get-Date).ToString("s")
        mason_base   = $baseDir
        docs         = $docs
    }

    $jsonPath = Join-Path $reportsDir "docs_index.json"
    $output | ConvertTo-Json -Depth 5 | Set-Content -Path $jsonPath -Encoding UTF8

    Write-Log "INFO" "Docs index written to $jsonPath. Count=$($docs.Count)"
    Write-Output "Docs index created at: $jsonPath (Count=$($docs.Count))"
}
catch {
    Write-Log "ERROR" "Docs index failed: $($_.Exception.Message)"
    throw
}
