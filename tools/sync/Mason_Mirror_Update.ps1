[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$MirrorPath = "C:\Users\Chris\Desktop\Mason2_MIRROR",
    [string]$Reason = "manual"
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

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object,
        [int]$Depth = 10
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Set-Content -LiteralPath $Path -Value ($Object | ConvertTo-Json -Depth $Depth) -Encoding UTF8
}

function Add-JsonLine {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Add-Content -LiteralPath $Path -Value ($Object | ConvertTo-Json -Compress -Depth 10) -Encoding UTF8
}

function Read-JsonSafe {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        $Default = $null
    )
    if (-not (Test-Path -LiteralPath $Path)) {
        return $Default
    }
    try {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
        if (-not $raw.Trim()) {
            return $Default
        }
        return $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return $Default
    }
}

function Invoke-GitCapture {
    param(
        [Parameter(Mandatory = $true)][string]$RepoPath,
        [Parameter(Mandatory = $true)][string[]]$Args
    )
    try {
        $output = & git -C $RepoPath @Args 2>&1
        $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { [int]$LASTEXITCODE }
        return [pscustomobject]@{
            ok      = ($exitCode -eq 0)
            exit    = $exitCode
            lines   = @($output | ForEach-Object { [string]$_ })
            joined  = ((@($output) -join "`n").Trim())
        }
    }
    catch {
        return [pscustomobject]@{
            ok      = $false
            exit    = 1
            lines   = @($_.Exception.Message)
            joined  = [string]$_.Exception.Message
        }
    }
}

function Get-MirrorDeltaSummary {
    param(
        [Parameter(Mandatory = $true)][string]$MirrorRoot,
        [string]$HeadBefore = "",
        [string]$HeadAfter = ""
    )

    $added = 0
    $modified = 0
    $removed = 0
    $topChanged = New-Object System.Collections.Generic.List[string]

    if ($HeadAfter -and $HeadBefore -and $HeadAfter -ne $HeadBefore) {
        $show = Invoke-GitCapture -RepoPath $MirrorRoot -Args @("show", "--name-status", "--pretty=", $HeadAfter)
        if ($show.ok) {
            foreach ($line in $show.lines) {
                $trim = ([string]$line).Trim()
                if (-not $trim) { continue }
                $parts = $trim -split "\s+", 2
                if ($parts.Count -lt 2) { continue }
                $status = $parts[0].ToUpperInvariant()
                $path = $parts[1]
                if ($topChanged.Count -lt 20) {
                    $topChanged.Add($path) | Out-Null
                }
                if ($status.StartsWith("A")) { $added++ ; continue }
                if ($status.StartsWith("D")) { $removed++ ; continue }
                if ($status.StartsWith("M") -or $status.StartsWith("R") -or $status.StartsWith("C")) { $modified++ ; continue }
            }
        }
    }
    else {
        $status = Invoke-GitCapture -RepoPath $MirrorRoot -Args @("status", "--porcelain")
        if ($status.ok) {
            foreach ($line in $status.lines) {
                $trim = ([string]$line)
                if (-not $trim.Trim()) { continue }
                $code = $trim.Substring(0, [Math]::Min(2, $trim.Length)).Trim()
                $path = $trim.Substring([Math]::Min(3, $trim.Length)).Trim()
                if ($topChanged.Count -lt 20 -and $path) {
                    $topChanged.Add($path) | Out-Null
                }
                if ($code -eq "??") { $added++ ; continue }
                if ($code.Contains("A")) { $added++ ; continue }
                if ($code.Contains("D")) { $removed++ ; continue }
                $modified++
            }
        }
    }

    return [ordered]@{
        generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
        mirror_root      = $MirrorRoot
        changed_count    = [int]($added + $modified + $removed)
        added_count      = [int]$added
        modified_count   = [int]$modified
        removed_count    = [int]$removed
        top_changed_paths = @($topChanged.ToArray())
        head_before      = $HeadBefore
        head_after       = $HeadAfter
    }
}

function Normalize-Reason {
    param([string]$Value)

    $reason = ([string]$Value).Trim().ToLowerInvariant()
    if (-not $reason) {
        return "manual"
    }

    switch ($reason) {
        "postingest" { $reason = "post-ingest"; break }
        "postapply" { $reason = "post-apply"; break }
        default { }
    }

    $reason = [regex]::Replace($reason, "[^a-z0-9._-]+", "-")
    $reason = [regex]::Replace($reason, "-{2,}", "-").Trim("-", "_", ".")
    if (-not $reason) {
        return "manual"
    }

    if ($reason.Length -gt 64) {
        $reason = $reason.Substring(0, 64).TrimEnd("-", "_", ".")
        if (-not $reason) {
            return "manual"
        }
    }

    return $reason
}

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
if (-not (Test-Path -LiteralPath $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}

$mirrorManifestScript = Join-Path $repoRoot "tools\Write_MirrorManifest.ps1"
$knowledgePackScript = Join-Path $repoRoot "tools\knowledge\Mason_Export_KnowledgePack.ps1"
$mirrorPushScript = Join-Path $MirrorPath "tools\MIRROR_Push.ps1"
$mirrorSecretGateScript = Join-Path $MirrorPath "tools\MIRROR_SecretGate.ps1"
$lastReportPath = Join-Path $reportsDir "mirror_update_last.json"
$logPath = Join-Path $reportsDir "mirror_update_log.jsonl"
$eventsPath = Join-Path $reportsDir "events.jsonl"
$mirrorDeltaPath = Join-Path $repoRoot "docs\mirror_delta.json"
$mirrorManifestPath = Join-Path $repoRoot "docs\mirror_manifest.json"

$reasonNormalized = Normalize-Reason -Value $Reason
$commitMessage = "mirror: $reasonNormalized"

$result = [ordered]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    reason_requested = $Reason
    reason        = $reasonNormalized
    commit_message = $commitMessage
    repo_root     = $repoRoot
    mirror_root   = $MirrorPath
    steps         = [ordered]@{
        write_mirror_manifest = "pending"
        verify_mirror_state   = "pending"
        export_knowledge_pack = "pending"
        run_secret_gate       = "pending"
        mirror_push           = "pending"
    }
    ok            = $false
    error         = $null
}

