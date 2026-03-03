[CmdletBinding()]
param(
    [string]$RootPath = "",
    [ValidateRange(1, 500)][int]$MaxTasks = 200,
    [switch]$SkipQueueSurface
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
    if (-not $raw.Trim()) { return $Default }
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

function To-Array {
    param($Value)
    if ($null -eq $Value) { return @() }
    if ($Value -is [System.Array]) { return $Value }
    return @($Value)
}

function Get-PropertyValue {
    param(
        $Object,
        [Parameter(Mandatory = $true)][string]$Name,
        $Default = $null
    )
    if ($null -eq $Object) { return $Default }
    if ($Object -is [hashtable]) {
        if ($Object.ContainsKey($Name)) { return $Object[$Name] }
        return $Default
    }
    if ($Object.PSObject -and ($Object.PSObject.Properties.Name -contains $Name)) {
        return $Object.$Name
    }
    return $Default
}

function New-HashId {
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
    return $hex.Substring(0, 12)
}

function Normalize-Risk {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [string[]]$Tags = @()
    )

    $haystack = ($Text + " " + ($Tags -join " ")).ToLowerInvariant()

    $critical = @("format disk", "drop database", "wipe", "exfiltrate", "disable defender", "disable firewall")
    foreach ($token in $critical) {
        if ($haystack.Contains($token)) { return 3 }
    }

    $high = @(
        "delete ", "remove-item", "registry", "firewall", "credential", "password", "private key", "token",
        "0.0.0.0", "bind all", "production db", "port exposure", "admin", "sudo", "elevated"
    )
    foreach ($token in $high) {
        if ($haystack.Contains($token)) { return 2 }
    }

    $low = @("docs", "documentation", "readme", "report", "status", "smoke", "test", "lint", "comment", "roadmap")
    foreach ($token in $low) {
        if ($haystack.Contains($token)) { return 0 }
    }

    return 1
}

