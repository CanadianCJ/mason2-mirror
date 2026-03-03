[CmdletBinding()]
param(
    [string]$RootPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    param([string]$CandidateRoot)
    if ($CandidateRoot -and (Test-Path -LiteralPath $CandidateRoot)) {
        return (Resolve-Path -LiteralPath $CandidateRoot).Path
    }
    return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

function Read-JsonSafe {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        $Default = $null
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $Default
    }
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if (-not $raw.Trim()) {
        return $Default
    }
    try {
        return $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Failed to parse JSON file $Path : $($_.Exception.Message)"
    }
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object,
        [int]$Depth = 12
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $json = $Object | ConvertTo-Json -Depth $Depth
    Set-Content -LiteralPath $Path -Value $json -Encoding UTF8
}

function ConvertTo-SafeToken {
    param([string]$Text)
    if (-not $Text) { return "item" }
    $token = ($Text -replace "[^a-zA-Z0-9_\-]+", "_").Trim("_")
    if (-not $token) { $token = "item" }
    if ($token.Length -gt 64) { $token = $token.Substring(0, 64) }
    return $token
}

function Get-ShortHash {
    param([Parameter(Mandatory = $true)][string]$InputText)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputText)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha.ComputeHash($bytes)
    }
    finally {
        $sha.Dispose()
    }
    $hex = -join ($hash | ForEach-Object { $_.ToString("x2") })
    return $hex.Substring(0, 8)
}

function Get-FileSha256 {
    param([string]$Path)
    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) {
        return $null
    }
    try {
        return (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()
    }
    catch {
        return $null
    }
}

function To-Array {
    param($Value)
    if ($null -eq $Value) { return @() }
    if ($Value -is [System.Array]) { return $Value }
    return @($Value)
}

function Get-RelativeChildPath {
    param(
        [Parameter(Mandatory = $true)][string]$BasePath,
        [Parameter(Mandatory = $true)][string]$FullPath
    )

    try {
        $base = [IO.Path]::GetFullPath($BasePath)
        $full = [IO.Path]::GetFullPath($FullPath)
        $rel = [IO.Path]::GetRelativePath($base, $full)
        if ($rel.StartsWith("..")) {
            return [IO.Path]::GetFileName($full)
        }
        return $rel
    }
    catch {
        return [IO.Path]::GetFileName($FullPath)
    }
}

function Normalize-PathKey {
    param([string]$Path)
    if (-not $Path) { return "" }
    try {
        return ([IO.Path]::GetFullPath($Path)).TrimEnd("\").ToLowerInvariant()
    }
    catch {
        return ([string]$Path).Trim().TrimEnd("\").ToLowerInvariant()
    }
}

function Add-TraceEvent {
    param(
        [Parameter(Mandatory = $true)][string]$TracePath,
        [Parameter(Mandatory = $true)][string]$Step,
        [string]$File = "",
        [Parameter(Mandatory = $true)][string]$Result,
        [string]$Error = ""
    )

    $parent = Split-Path -Parent $TracePath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $entry = [ordered]@{
        ts     = (Get-Date).ToUniversalTime().ToString("o")
        step   = $Step
        file   = $File
        result = $Result
    }
    if ($Error) {
        $entry.error = $Error
    }
    Add-Content -LiteralPath $TracePath -Value ($entry | ConvertTo-Json -Compress -Depth 6) -Encoding UTF8
}

function Add-EventLine {
    param(
        [Parameter(Mandatory = $true)][string]$ReportsDir,
        [Parameter(Mandatory = $true)][string]$Kind,
        [Parameter(Mandatory = $true)][string]$Status,
        [Parameter(Mandatory = $true)][string]$CorrelationId,
        [hashtable]$Details = @{}
    )

    $eventsPath = Join-Path $ReportsDir "events.jsonl"
    $parent = Split-Path -Parent $eventsPath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $line = [ordered]@{
        ts_utc         = (Get-Date).ToUniversalTime().ToString("o")
        kind           = $Kind
        status         = $Status
        component      = "ingest_autopilot"
        correlation_id = $CorrelationId
        details        = $Details
    }
    Add-Content -LiteralPath $eventsPath -Value ($line | ConvertTo-Json -Compress -Depth 10) -Encoding UTF8
}

function Get-IntField {
    param(
        $Object,
        [Parameter(Mandatory = $true)][string]$Name,
        [int]$Default = 0
    )

    if ($null -eq $Object) { return $Default }
    $raw = $null
    if ($Object -is [hashtable]) {
        if (-not $Object.ContainsKey($Name)) { return $Default }
        $raw = $Object[$Name]
    }
    elseif ($Object.PSObject -and ($Object.PSObject.Properties.Name -contains $Name)) {
        $raw = $Object.$Name
    }
    else {
        return $Default
    }

    $value = 0
    if ([int]::TryParse([string]$raw, [ref]$value)) {
        return [int]$value
    }
    return $Default
}

function Has-AnyPositiveCount {
    param($Map)

    if ($null -eq $Map) { return $false }
    foreach ($k in $Map.Keys) {
        $n = 0
        if ([int]::TryParse([string]$Map[$k], [ref]$n) -and $n -gt 0) {
            return $true
        }
    }
    return $false
}

function Test-EndpointOk {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$TimeoutSec = 4
    )

    try {
        $response = Invoke-WebRequest -Uri $Url -Method Get -UseBasicParsing -TimeoutSec $TimeoutSec -ErrorAction Stop
        return ($response.StatusCode -ge 200 -and $response.StatusCode -lt 300)
    }
    catch {
        return $false
    }
}

function Test-PortListening {
    param([int]$Port)

    if ($Port -le 0) { return $false }

    if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
        try {
            $rows = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue
            if (@($rows).Count -gt 0) { return $true }
        }
        catch {
            # fallback to netstat
        }
    }

    try {
        $rows = netstat -ano -p tcp
        foreach ($line in $rows) {
            if ($line -notmatch "LISTENING") { continue }
            if ($line -match "^\s*TCP\s+\S+:(\d+)\s+\S+\s+LISTENING\s+\d+") {
                $p = 0
                if ([int]::TryParse($Matches[1], [ref]$p) -and $p -eq $Port) {
                    return $true
                }
            }
        }
    }
    catch {
        return $false
    }

    return $false
}