$headBefore = ""
if (Test-Path -LiteralPath $MirrorPath) {
    $headBeforeResult = Invoke-GitCapture -RepoPath $MirrorPath -Args @("rev-parse", "HEAD")
    if ($headBeforeResult.ok) {
        $headBefore = [string]$headBeforeResult.joined
    }
}

try {
    if (-not (Test-Path -LiteralPath $mirrorManifestScript)) {
        throw "Missing script: $mirrorManifestScript"
    }
    & $mirrorManifestScript -RootPath $repoRoot -MirrorPath $MirrorPath | Out-Null
    $result.steps.write_mirror_manifest = "ok"

    $manifest = Read-JsonSafe -Path $mirrorManifestPath -Default $null
    if (-not $manifest) {
        throw "Mirror manifest missing or invalid after generation: $mirrorManifestPath"
    }
    $missingAllowlist = @()
    if ($manifest.PSObject.Properties.Name -contains "missing_from_mirror" -and $manifest.missing_from_mirror) {
        $missing = $manifest.missing_from_mirror
        if ($missing.PSObject.Properties.Name -contains "allowlist_names_absent_in_mirror") {
            $missingAllowlist = @($missing.allowlist_names_absent_in_mirror | ForEach-Object { [string]$_ } | Where-Object { $_ })
        }
    }
    if ($missingAllowlist.Count -gt 0) {
        throw ("Mirror missing allowlisted top-level items: {0}" -f (($missingAllowlist | Sort-Object -Unique) -join ", "))
    }
    $result.steps.verify_mirror_state = "ok"

    if (-not (Test-Path -LiteralPath $knowledgePackScript)) {
        throw "Missing script: $knowledgePackScript"
    }
    & $knowledgePackScript -RootPath $repoRoot | Out-Null
    $result.steps.export_knowledge_pack = "ok"

    if (-not (Test-Path -LiteralPath $mirrorSecretGateScript)) {
        throw "Missing mirror secret gate script: $mirrorSecretGateScript"
    }
    & $mirrorSecretGateScript -RootPath $MirrorPath | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Mirror secret gate failed."
    }
    $result.steps.run_secret_gate = "ok"

    if (-not (Test-Path -LiteralPath $mirrorPushScript)) {
        throw "Missing mirror push script: $mirrorPushScript"
    }
    & $mirrorPushScript -RootPath $MirrorPath -CommitMessage $commitMessage
    if ($LASTEXITCODE -ne 0) {
        throw "Mirror push failed with exit code $LASTEXITCODE."
    }
    $result.steps.mirror_push = "ok"
    $result.ok = $true
}
catch {
    $result.error = $_.Exception.Message
}

$headAfter = ""
if (Test-Path -LiteralPath $MirrorPath) {
    $headAfterResult = Invoke-GitCapture -RepoPath $MirrorPath -Args @("rev-parse", "HEAD")
    if ($headAfterResult.ok) {
        $headAfter = [string]$headAfterResult.joined
    }
}
$delta = Get-MirrorDeltaSummary -MirrorRoot $MirrorPath -HeadBefore $headBefore -HeadAfter $headAfter
Write-JsonFile -Path $mirrorDeltaPath -Object $delta -Depth 12

Write-JsonFile -Path $lastReportPath -Object $result -Depth 12
Add-JsonLine -Path $logPath -Object $result
Add-JsonLine -Path $eventsPath -Object ([ordered]@{
        ts_utc         = (Get-Date).ToUniversalTime().ToString("o")
        kind           = "mirror_update"
        status         = if ($result.ok) { "completed" } else { "failed" }
        component      = "mirror"
        correlation_id = ("mirror-{0}" -f ((Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")))
        details        = [ordered]@{
            reason         = $reasonNormalized
            commit_message = $commitMessage
            error          = $result.error
            delta_path     = $mirrorDeltaPath
            changed_count  = $delta.changed_count
            added_count    = $delta.added_count
            modified_count = $delta.modified_count
            removed_count  = $delta.removed_count
        }
    })

$result | ConvertTo-Json -Depth 12

if (-not $result.ok) {
    exit 1
}

exit 0