function Get-RelativePathSafe {
    param(
        [Parameter(Mandatory = $true)][string]$BasePath,
        [Parameter(Mandatory = $true)][string]$FullPath
    )
    try {
        $baseResolved = (Resolve-Path -LiteralPath $BasePath -ErrorAction Stop).Path
        $fullResolved = (Resolve-Path -LiteralPath $FullPath -ErrorAction Stop).Path
        if ($fullResolved.StartsWith($baseResolved, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $fullResolved.Substring($baseResolved.Length).TrimStart("\", "/")
        }
        return $fullResolved
    }
    catch {
        return $FullPath
    }
}

function Convert-RiskLevelToText {
    param([int]$RiskLevel)
    switch ($RiskLevel) {
        0 { return "low" }
        1 { return "medium" }
        2 { return "high" }
        default { return "critical" }
    }
}

function Dedupe-ById {
    param($Items)
    $seen = @{}
    $output = New-Object System.Collections.Generic.List[object]
    foreach ($item in To-Array $Items) {
        if (-not $item) { continue }
        $idValue = Get-PropertyValue -Object $item -Name "id" -Default $null
        if (-not $idValue) {
            $output.Add($item) | Out-Null
            continue
        }
        $id = [string]$idValue
        if ($seen.ContainsKey($id)) { continue }
        $seen[$id] = $true
        $output.Add($item) | Out-Null
    }
    return @($output.ToArray())
}

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
$tasksDir = Join-Path $repoRoot "tasks\pending\mason"
$stateDir = Join-Path $repoRoot "state\knowledge"
$pendingPath = Join-Path $stateDir "pending_patch_runs.json"
$quarantinePath = Join-Path $stateDir "pending_patch_runs_quarantine.json"
$summaryReportPath = Join-Path $reportsDir "knowledge_tasks_last.json"

if (-not (Test-Path -LiteralPath $tasksDir)) {
    New-Item -ItemType Directory -Path $tasksDir -Force | Out-Null
}
if (-not (Test-Path -LiteralPath $stateDir)) {
    New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
}
if (-not (Test-Path -LiteralPath $pendingPath)) {
    "[]" | Set-Content -LiteralPath $pendingPath -Encoding UTF8
}
if (-not (Test-Path -LiteralPath $quarantinePath)) {
    "[]" | Set-Content -LiteralPath $quarantinePath -Encoding UTF8
}

$indexFiles = @(
    Get-ChildItem -Path $reportsDir -Filter "ingest_index_*.json" -File -ErrorAction SilentlyContinue |
    Sort-Object -Property LastWriteTimeUtc -Descending
)

$candidates = New-Object System.Collections.Generic.List[object]
$seenOpen = @{}

foreach ($indexFile in $indexFiles) {
    $index = Read-JsonSafe -Path $indexFile.FullName -Default $null
    if (-not $index) { continue }

    $runId = ""
    $runVal = Get-PropertyValue -Object $index -Name "run_id" -Default ""
    if ($runVal) { $runId = [string]$runVal }
    $indexRel = Get-RelativePathSafe -BasePath $repoRoot -FullPath $indexFile.FullName
    $indexTags = @((To-Array (Get-PropertyValue -Object $index -Name "tags" -Default @())) | ForEach-Object { [string]$_ } | Where-Object { $_ })

    foreach ($open in To-Array (Get-PropertyValue -Object $index -Name "open_items" -Default @())) {
        $text = [string]$open
        $text = $text.Trim()
        if (-not $text) { continue }
        $key = $text.ToLowerInvariant()
        if ($seenOpen.ContainsKey($key)) { continue }
        $seenOpen[$key] = $true
        $candidates.Add([ordered]@{
                text      = $text
                run_id    = $runId
                tags      = $indexTags
                evidence  = @($indexRel)
            }) | Out-Null
    }

    foreach ($chunk in To-Array (Get-PropertyValue -Object $index -Name "chunks" -Default @())) {
        if (-not $chunk) { continue }
        $chunkTags = @((To-Array (Get-PropertyValue -Object $chunk -Name "tags" -Default @())) | ForEach-Object { [string]$_ } | Where-Object { $_ } | Select-Object -Unique)
        $allTags = @($indexTags + $chunkTags | Select-Object -Unique)
        foreach ($open in To-Array (Get-PropertyValue -Object $chunk -Name "open_items" -Default @())) {
            $text = [string]$open
            $text = $text.Trim()
            if (-not $text) { continue }
            $key = $text.ToLowerInvariant()
            if ($seenOpen.ContainsKey($key)) { continue }
            $seenOpen[$key] = $true
            $candidates.Add([ordered]@{
                    text      = $text
                    run_id    = $runId
                    tags      = $allTags
                    evidence  = @($indexRel)
                }) | Out-Null
        }
    }
}

$nowUtc = (Get-Date).ToUniversalTime().ToString("o")
$createdTasks = 0
$lowRiskQueued = 0
$highRiskQuarantined = 0

$pending = @(To-Array (Read-JsonSafe -Path $pendingPath -Default @()))
$quarantine = @(To-Array (Read-JsonSafe -Path $quarantinePath -Default @()))
$pendingIds = @{}
$quarantineIds = @{}
foreach ($item in $pending) {
    if (-not $item) { continue }
    $itemId = Get-PropertyValue -Object $item -Name "id" -Default $null
    if ($itemId) { $pendingIds[[string]$itemId] = $true }
}
foreach ($item in $quarantine) {
    if (-not $item) { continue }
    $itemId = Get-PropertyValue -Object $item -Name "id" -Default $null
    if ($itemId) { $quarantineIds[[string]$itemId] = $true }
}

$selectedCandidates = @($candidates.ToArray() | Select-Object -First $MaxTasks)
foreach ($candidate in $selectedCandidates) {
    $text = [string]$candidate.text
    $tags = @($candidate.tags)
    $risk = Normalize-Risk -Text $text -Tags $tags
    $taskHash = New-HashId -InputText ($text + "|" + ($tags -join "|"))
    $taskId = "knowledge-task-{0}" -f $taskHash
    $taskPath = Join-Path $tasksDir ("{0}.json" -f $taskId)

    $taskObj = [ordered]@{
        id          = $taskId
        source      = "knowledge_ingest"
        source_run_id = [string]$candidate.run_id
        status      = "pending"
        summary     = $text
        tags        = @($tags | Select-Object -Unique)
        risk_level  = [int]$risk
        risk        = Convert-RiskLevelToText -RiskLevel $risk
        evidence_files = @($candidate.evidence)
        created_at  = $nowUtc
        updated_at  = $nowUtc
    }

    if (-not (Test-Path -LiteralPath $taskPath)) {
        Write-JsonFile -Path $taskPath -Object $taskObj -Depth 12
        $createdTasks++
    }

    $approvalId = "knowledge-approval-{0}" -f $taskHash
    $approvalItem = [ordered]@{
        id             = $approvalId
        component_id   = "mason"
        title          = if ($text.Length -gt 120) { $text.Substring(0, 117) + "..." } else { $text }
        risk_level     = [int]$risk
        status         = "pending"
        source         = "knowledge_taskgen"
        created_at     = $nowUtc
        kind           = "patch_run"
        source_task    = $taskId
        evidence_files = @($candidate.evidence)
        tags           = @($tags | Select-Object -Unique)
    }

    if ($risk -le 1) {
        if (-not $pendingIds.ContainsKey($approvalId)) {
            $pending += [pscustomobject]$approvalItem
            $pendingIds[$approvalId] = $true
            $lowRiskQueued++
        }
    }
    else {
        $approvalItem["quarantine_reason"] = "risk_gt_r1_gate_from_knowledge"
        if (-not $quarantineIds.ContainsKey($approvalId)) {
            $quarantine += [pscustomobject]$approvalItem
            $quarantineIds[$approvalId] = $true
            $highRiskQuarantined++
        }
    }
}

$pending = Dedupe-ById -Items $pending
$quarantine = Dedupe-ById -Items $quarantine

Write-JsonFile -Path $pendingPath -Object $pending -Depth 20
Write-JsonFile -Path $quarantinePath -Object $quarantine -Depth 20

$tasksToApprovals = Join-Path $repoRoot "tools\Mason_Tasks_To_Approvals.ps1"
if (-not $SkipQueueSurface -and (Test-Path -LiteralPath $tasksToApprovals)) {
    & $tasksToApprovals -RootPath $repoRoot
}

$summary = [ordered]@{
    generated_at_utc      = (Get-Date).ToUniversalTime().ToString("o")
    ingest_indexes_seen   = $indexFiles.Count
    candidate_open_items  = $candidates.Count
    candidates_processed  = $selectedCandidates.Count
    tasks_created         = $createdTasks
    approvals_queued_low_risk = $lowRiskQueued
    approvals_quarantined_high_risk = $highRiskQuarantined
    paths = [ordered]@{
        tasks_dir       = $tasksDir
        pending         = $pendingPath
        quarantine      = $quarantinePath
    }
}

Write-JsonFile -Path $summaryReportPath -Object $summary -Depth 12
$summary | ConvertTo-Json -Depth 12