function Test-MasonConsoleProcess {
    param([Parameter(Mandatory = $true)][string]$ConsoleDir)

    try {
        $normDir = [IO.Path]::GetFullPath($ConsoleDir).TrimEnd("\")
    }
    catch {
        $normDir = $ConsoleDir
    }

    try {
        $rows = Get-CimInstance Win32_Process -Filter "Name='python.exe' OR Name='pythonw.exe'" -ErrorAction Stop
        foreach ($row in @($rows)) {
            $cmd = [string]$row.CommandLine
            if (-not $cmd) { continue }
            if ($cmd -notmatch "(?i)\bserver\.py\b") { continue }
            if ($cmd.ToLowerInvariant().Contains($normDir.ToLowerInvariant())) {
                return $true
            }
        }
    }
    catch {
        return $false
    }

    return $false
}

function Resolve-MasonConsolePython {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$ConsoleDir
    )

    $candidates = @(
        (Join-Path $ConsoleDir ".venv\Scripts\python.exe"),
        (Join-Path $ConsoleDir "venv\Scripts\python.exe"),
        (Join-Path $RepoRoot ".venv\Scripts\python.exe"),
        (Join-Path $RepoRoot "venv\Scripts\python.exe")
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return "python"
}

function Start-MasonConsoleServer {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$ReportsDir
    )

    $consoleDir = Join-Path $RepoRoot "MasonConsole"
    $serverPath = Join-Path $consoleDir "server.py"
    if (-not (Test-Path -LiteralPath $serverPath)) {
        return [pscustomobject]@{
            started = $false
            reason  = "missing_server_py"
            pid     = $null
        }
    }

    $stdoutLog = Join-Path $ReportsDir "masonconsole_stdout.log"
    $stderrLog = Join-Path $ReportsDir "masonconsole_stderr.log"
    $pythonExe = Resolve-MasonConsolePython -RepoRoot $RepoRoot -ConsoleDir $consoleDir

    try {
        $proc = Start-Process `
            -FilePath $pythonExe `
            -ArgumentList @("server.py") `
            -WorkingDirectory $consoleDir `
            -WindowStyle Hidden `
            -RedirectStandardOutput $stdoutLog `
            -RedirectStandardError $stderrLog `
            -PassThru `
            -ErrorAction Stop

        return [pscustomobject]@{
            started = $true
            reason  = "started"
            pid     = [int]$proc.Id
            stdout  = $stdoutLog
            stderr  = $stderrLog
            python  = $pythonExe
        }
    }
    catch {
        return [pscustomobject]@{
            started = $false
            reason  = ("start_failed:{0}" -f $_.Exception.Message)
            pid     = $null
            stdout  = $stdoutLog
            stderr  = $stderrLog
            python  = $pythonExe
        }
    }
}

function Ensure-IngestEndpoint {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$ReportsDir,
        [string]$EndpointUrl = "http://127.0.0.1:8000/api/ingest_index"
    )

    $consoleDir = Join-Path $RepoRoot "MasonConsole"
    $startedConsole = $false
    $startResult = $null

    for ($i = 0; $i -lt 3; $i++) {
        if (Test-EndpointOk -Url $EndpointUrl -TimeoutSec 4) {
            return [pscustomobject]@{
                ingest_endpoint_ok   = $true
                masonconsole_started = $false
                mode_reason          = $null
                endpoint_url         = $EndpointUrl
                start_result         = $null
            }
        }
        Start-Sleep -Milliseconds 800
    }

    $alreadyListening = Test-PortListening -Port 8000
    $existingConsole = Test-MasonConsoleProcess -ConsoleDir $consoleDir
    if (-not $alreadyListening -and -not $existingConsole) {
        $startResult = Start-MasonConsoleServer -RepoRoot $RepoRoot -ReportsDir $ReportsDir
        $startedConsole = [bool]$startResult.started
    }

    $deadline = (Get-Date).ToUniversalTime().AddSeconds(30)
    while ((Get-Date).ToUniversalTime() -lt $deadline) {
        if (Test-EndpointOk -Url $EndpointUrl -TimeoutSec 4) {
            return [pscustomobject]@{
                ingest_endpoint_ok   = $true
                masonconsole_started = $startedConsole
                mode_reason          = $null
                endpoint_url         = $EndpointUrl
                start_result         = $startResult
            }
        }
        Start-Sleep -Seconds 1
    }

    return [pscustomobject]@{
        ingest_endpoint_ok   = $false
        masonconsole_started = $startedConsole
        mode_reason          = "athena_unreachable"
        endpoint_url         = $EndpointUrl
        start_result         = $startResult
    }
}

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$policyPath = Join-Path $repoRoot "config\ingest_policy.json"
$policy = Read-JsonSafe -Path $policyPath -Default $null
if (-not $policy) {
    throw "Missing ingest policy: $policyPath"
}

