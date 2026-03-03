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
    return (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
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
        return $Default
    }
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object,
        [int]$Depth = 16
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Set-Content -LiteralPath $Path -Value ($Object | ConvertTo-Json -Depth $Depth) -Encoding UTF8
}

function Append-JsonLine {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Add-Content -LiteralPath $Path -Value ($Object | ConvertTo-Json -Compress -Depth 12) -Encoding UTF8
}

function Get-RelativePathSafe {
    param(
        [Parameter(Mandatory = $true)][string]$BasePath,
        [Parameter(Mandatory = $true)][string]$FullPath
    )
    try {
        $baseResolved = (Resolve-Path -LiteralPath $BasePath -ErrorAction Stop).Path
        $fullResolved = [IO.Path]::GetFullPath($FullPath)
        if ($fullResolved.StartsWith($baseResolved, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $fullResolved.Substring($baseResolved.Length).TrimStart("\", "/").Replace("/", "\")
        }
        return $fullResolved
    }
    catch {
        return $FullPath
    }
}

function Get-FileHashSafe {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }
    try {
        return (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant()
    }
    catch {
        return $null
    }
}

function New-Sha256Hex {
    param([string]$InputText)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputText)
        $hash = $sha.ComputeHash($bytes)
    }
    finally {
        $sha.Dispose()
    }
    return (-join ($hash | ForEach-Object { $_.ToString("x2") }))
}

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
$stateDir = Join-Path $repoRoot "state\knowledge"
New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
New-Item -ItemType Directory -Path $stateDir -Force | Out-Null

$manifestPath = Join-Path $reportsDir "drift_manifest.json"
$historyPath = Join-Path $reportsDir "drift_manifest_history.jsonl"
$pendingPath = Join-Path $stateDir "pending_patch_runs.json"
$eventsPath = Join-Path $reportsDir "events.jsonl"

if (-not (Test-Path -LiteralPath $pendingPath)) {
    "[]" | Set-Content -LiteralPath $pendingPath -Encoding UTF8
}

$onyxLauncherPath = $null
$onyxRoot = Join-Path $repoRoot "Component - Onyx App\onyx_business_manager"
if (Test-Path -LiteralPath $onyxRoot) {
    $candidate = Get-ChildItem -LiteralPath $onyxRoot -Filter "Start-Onyx5353.ps1" -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($candidate) {
        $onyxLauncherPath = $candidate.FullName
    }
}

$trackList = @(
    "Start_Mason2.ps1",
    "Start-Athena.ps1",
    "tools\launch\Start_Mason_FullStack.ps1",
    "tools\launch\Start_Mason_CoreOnly.ps1",
    "tools\launch\Create_Mason_Shortcuts.ps1",
    "MasonConsole\server.py",
    "MasonConsole\static\athena\index.html",
    "MasonConsole\static\athena\manifest.webmanifest",
    "MasonConsole\static\athena\sw.js",
    "tools\Mason_Doctor.ps1",
    "tools\Mason_Component_Inventory.ps1",
    "tools\Mason_TaskGen_Run.ps1",
    "tools\ingest\Mason_IngestDrop_Once.ps1",
    "tools\ingest\Mason_Inbox_Flatten.ps1",
    "tools\sync\Mason_Mirror_Update.ps1",
    "config\ports.json",
    "config\component_registry.json",
    "config\remote_access_policy.json",
    "config\mirror_policy.json",
    "config\tool_registry.json",
    "config\tiers.json",
    "config\addons.json",
    "config\onboarding_questions.json"
)
if ($onyxLauncherPath) {
    $trackList += (Get-RelativePathSafe -BasePath $repoRoot -FullPath $onyxLauncherPath)
}
$trackList = @($trackList | Select-Object -Unique)

$files = New-Object System.Collections.Generic.List[object]
foreach ($rel in $trackList) {
    $full = if ([IO.Path]::IsPathRooted($rel)) { $rel } else { Join-Path $repoRoot $rel }
    $exists = Test-Path -LiteralPath $full
    $hash = if ($exists) { Get-FileHashSafe -Path $full } else { $null }
    $lastWriteUtc = $null
    if ($exists) {
        try { $lastWriteUtc = (Get-Item -LiteralPath $full -ErrorAction Stop).LastWriteTimeUtc.ToString("o") } catch { $lastWriteUtc = $null }
    }
    $files.Add([ordered]@{
            path           = Get-RelativePathSafe -BasePath $repoRoot -FullPath $full
            exists         = [bool]$exists
            sha256         = $hash
            last_write_utc = $lastWriteUtc
        }) | Out-Null
}

$currentByPath = @{}
foreach ($f in @($files.ToArray())) {
    $currentByPath[[string]$f.path] = $f
}

$previous = Read-JsonSafe -Path $manifestPath -Default $null
$previousByPath = @{}
if ($previous -and ($previous.PSObject.Properties.Name -contains "files")) {
    foreach ($f in @($previous.files)) {
        if (-not $f -or -not $f.path) { continue }
        $previousByPath[[string]$f.path] = $f
    }
}