$reportsDir = Join-Path $repoRoot "reports"
$statusPath = Join-Path $reportsDir "ingest_autopilot_status.json"
if (-not (Test-Path -LiteralPath $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}

if (-not [bool]$policy.enabled) {
    $disabled = [ordered]@{
        run_id         = ""
        updated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
        mode           = "disabled"
        mode_reason    = "config.ingest_policy.enabled=false"
        reason         = "config.ingest_policy.enabled=false"
        ingest_endpoint_ok   = $false
        masonconsole_started = $false
        source_path_file_counts = [ordered]@{}
        sample_files            = @()
    }
    Write-JsonFile -Path $statusPath -Object $disabled -Depth 8
    $disabled | ConvertTo-Json -Depth 8
    exit 0
}

$dropDir = [string]$policy.drop_dir
$processedDir = [string]$policy.processed_dir
if (-not $dropDir.Trim()) { $dropDir = Join-Path $repoRoot "drop\ingest" }
if (-not $processedDir.Trim()) { $processedDir = Join-Path $repoRoot "drop\processed" }

if (-not (Test-Path -LiteralPath $dropDir)) {
    New-Item -ItemType Directory -Path $dropDir -Force | Out-Null
}
if (-not (Test-Path -LiteralPath $processedDir)) {
    New-Item -ItemType Directory -Path $processedDir -Force | Out-Null
}

$allowedExt = @()
foreach ($ext in To-Array $policy.allowed_ext) {
    if (-not $ext) { continue }
    $value = ([string]$ext).Trim().ToLowerInvariant()
    if (-not $value.StartsWith(".")) { $value = "." + $value }
    if ($value) { $allowedExt += $value }
}
$allowedExt = @($allowedExt | Select-Object -Unique)
if ($allowedExt.Count -eq 0) {
    $allowedExt = @(".txt", ".md", ".log", ".json")
}
$policyMode = "llm"
if ($policy.mode) {
    $policyMode = ([string]$policy.mode).Trim().ToLowerInvariant()
}
if (-not $policyMode) {
    $policyMode = "llm"
}
$policyForcesStorageOnly = $policyMode -ne "llm"

$maxFilesPerRun = 300
$debounceSeconds = 5
$maxCharsPerChunk = 6000
try { $maxFilesPerRun = [int]$policy.max_files_per_run } catch { }
try { $debounceSeconds = [int]$policy.debounce_seconds } catch { }
try { $maxCharsPerChunk = [int]$policy.max_chars_per_chunk } catch { }
if ($maxFilesPerRun -lt 1) { $maxFilesPerRun = 300 }
if ($debounceSeconds -lt 0) { $debounceSeconds = 0 }
if ($maxCharsPerChunk -lt 1) { $maxCharsPerChunk = 6000 }

$runId = Get-Date -Format "yyyyMMdd_HHmmss"
$tracePath = Join-Path $reportsDir ("ingest_autopilot_trace_{0}.jsonl" -f $runId)
Add-TraceEvent -TracePath $tracePath -Step "run_start" -Result "ok"
Add-EventLine -ReportsDir $reportsDir -Kind "ingest_run" -Status "started" -CorrelationId $runId -Details @{
    run_id = $runId
}

$useFlattenedInbox = $false
$flattenSourceDir = ""
$flattenTargetDir = ""
$flattenResult = $null
$flattenScriptPath = Join-Path $repoRoot "tools\ingest\Mason_Inbox_Flatten.ps1"
if ($policy -and ($policy.PSObject.Properties.Name -contains "use_flattened_inbox")) {
    $useFlattenedInbox = [bool]$policy.use_flattened_inbox
}
if ($policy -and ($policy.PSObject.Properties.Name -contains "flatten_source_dir") -and $policy.flatten_source_dir) {
    $flattenSourceDir = [string]$policy.flatten_source_dir
}
if ($policy -and ($policy.PSObject.Properties.Name -contains "flatten_target_dir") -and $policy.flatten_target_dir) {
    $flattenTargetDir = [string]$policy.flatten_target_dir
}
if (-not $flattenSourceDir.Trim()) {
    $flattenSourceDir = "C:\Users\Chris\Desktop\Chat GPT old chats"
}
if (-not $flattenTargetDir.Trim()) {
    $flattenTargetDir = Join-Path $repoRoot "knowledge\inbox_flat"
}

if ($useFlattenedInbox) {
    if (-not (Test-Path -LiteralPath $flattenScriptPath)) {
        Add-TraceEvent -TracePath $tracePath -Step "flatten_run" -Result "fail" -Error ("missing_script:{0}" -f $flattenScriptPath)
        throw "Flattened inbox is enabled but script is missing: $flattenScriptPath"
    }
    try {
        $flattenJson = & $flattenScriptPath -RootPath $repoRoot -SourceDir $flattenSourceDir -TargetDir $flattenTargetDir
        if ($flattenJson) {
            try {
                $flattenResult = $flattenJson | ConvertFrom-Json -ErrorAction Stop
            }
            catch {
                $flattenResult = $null
            }
        }
        Add-TraceEvent -TracePath $tracePath -Step "flatten_run" -Result "ok" -File $flattenTargetDir
    }
    catch {
        Add-TraceEvent -TracePath $tracePath -Step "flatten_run" -Result "fail" -Error $_.Exception.Message
        throw
    }
}
$flattenTargetPathKey = Normalize-PathKey -Path $flattenTargetDir

$stagingRoot = Join-Path $repoRoot ("ingest\autopilot\{0}\input" -f $runId)
New-Item -ItemType Directory -Path $stagingRoot -Force | Out-Null
$processedRunRoot = Join-Path $processedDir $runId
New-Item -ItemType Directory -Path $processedRunRoot -Force | Out-Null

$scanRoots = New-Object System.Collections.Generic.List[string]
$scanRootSeen = @{}
$dropKey = Normalize-PathKey -Path $dropDir
$scanRootSeen[$dropKey] = $true
$scanRoots.Add($dropDir) | Out-Null
foreach ($p in To-Array $policy.inbox_paths) {
    if (-not $p) { continue }
    $candidate = [string]$p
    if ($useFlattenedInbox) {
        $candidateKey = Normalize-PathKey -Path $candidate
        $flattenSourceKey = Normalize-PathKey -Path $flattenSourceDir
        if ($candidateKey -eq $flattenSourceKey -or $candidateKey.StartsWith(($flattenSourceKey + "\"))) {
            continue
        }
    }
    $key = Normalize-PathKey -Path $candidate
    if (-not $scanRootSeen.ContainsKey($key)) {
        $scanRoots.Add($candidate) | Out-Null
        $scanRootSeen[$key] = $true
    }
}
if ($useFlattenedInbox) {
    $flattenTargetKey = Normalize-PathKey -Path $flattenTargetDir
    if (-not $scanRootSeen.ContainsKey($flattenTargetKey)) {
        $scanRoots.Add($flattenTargetDir) | Out-Null
        $scanRootSeen[$flattenTargetKey] = $true
    }
}

$seen = @{}
$detectedCandidates = New-Object System.Collections.Generic.List[object]
$debounceCutoff = (Get-Date).ToUniversalTime().AddSeconds(-1 * $debounceSeconds)

foreach ($root in @($scanRoots.ToArray())) {
    if (-not (Test-Path -LiteralPath $root)) { continue }
    $item = Get-Item -LiteralPath $root -ErrorAction SilentlyContinue
    if (-not $item) { continue }
    $rootPathKey = Normalize-PathKey -Path $root
    $ignoreDebounceForRoot = $useFlattenedInbox -and $rootPathKey -eq $flattenTargetPathKey

    if ($item.PSIsContainer) {
        $rootResolved = $item.FullName
        foreach ($file in Get-ChildItem -LiteralPath $item.FullName -Recurse -File -ErrorAction SilentlyContinue) {
            $ext = ([string]$file.Extension).ToLowerInvariant()
            if ($allowedExt -notcontains $ext) { continue }
            if ($useFlattenedInbox -and $rootPathKey -eq $flattenTargetPathKey -and $file.Name -ieq "_manifest.json") { continue }
            if (-not $ignoreDebounceForRoot -and $file.LastWriteTimeUtc -gt $debounceCutoff) { continue }
            if ($seen.ContainsKey($file.FullName)) { continue }
            $seen[$file.FullName] = $true
            $detectedCandidates.Add([pscustomobject]@{
                    source_root  = $root
                    source_bucket = ConvertTo-SafeToken -Text ([System.IO.Path]::GetFileName($root))
                    source_path  = $file.FullName
                    relative_name = (Get-RelativeChildPath -BasePath $rootResolved -FullPath $file.FullName)
                    file         = $file
                }) | Out-Null
        }
    }
    else {
        $ext = ([string]$item.Extension).ToLowerInvariant()
        $skipFlattenManifest = $useFlattenedInbox -and $rootPathKey -eq $flattenTargetPathKey -and $item.Name -ieq "_manifest.json"
        if (($allowedExt -contains $ext) -and (-not $skipFlattenManifest) -and ($ignoreDebounceForRoot -or $item.LastWriteTimeUtc -le $debounceCutoff)) {
            if (-not $seen.ContainsKey($item.FullName)) {
                $seen[$item.FullName] = $true
                $detectedCandidates.Add([pscustomobject]@{
                        source_root  = $root
                        source_bucket = ConvertTo-SafeToken -Text ([System.IO.Path]::GetFileName($root))
                        source_path  = $item.FullName
                        relative_name = [System.IO.Path]::GetFileName($item.FullName)
                        file         = $item
                    }) | Out-Null
            }
        }
    }
}

$detectedFiles = @($detectedCandidates.ToArray() | Sort-Object { $_.source_path } | Select-Object -First $maxFilesPerRun)
$sourcePathFileCounts = [ordered]@{}
foreach ($root in @($scanRoots.ToArray())) {
    if (-not $root) { continue }
    if (-not $sourcePathFileCounts.Contains($root)) {
        $sourcePathFileCounts[$root] = 0
    }
}
foreach ($entry in $detectedFiles) {
    $root = [string]$entry.source_root
    if (-not $sourcePathFileCounts.Contains($root)) { $sourcePathFileCounts[$root] = 0 }
    $sourcePathFileCounts[$root] = [int]$sourcePathFileCounts[$root] + 1
}

$sampleFiles = New-Object System.Collections.Generic.List[string]
foreach ($entry in $detectedFiles) {
    if ($sampleFiles.Count -ge 10) { break }
    if (-not $entry -or -not $entry.file) { continue }
    $name = [string]$entry.file.Name
    if (-not $name) { continue }
    if ($sampleFiles.Contains($name)) { continue }
    $sampleFiles.Add($name) | Out-Null
}

$detectedCount = $detectedFiles.Count
Add-TraceEvent -TracePath $tracePath -Step "scan_complete" -Result "ok" -File ("detected={0}" -f $detectedCount)

$stagedCount = $detectedCount
$stageSuccessCount = 0
$movedCount = 0
$skippedCount = 0
$stagedPaths = New-Object System.Collections.Generic.List[string]
$stagedManifest = New-Object System.Collections.Generic.List[object]

foreach ($entry in $detectedFiles) {
    $file = $entry.file
    $sourceRoot = [string]$entry.source_root
    $sourcePath = [string]$entry.source_path
    $sourceRootToken = [string]$entry.source_bucket
    if (-not $sourceRootToken) { $sourceRootToken = "source" }
    $relativeName = [string]$entry.relative_name
    if (-not $relativeName) {
        $relativeName = [System.IO.Path]::GetFileName($sourcePath)
    }
    $relativeName = $relativeName.Replace("/", "\")

    $stagePath = Join-Path (Join-Path $stagingRoot $sourceRootToken) $relativeName
    $stageParent = Split-Path -Parent $stagePath
    if ($stageParent -and -not (Test-Path -LiteralPath $stageParent)) {
        New-Item -ItemType Directory -Path $stageParent -Force | Out-Null
    }

    try {
        Copy-Item -LiteralPath $sourcePath -Destination $stagePath -Force
        $stageSuccessCount++
        $stagedPaths.Add($stagePath) | Out-Null
        Add-TraceEvent -TracePath $tracePath -Step "stage_copy" -File $sourcePath -Result "ok"
    }
    catch {
        $skippedCount++
        Add-TraceEvent -TracePath $tracePath -Step "stage_copy" -File $sourcePath -Result "fail" -Error $_.Exception.Message
        continue
    }

    $processedPath = $null
    $sourceRootKey = Normalize-PathKey -Path $sourceRoot
    $sourcePathKey = Normalize-PathKey -Path $sourcePath
    $moveOriginal = $false
    if ($sourceRootKey -eq $dropKey -or ($dropKey -and $sourcePathKey.StartsWith($dropKey + "\"))) {
        $moveOriginal = $true
    }

    if ($moveOriginal) {
        $processedPath = Join-Path (Join-Path $processedRunRoot $sourceRootToken) $relativeName
        $processedParent = Split-Path -Parent $processedPath
        if ($processedParent -and -not (Test-Path -LiteralPath $processedParent)) {
            New-Item -ItemType Directory -Path $processedParent -Force | Out-Null
        }

        try {
            Move-Item -LiteralPath $sourcePath -Destination $processedPath -Force
            $movedCount++
            Add-TraceEvent -TracePath $tracePath -Step "move_processed" -File $sourcePath -Result "ok"
        }
        catch {
            $skippedCount++
            Add-TraceEvent -TracePath $tracePath -Step "move_processed" -File $sourcePath -Result "fail" -Error $_.Exception.Message
        }
    }
    else {
        Add-TraceEvent -TracePath $tracePath -Step "move_processed" -File $sourcePath -Result "skip"
    }

    $stagedManifest.Add([pscustomobject]@{
            name           = [System.IO.Path]::GetFileName($sourcePath)
            source_path    = $sourcePath
            source_root    = $sourceRoot
            staged_path    = $stagePath
            processed_path = $processedPath
            relative_name  = $relativeName
            bytes          = if ($file) { [int64]$file.Length } else { 0 }
            sha256         = Get-FileSha256 -Path $stagePath
        }) | Out-Null
}

Add-TraceEvent -TracePath $tracePath -Step "stage_complete" -Result "ok" -File ("staged_success={0};moved={1}" -f $stageSuccessCount, $movedCount)

$ingestScript = Join-Path $repoRoot "tools\ingest\Mason_IngestFolder.ps1"
if (-not (Test-Path -LiteralPath $ingestScript)) {
    throw "Missing dependency: $ingestScript"
}
$roadmapScript = Join-Path $repoRoot "tools\Mason_Build_Master_Roadmap.ps1"
$tasksScript = Join-Path $repoRoot "tools\Mason_Tasks_From_Knowledge.ps1"
$mirrorUpdateScript = Join-Path $repoRoot "tools\sync\Mason_Mirror_Update.ps1"
$endpointState = Ensure-IngestEndpoint -RepoRoot $repoRoot -ReportsDir $reportsDir -EndpointUrl "http://127.0.0.1:8000/api/ingest_index"
$ingestEndpointOk = [bool]$endpointState.ingest_endpoint_ok
$masonconsoleStarted = [bool]$endpointState.masonconsole_started
$modeReason = $null
if ($endpointState -and ($endpointState.PSObject.Properties.Name -contains "mode_reason")) {
    $modeReason = [string]$endpointState.mode_reason
}
if (-not $modeReason -and -not $ingestEndpointOk -and $detectedCount -gt 0) {
    $modeReason = "athena_unreachable"
}
$forceStorageOnly = -not $ingestEndpointOk

$ingestResult = $null
$roadmapResult = $null
$tasksResult = $null
$mirrorResult = $null
if ($stageSuccessCount -gt 0) {
    try {
        Add-TraceEvent -TracePath $tracePath -Step "ingest_start" -Result "ok" -File ("staged_success={0}" -f $stageSuccessCount)
        $ingestInputPaths = @($stagedPaths.ToArray())
        $jsonText = & $ingestScript `
            -RootPath $repoRoot `
            -InputPaths $ingestInputPaths `
            -Label "drop-autopilot" `
            -RunId $runId `
            -IgnoreDebounce `
            -ForceStorageOnly:$forceStorageOnly
        if ($jsonText) {
            try {
                $ingestResult = $jsonText | ConvertFrom-Json -ErrorAction Stop
            }
            catch {
                $ingestResult = $null
            }
        }
        Add-TraceEvent -TracePath $tracePath -Step "ingest_complete" -Result "ok"
    }
    catch {
        $ingestResult = [pscustomobject]@{
            ok    = $false
            error = $_.Exception.Message
        }
        Add-TraceEvent -TracePath $tracePath -Step "ingest_complete" -Result "fail" -Error $_.Exception.Message
    }

    if (Test-Path -LiteralPath $roadmapScript) {
        try {
            $roadmapJson = & $roadmapScript -RootPath $repoRoot
            if ($roadmapJson) {
                try { $roadmapResult = $roadmapJson | ConvertFrom-Json -ErrorAction Stop } catch { $roadmapResult = $null }
            }
        }
        catch {
            $roadmapResult = [pscustomobject]@{
                ok    = $false
                error = $_.Exception.Message
            }
        }
    }

    if (Test-Path -LiteralPath $tasksScript) {
        try {
            $tasksJson = & $tasksScript -RootPath $repoRoot
            if ($tasksJson) {
                try { $tasksResult = $tasksJson | ConvertFrom-Json -ErrorAction Stop } catch { $tasksResult = $null }
            }
        }
        catch {
            $tasksResult = [pscustomobject]@{
                ok    = $false
                error = $_.Exception.Message
            }
        }
    }

    $ingestOk = ($ingestResult -and $ingestResult.ok)
    $roadmapOk = ($null -eq $roadmapResult) -or ($roadmapResult.PSObject.Properties.Name -contains "ok" -and [bool]$roadmapResult.ok)
    $tasksOk = ($null -eq $tasksResult) -or ($tasksResult.PSObject.Properties.Name -contains "generated_at_utc")

    if ($ingestOk -and $roadmapOk -and $tasksOk -and (Test-Path -LiteralPath $mirrorUpdateScript)) {
        try {
            $mirrorJson = & $mirrorUpdateScript -RootPath $repoRoot -Reason "post-ingest"
            if ($mirrorJson) {
                try { $mirrorResult = $mirrorJson | ConvertFrom-Json -ErrorAction Stop } catch { $mirrorResult = $null }
            }
        }
        catch {
            $mirrorResult = [pscustomobject]@{
                ok    = $false
                error = $_.Exception.Message
            }
        }
    }
}

# Normalize ingest index files[] from authoritative staged manifest so
# file accounting is correct even when running storage_only.
$ingestIndexPath = $null
$ingestIndexObject = $null
if ($ingestResult -and ($ingestResult.PSObject.Properties.Name -contains "ingest_index")) {
    $candidate = [string]$ingestResult.ingest_index
    if ($candidate) {
        if ([System.IO.Path]::IsPathRooted($candidate)) {
            $ingestIndexPath = $candidate
        }
        else {
            $ingestIndexPath = Join-Path $repoRoot $candidate
        }
    }
}
if ($ingestIndexPath -and (Test-Path -LiteralPath $ingestIndexPath)) {
    $ingestIndexObject = Read-JsonSafe -Path $ingestIndexPath -Default $null
}
if (-not $ingestIndexObject -and $stageSuccessCount -gt 0) {
    if (-not $ingestIndexPath) {
        $ingestIndexPath = Join-Path $reportsDir ("ingest_index_{0}.json" -f $runId)
    }

    $fallbackFiles = New-Object System.Collections.Generic.List[object]
    $fallbackChunks = New-Object System.Collections.Generic.List[object]
    $fallbackChunkTotal = 0
    $fileOrdinal = 0
    foreach ($item in @($stagedManifest.ToArray())) {
        $fileOrdinal++
        $fallbackFiles.Add([ordered]@{
                name          = [string]$item.name
                source_path   = [string]$item.source_path
                staged_path   = [string]$item.staged_path
                processed_path = [string]$item.processed_path
                source_root   = [string]$item.source_root
                relative_name = [string]$item.relative_name
                bytes         = [int64]$item.bytes
                sha256        = [string]$item.sha256
            }) | Out-Null

        $text = ""
        try {
            $text = Get-Content -LiteralPath ([string]$item.staged_path) -Raw -Encoding UTF8 -ErrorAction Stop
        }
        catch {
            try { $text = Get-Content -LiteralPath ([string]$item.staged_path) -Raw -ErrorAction Stop } catch { $text = "" }
        }

        $chars = if ($text) { $text.Length } else { 0 }
        $chunkCountForFile = if ($chars -gt 0) { [int][Math]::Ceiling($chars / [double]$maxCharsPerChunk) } else { 0 }
        for ($chunkIndex = 1; $chunkIndex -le $chunkCountForFile; $chunkIndex++) {
            $fallbackChunkTotal++
            $fallbackChunks.Add([ordered]@{
                    run_id           = $runId
                    source_file      = [string]$item.source_path
                    staged_path      = [string]$item.staged_path
                    chunk_index      = [int]$chunkIndex
                    chunk_chars      = if ($chars -gt 0) { [Math]::Min($maxCharsPerChunk, $chars - (($chunkIndex - 1) * $maxCharsPerChunk)) } else { 0 }
                    pending_llm      = $true
                    mode             = "storage_only"
                    label            = ("drop-autopilot|{0}|chunk:{1}" -f [string]$item.name, $chunkIndex)
                    created_at_utc   = (Get-Date).ToUniversalTime().ToString("o")
                    summary          = ""
                    decisions        = @()
                    rules            = @()
                    done_items       = @()
                    open_items       = @()
                    tags             = @()
                    error            = if (-not $ingestEndpointOk) { "athena_unreachable" } elseif ($policyForcesStorageOnly) { "storage_only_mode" } else { "ingest_index_fallback" }
                    pending_queue_path = $null
                }) | Out-Null
        }
    }

    $ingestIndexObject = [ordered]@{
        run_id         = $runId
        created_at_utc = (Get-Date).ToUniversalTime().ToString("o")
        label          = "drop-autopilot"
        source         = "ingest_autopilot"
        ingest_url     = [string]$policy.ingest_url
        no_llm         = $true
        mode           = if ($fallbackChunkTotal -gt 0) { "storage_only" } else { "idle" }
        files          = @($fallbackFiles.ToArray())
        chunks         = @($fallbackChunks.ToArray())
        open_items     = @()
        done_items     = @()
        decisions      = @()
        rules          = @()
        tags           = @()
        stats          = [ordered]@{
            files_total        = [int]$stageSuccessCount
            chunks_total       = [int]$fallbackChunkTotal
            chunks_llm_called  = 0
            chunks_pending_llm = [int]$fallbackChunkTotal
            chunks_failed      = 0
        }
    }
    Write-JsonFile -Path $ingestIndexPath -Object $ingestIndexObject -Depth 20
    Add-TraceEvent -TracePath $tracePath -Step "ingest_index_fallback_created" -Result "ok" -File $ingestIndexPath

    if (-not $ingestResult) {
        $ingestResult = [pscustomobject]@{
            ok          = $false
            run_id      = $runId
            ingest_index = $ingestIndexPath
            error       = "ingest_result_missing_created_fallback_index"
            counts      = [ordered]@{
                files_processed   = [int]$stageSuccessCount
                chunks_total      = [int]$fallbackChunkTotal
                chunks_llm_called = 0
                chunks_pending_llm = [int]$fallbackChunkTotal
                chunks_failed     = 0
            }
        }
    }
}
if ($ingestIndexObject -and $stageSuccessCount -gt 0) {
    $manifestFiles = New-Object System.Collections.Generic.List[object]
    foreach ($item in @($stagedManifest.ToArray())) {
        $manifestFiles.Add([ordered]@{
                name          = [string]$item.name
                source_path   = [string]$item.source_path
                staged_path   = [string]$item.staged_path
                processed_path = [string]$item.processed_path
                source_root   = [string]$item.source_root
                relative_name = [string]$item.relative_name
                bytes         = [int64]$item.bytes
                sha256        = [string]$item.sha256
            }) | Out-Null
    }

    if (-not ($ingestIndexObject.PSObject.Properties.Name -contains "files")) {
        Add-Member -InputObject $ingestIndexObject -MemberType NoteProperty -Name "files" -Value @() -Force
    }
    $ingestIndexObject.files = @($manifestFiles.ToArray())

    if (-not ($ingestIndexObject.PSObject.Properties.Name -contains "stats") -or -not $ingestIndexObject.stats) {
        Add-Member -InputObject $ingestIndexObject -MemberType NoteProperty -Name "stats" -Value ([ordered]@{}) -Force
    }
    $stats = $ingestIndexObject.stats
    $chunksFromList = 0
    if ($ingestIndexObject.PSObject.Properties.Name -contains "chunks") {
        $chunksFromList = @($ingestIndexObject.chunks).Count
    }
    $statsFilesTotal = $stageSuccessCount
    $statsChunksTotal = Get-IntField -Object $stats -Name "chunks_total" -Default 0
    $statsChunksLlmCalled = Get-IntField -Object $stats -Name "chunks_llm_called" -Default 0
    $statsChunksPending = Get-IntField -Object $stats -Name "chunks_pending_llm" -Default 0
    $statsChunksFailed = Get-IntField -Object $stats -Name "chunks_failed" -Default 0

    if ($chunksFromList -gt $statsChunksTotal) { $statsChunksTotal = $chunksFromList }
    if ($statsChunksTotal -lt 0) { $statsChunksTotal = 0 }
    if ($statsChunksLlmCalled -lt 0) { $statsChunksLlmCalled = 0 }
    if ($statsChunksPending -lt 0) { $statsChunksPending = 0 }
    if ($statsChunksFailed -lt 0) { $statsChunksFailed = 0 }

    if ($forceStorageOnly -or $policyForcesStorageOnly) {
        if ($statsChunksTotal -gt 0) {
            $statsChunksPending = $statsChunksTotal
            $statsChunksLlmCalled = 0
        }
    }
    elseif ($statsChunksTotal -gt 0 -and ($statsChunksLlmCalled + $statsChunksPending) -gt $statsChunksTotal) {
        $statsChunksPending = [Math]::Max(0, $statsChunksTotal - $statsChunksLlmCalled)
    }

    $stats.files_total = [int]$statsFilesTotal
    $stats.chunks_total = [int]$statsChunksTotal
    $stats.chunks_llm_called = [int]$statsChunksLlmCalled
    $stats.chunks_pending_llm = [int]$statsChunksPending
    $stats.chunks_failed = [int]$statsChunksFailed

    if ($statsChunksTotal -gt 0 -and $statsChunksLlmCalled -gt 0) {
        $ingestIndexObject.mode = "llm"
    }
    elseif ($statsChunksTotal -gt 0) {
        $ingestIndexObject.mode = "storage_only"
    }
    else {
        $ingestIndexObject.mode = "idle"
    }
    $ingestIndexObject.no_llm = ($statsChunksLlmCalled -eq 0)

    Write-JsonFile -Path $ingestIndexPath -Object $ingestIndexObject -Depth 20
    Add-TraceEvent -TracePath $tracePath -Step "ingest_index_normalized" -Result "ok" -File $ingestIndexPath
}
elseif ($stageSuccessCount -gt 0) {
    Add-TraceEvent -TracePath $tracePath -Step "ingest_index_normalized" -Result "skip" -Error "missing_ingest_index"
}

if (-not $modeReason -and $ingestResult -and ($ingestResult.PSObject.Properties.Name -contains "counts") -and $ingestResult.counts -and ($ingestResult.counts.PSObject.Properties.Name -contains "mode_reason")) {
    $ingestModeReason = [string]$ingestResult.counts.mode_reason
    if ($ingestModeReason -and $ingestModeReason.Trim()) {
        $modeReason = $ingestModeReason.Trim()
    }
}

$filesProcessedCount = 0
$chunksTotalCount = 0
$chunksLlmCalledCount = 0
$chunksPendingLlmCount = 0
$chunksFailedCount = 0

$ingestCounts = $null
if ($ingestResult -and ($ingestResult.PSObject.Properties.Name -contains "counts") -and $ingestResult.counts) {
    $ingestCounts = $ingestResult.counts
}

if ($ingestCounts) {
    $filesProcessedCount = Get-IntField -Object $ingestCounts -Name "files_processed" -Default 0
    $chunksTotalCount = Get-IntField -Object $ingestCounts -Name "chunks_total" -Default 0
    $chunksLlmCalledCount = Get-IntField -Object $ingestCounts -Name "chunks_llm_called" -Default 0
    $chunksPendingLlmCount = Get-IntField -Object $ingestCounts -Name "chunks_pending_llm" -Default 0
    $chunksFailedCount = Get-IntField -Object $ingestCounts -Name "chunks_failed" -Default 0
}

if ($ingestIndexObject -and ($ingestIndexObject.PSObject.Properties.Name -contains "stats") -and $ingestIndexObject.stats) {
    $filesProcessedCount = Get-IntField -Object $ingestIndexObject.stats -Name "files_total" -Default $filesProcessedCount
    $chunksTotalCount = Get-IntField -Object $ingestIndexObject.stats -Name "chunks_total" -Default $chunksTotalCount
    $chunksLlmCalledCount = Get-IntField -Object $ingestIndexObject.stats -Name "chunks_llm_called" -Default $chunksLlmCalledCount
    $chunksPendingLlmCount = Get-IntField -Object $ingestIndexObject.stats -Name "chunks_pending_llm" -Default $chunksPendingLlmCount
    $chunksFailedCount = Get-IntField -Object $ingestIndexObject.stats -Name "chunks_failed" -Default $chunksFailedCount
}

if ($stageSuccessCount -gt 0 -and $filesProcessedCount -le 0) {
    $filesProcessedCount = if ($movedCount -gt 0) { $movedCount } else { $stageSuccessCount }
}

if ($forceStorageOnly -and $chunksTotalCount -gt 0) {
    $chunksPendingLlmCount = $chunksTotalCount
    $chunksLlmCalledCount = 0
}

$finalMode = "idle"
if ($stageSuccessCount -gt 0) {
    if ($chunksLlmCalledCount -gt 0) {
        $finalMode = "llm"
    }
    else {
        $finalMode = "storage_only"
    }
}

if ($detectedCount -eq 0) {
    $modeReason = "no_files_found"
}

if (-not $modeReason) {
    if ($detectedCount -eq 0) {
        $modeReason = "no_files_found"
    }
    elseif (-not $ingestEndpointOk) {
        $modeReason = "athena_unreachable"
    }
    elseif ($finalMode -eq "storage_only" -and $stageSuccessCount -gt 0) {
        $chunkErrors = @()
        if ($ingestIndexObject -and ($ingestIndexObject.PSObject.Properties.Name -contains "chunks")) {
            foreach ($c in @($ingestIndexObject.chunks)) {
                if (-not $c) { continue }
                if ($c.PSObject.Properties.Name -contains "error") {
                    $err = [string]$c.error
                    if ($err) { $chunkErrors += $err }
                }
            }
        }
        if (@($chunkErrors | Where-Object { $_ -eq "budget_exhausted" }).Count -gt 0) {
            $modeReason = "budget_exhausted"
        }
        elseif ($policyForcesStorageOnly) {
            $modeReason = "forced_storage_only"
        }
        else {
            $modeReason = "ok"
        }
    }
    else {
        $modeReason = "ok"
    }
}

$allowedModeReasons = @("no_files_found", "ok", "athena_unreachable", "budget_exhausted", "forced_storage_only")
if ($allowedModeReasons -notcontains $modeReason) {
    $modeReason = if ($detectedCount -eq 0) { "no_files_found" } elseif ($finalMode -eq "storage_only") { "forced_storage_only" } else { "ok" }
}

$summary = [ordered]@{
    run_id                  = $runId
    updated_at_utc          = (Get-Date).ToUniversalTime().ToString("o")
    mode                    = $finalMode
    mode_reason             = $modeReason
    ingest_endpoint_ok      = $ingestEndpointOk
    endpoint_ok             = $ingestEndpointOk
    masonconsole_started    = $masonconsoleStarted
    source_paths_scanned    = @($scanRoots.ToArray())
    source_path_file_counts = $sourcePathFileCounts
    sample_files            = @($sampleFiles.ToArray())
    files_processed         = [int]$filesProcessedCount
    chunks_total            = [int]$chunksTotalCount
    chunks_llm_called       = [int]$chunksLlmCalledCount
    chunks_pending_llm      = [int]$chunksPendingLlmCount
    chunks_failed           = [int]$chunksFailedCount
    staged_files_count      = $stagedCount
    moved_to_processed_count = $movedCount
    skipped_count           = $skippedCount
    staging_root            = $stagingRoot
    processed_dir           = $processedDir
    ingest_result           = $ingestResult
    roadmap_result          = $roadmapResult
    tasks_result            = $tasksResult
    mirror_update_result    = $mirrorResult
    flatten_enabled         = [bool]$useFlattenedInbox
    flatten_source_dir      = if ($useFlattenedInbox) { $flattenSourceDir } else { $null }
    flatten_target_dir      = if ($useFlattenedInbox) { $flattenTargetDir } else { $null }
    flatten_result          = $flattenResult
    endpoint_status         = $endpointState
}

Write-JsonFile -Path $statusPath -Object $summary -Depth 14
Add-EventLine -ReportsDir $reportsDir -Kind "ingest_run" -Status "completed" -CorrelationId $runId -Details @{
    mode                    = $finalMode
    mode_reason             = $modeReason
    files_processed         = [int]$filesProcessedCount
    chunks_total            = [int]$chunksTotalCount
    chunks_pending_llm      = [int]$chunksPendingLlmCount
    ingest_endpoint_ok      = [bool]$ingestEndpointOk
    masonconsole_started    = [bool]$masonconsoleStarted
}
$summary | ConvertTo-Json -Depth 14