$driftFindings = New-Object System.Collections.Generic.List[object]
foreach ($path in $currentByPath.Keys) {
    $cur = $currentByPath[$path]
    if (-not $previousByPath.ContainsKey($path)) {
        $driftFindings.Add([ordered]@{
                type  = "new_tracked_file"
                path  = $path
                old   = $null
                new   = $cur.sha256
            }) | Out-Null
        continue
    }
    $old = $previousByPath[$path]
    $oldHash = if ($old.PSObject.Properties.Name -contains "sha256") { [string]$old.sha256 } else { "" }
    $newHash = if ($cur.sha256) { [string]$cur.sha256 } else { "" }
    if ($oldHash -ne $newHash -or [bool]$old.exists -ne [bool]$cur.exists) {
        $driftFindings.Add([ordered]@{
                type  = "hash_changed"
                path  = $path
                old   = $oldHash
                new   = $newHash
            }) | Out-Null
    }
}
foreach ($path in $previousByPath.Keys) {
    if (-not $currentByPath.ContainsKey($path)) {
        $driftFindings.Add([ordered]@{
                type  = "removed_tracked_file"
                path  = $path
                old   = if ($previousByPath[$path].sha256) { [string]$previousByPath[$path].sha256 } else { "" }
                new   = $null
            }) | Out-Null
    }
}

$mirrorLast = Read-JsonSafe -Path (Join-Path $reportsDir "mirror_update_last.json") -Default $null
$expectedUpdatePipeline = $false
if ($mirrorLast -and ($mirrorLast.PSObject.Properties.Name -contains "ok") -and [bool]$mirrorLast.ok) {
    $reason = ""
    if ($mirrorLast.PSObject.Properties.Name -contains "reason") {
        $reason = [string]$mirrorLast.reason
    }
    $knownReasons = @("post-ingest", "post-apply", "hourly", "post-epic")
    $recentEnough = $false
    if ($mirrorLast.PSObject.Properties.Name -contains "timestamp_utc" -and $mirrorLast.timestamp_utc) {
        $dt = [datetime]::MinValue
        if ([datetime]::TryParse([string]$mirrorLast.timestamp_utc, [ref]$dt)) {
            $recentEnough = ($dt.ToUniversalTime() -ge (Get-Date).ToUniversalTime().AddMinutes(-30))
        }
    }
    if ($knownReasons -contains $reason -and $recentEnough) {
        $expectedUpdatePipeline = $true
    }
}

$generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
$fingerprint = New-Sha256Hex -InputText ((@($driftFindings.ToArray() | ForEach-Object { "{0}|{1}|{2}|{3}" -f $_.type, $_.path, $_.old, $_.new }) -join "`n"))

$manifest = [ordered]@{
    generated_at_utc = $generatedAtUtc
    root_path        = $repoRoot
    expected_update_pipeline = [bool]$expectedUpdatePipeline
    tracked_count    = @($files.ToArray()).Count
    drift_count      = @($driftFindings.ToArray()).Count
    drift_fingerprint = $fingerprint
    onyx_launcher_path = if ($onyxLauncherPath) { Get-RelativePathSafe -BasePath $repoRoot -FullPath $onyxLauncherPath } else { $null }
    files            = @($files.ToArray())
    drift_findings   = @($driftFindings.ToArray())
}

Write-JsonFile -Path $manifestPath -Object $manifest -Depth 20
Append-JsonLine -Path $historyPath -Object ([ordered]@{
        generated_at_utc       = $generatedAtUtc
        tracked_count          = $manifest.tracked_count
        drift_count            = $manifest.drift_count
        expected_update_pipeline = $manifest.expected_update_pipeline
        drift_fingerprint      = $fingerprint
    })

$approvalQueued = $false
$approvalId = $null
if (@($driftFindings.ToArray()).Count -gt 0 -and -not $expectedUpdatePipeline) {
    $approvalId = ("drift-manifest-{0}" -f $fingerprint.Substring(0, 12))
    $pending = Read-JsonSafe -Path $pendingPath -Default @()
    $items = @()
    foreach ($x in @($pending)) {
        if ($x) { $items += $x }
    }
    $exists = $false
    foreach ($x in $items) {
        if ($x -and $x.id -and ([string]$x.id -eq $approvalId)) {
            $exists = $true
            break
        }
    }
    if (-not $exists) {
        $items += [ordered]@{
            id             = $approvalId
            component_id   = "mason"
            title          = "Review unexpected drift manifest changes"
            risk_level     = 1
            status         = "pending"
            source         = "drift_manifest"
            created_at     = $generatedAtUtc
            evidence_files = @(
                "reports/drift_manifest.json",
                "reports/drift_manifest_history.jsonl"
            )
        }
        Write-JsonFile -Path $pendingPath -Object $items -Depth 20
        $approvalQueued = $true
    }
}

Append-JsonLine -Path $eventsPath -Object ([ordered]@{
        ts_utc         = $generatedAtUtc
        kind           = "drift_manifest"
        status         = "completed"
        component      = "drift"
        correlation_id = ("drift-{0}" -f $generatedAtUtc.Replace("-", "").Replace(":", "").Replace("T", "").Replace("Z", ""))
        details        = [ordered]@{
            drift_count             = @($driftFindings.ToArray()).Count
            expected_update_pipeline = [bool]$expectedUpdatePipeline
            approval_queued         = [bool]$approvalQueued
            approval_id             = $approvalId
            report_path             = $manifestPath
        }
    })

[pscustomobject]@{
    ok                     = $true
    report_path            = $manifestPath
    history_path           = $historyPath
    drift_count            = @($driftFindings.ToArray()).Count
    expected_update_pipeline = [bool]$expectedUpdatePipeline
    approval_queued        = [bool]$approvalQueued
    approval_id            = $approvalId
} | ConvertTo-Json -Depth 10
