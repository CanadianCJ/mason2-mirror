[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$PendingPath = "",
    [int]$MaxEligible = 200
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-FloodLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [Mason_Approvals_FloodControl] [$Level] $Message"
}

function To-Array {
    param($Value)
    if ($null -eq $Value) { return @() }
    if ($Value -is [System.Array]) { return $Value }
    return @($Value)
}

function To-OrderedMap {
    param($Value)
    $map = [ordered]@{}
    if ($null -eq $Value) { return $map }
    foreach ($p in $Value.PSObject.Properties) {
        $map[$p.Name] = $p.Value
    }
    return $map
}

function Convert-ToRiskInt {
    param($RiskValue)

    if ($null -eq $RiskValue) { return 1 }
    $raw = [string]$RiskValue
    if (-not $raw.Trim()) { return 1 }

    $n = 0
    if ([int]::TryParse($raw, [ref]$n)) {
        return [Math]::Min(3, [Math]::Max(0, $n))
    }

    $text = $raw.Trim().ToLowerInvariant()
    $m = [regex]::Match($text, "(\d+)")
    if ($m.Success) {
        $v = [int]$m.Groups[1].Value
        return [Math]::Min(3, [Math]::Max(0, $v))
    }

    switch ($text) {
        "observe_only" { return 0 }
        "observe-only" { return 0 }
        "observe" { return 0 }
        "low" { return 1 }
        "medium" { return 2 }
        "med" { return 2 }
        "high" { return 3 }
        "critical" { return 3 }
        default { return 1 }
    }
}

function Normalize-CreatedAt {
    param($Value)
    $dt = [datetime]::MinValue
    if ($Value -and [datetime]::TryParse([string]$Value, [ref]$dt)) {
        return $dt.ToUniversalTime()
    }
    return (Get-Date).ToUniversalTime()
}

function Get-DeterministicId {
    param(
        $Item
    )

    if ($Item.Contains("id") -and ([string]$Item["id"]).Trim()) {
        return ([string]$Item["id"]).Trim()
    }

    $title = if ($Item.Contains("title")) { [string]$Item["title"] } else { "" }
    $fileValue = ""
    foreach ($field in @("file", "file_path", "path", "source_file")) {
        if ($Item.Contains($field) -and ([string]$Item[$field]).Trim()) {
            $fileValue = [string]$Item[$field]
            break
        }
    }
    $action = ""
    foreach ($field in @("action", "kind", "change_type")) {
        if ($Item.Contains($field) -and ([string]$Item[$field]).Trim()) {
            $action = [string]$Item[$field]
            break
        }
    }

    $seed = ("{0}|{1}|{2}" -f $title, $fileValue, $action).ToLowerInvariant()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($seed)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha.ComputeHash($bytes)
    }
    finally {
        $sha.Dispose()
    }

    $hex = -join ($hash | ForEach-Object { $_.ToString("x2") })
    $generated = "auto-" + $hex.Substring(0, 24)
    $Item["id"] = $generated
    return $generated
}

function Dedupe-ById {
    param(
        [Parameter(Mandatory = $true)]$Items
    )

    $sorted = @($Items | Sort-Object { Normalize-CreatedAt $_["created_at"] })
    $seen = @{}
    $kept = New-Object System.Collections.Generic.List[object]
    $removed = 0

    foreach ($map in $sorted) {
        $id = Get-DeterministicId -Item $map
        if ($seen.ContainsKey($id)) {
            $removed++
            continue
        }
        $seen[$id] = $true
        $kept.Add($map)
    }

    return [pscustomobject]@{
        items = @($kept.ToArray())
        removed_count = $removed
    }
}

function Get-RiskCounts {
    param($Items)
    $counts = [ordered]@{
        "0" = 0
        "1" = 0
        "2" = 0
        "3" = 0
    }
    foreach ($item in @($Items)) {
        $risk = 1
        if ($item.Contains("risk_level")) {
            $risk = Convert-ToRiskInt $item["risk_level"]
        }
        $key = [string]$risk
        if (-not $counts.Contains($key)) {
            $counts[$key] = 0
        }
        $counts[$key] = [int]$counts[$key] + 1
    }
    return $counts
}

function Get-OldestAgeHours {
    param($Items)
    $arr = @($Items)
    if ($arr.Count -eq 0) { return $null }
    $oldest = ($arr | Sort-Object { Normalize-CreatedAt $_["created_at"] } | Select-Object -First 1)
    $dt = Normalize-CreatedAt $oldest["created_at"]
    return [math]::Round(((Get-Date).ToUniversalTime() - $dt).TotalHours, 2)
}

function Read-JsonArrayFile {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return @() }
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if (-not $raw.Trim()) { return @() }
    return To-Array ($raw | ConvertFrom-Json -ErrorAction Stop)
}

function Get-OptionalProperty {
    param(
        $Object,
        [string]$Name
    )

    if ($null -eq $Object) { return $null }
    if ($Object.PSObject.Properties.Name -contains $Name) {
        return $Object.$Name
    }
    return $null
}

$scriptRoot = $PSScriptRoot
if (-not $scriptRoot) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if (-not $RootPath) {
    $RootPath = Split-Path -Parent $scriptRoot
}
if (-not $PendingPath) {
    $PendingPath = Join-Path $RootPath "state\knowledge\pending_patch_runs.json"
}

$stateDir = Split-Path -Parent $PendingPath
$configDir = Join-Path $RootPath "config"
$reportsDir = Join-Path $RootPath "reports"
New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null

$riskPolicyPath = Join-Path $configDir "risk_policy.json"
$quarantinePath = Join-Path $stateDir "pending_patch_runs_quarantine.json"
$posturePath = Join-Path $reportsDir "approvals_posture.json"
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$archivePath = Join-Path $stateDir ("pending_patch_runs_archive_{0}.json" -f $stamp)

if (-not (Test-Path -LiteralPath $PendingPath)) {
    "[]" | Set-Content -LiteralPath $PendingPath -Encoding UTF8
}
if (-not (Test-Path -LiteralPath $quarantinePath)) {
    "[]" | Set-Content -LiteralPath $quarantinePath -Encoding UTF8
}

$allowedApproveRisk = 1
if (Test-Path -LiteralPath $riskPolicyPath) {
    try {
        $policy = Get-Content -LiteralPath $riskPolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        $rootAllowed = Get-OptionalProperty -Object $policy -Name "allowed_approve_risk"
        $globalAllowed = $null
        $policyGlobal = Get-OptionalProperty -Object $policy -Name "global"
        if ($policyGlobal) {
            $globalAllowed = Get-OptionalProperty -Object $policyGlobal -Name "allowed_approve_risk"
        }
        foreach ($candidate in @(
                $rootAllowed,
                $globalAllowed
            )) {
            if ($null -ne $candidate) {
                $parsed = 0
                if ([int]::TryParse([string]$candidate, [ref]$parsed)) {
                    $allowedApproveRisk = [Math]::Min(3, [Math]::Max(0, $parsed))
                    break
                }
            }
        }
    }
    catch {
        Write-FloodLog ("Could not parse risk policy, defaulting allowed_approve_risk to 1: {0}" -f $_.Exception.Message) "WARN"
    }
}

$pendingRaw = Get-Content -LiteralPath $PendingPath -Raw -Encoding UTF8
Set-Content -LiteralPath $archivePath -Value $pendingRaw -Encoding UTF8

$pendingInput = @()
if ($pendingRaw.Trim()) {
    $pendingInput = To-Array ($pendingRaw | ConvertFrom-Json -ErrorAction Stop)
}
$existingQuarantineInput = Read-JsonArrayFile -Path $quarantinePath

$preparedPending = New-Object System.Collections.Generic.List[object]
foreach ($entry in $pendingInput) {
    if ($null -eq $entry) { continue }
    $map = To-OrderedMap $entry
    $riskInput = $null
    if ($map.Contains("risk_level")) {
        $riskInput = $map["risk_level"]
    }
    elseif ($map.Contains("risk")) {
        $riskInput = $map["risk"]
    }
    $map["risk_level"] = [int](Convert-ToRiskInt $riskInput)
    $map["created_at"] = (Normalize-CreatedAt $map["created_at"]).ToString("o")
    if (-not $map.Contains("status") -or -not ([string]$map["status"]).Trim()) {
        $map["status"] = "pending"
    }
    if (-not $map.Contains("source") -or -not ([string]$map["source"]).Trim()) {
        $map["source"] = "manual"
    }
    $null = Get-DeterministicId -Item $map
    $preparedPending.Add($map)
}

$dedupePending = Dedupe-ById -Items @($preparedPending.ToArray())
$dedupedPending = @($dedupePending.items)
$dedupRemovedPending = [int]$dedupePending.removed_count

$eligible = New-Object System.Collections.Generic.List[object]
$newQuarantine = New-Object System.Collections.Generic.List[object]

foreach ($item in $dedupedPending) {
    $risk = Convert-ToRiskInt $item["risk_level"]
    $item["risk_level"] = [int]$risk
    if ($risk -le $allowedApproveRisk) {
        $eligible.Add($item)
    }
    else {
        if (-not $item.Contains("quarantine_reason")) {
            $item["quarantine_reason"] = "risk_gt_allowed"
        }
        $newQuarantine.Add($item)
    }
}

$eligibleOrdered = @($eligible.ToArray() | Sort-Object { Normalize-CreatedAt $_["created_at"] })
$throttleRemoved = 0
if ($eligibleOrdered.Count -gt $MaxEligible) {
    $overflow = @($eligibleOrdered | Select-Object -Skip $MaxEligible)
    $eligibleOrdered = @($eligibleOrdered | Select-Object -First $MaxEligible)
    $throttleRemoved = $overflow.Count

    foreach ($item in $overflow) {
        $item["quarantine_reason"] = "throttle_overflow"
        $newQuarantine.Add($item)
    }
}

$eligibleIdSet = @{}
foreach ($item in $eligibleOrdered) {
    $eligibleIdSet[[string]$item["id"]] = $true
}

$preparedExistingQuarantine = New-Object System.Collections.Generic.List[object]
foreach ($entry in $existingQuarantineInput) {
    if ($null -eq $entry) { continue }
    $map = To-OrderedMap $entry
    $riskInput = $null
    if ($map.Contains("risk_level")) {
        $riskInput = $map["risk_level"]
    }
    elseif ($map.Contains("risk")) {
        $riskInput = $map["risk"]
    }
    $map["risk_level"] = [int](Convert-ToRiskInt $riskInput)
    $map["created_at"] = (Normalize-CreatedAt $map["created_at"]).ToString("o")
    if (-not $map.Contains("status") -or -not ([string]$map["status"]).Trim()) {
        $map["status"] = "pending"
    }
    if (-not $map.Contains("source") -or -not ([string]$map["source"]).Trim()) {
        $map["source"] = "manual"
    }
    $id = Get-DeterministicId -Item $map
    if (-not $eligibleIdSet.ContainsKey($id)) {
        $preparedExistingQuarantine.Add($map)
    }
}

$mergedQuarantine = @($preparedExistingQuarantine.ToArray()) + @($newQuarantine.ToArray())
$dedupeQuarantine = Dedupe-ById -Items $mergedQuarantine
$finalQuarantine = @($dedupeQuarantine.items)
$dedupRemovedQuarantine = [int]$dedupeQuarantine.removed_count

$eligibleOrdered | ForEach-Object { [pscustomobject]$_ } | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $PendingPath -Encoding UTF8
$finalQuarantine | ForEach-Object { [pscustomobject]$_ } | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $quarantinePath -Encoding UTF8

$riskCountsEligible = Get-RiskCounts -Items $eligibleOrdered
$riskCountsQuarantine = Get-RiskCounts -Items $finalQuarantine
$oldestEligibleHours = Get-OldestAgeHours -Items $eligibleOrdered
$oldestQuarantineHours = Get-OldestAgeHours -Items $finalQuarantine
$allItemsForAge = @($eligibleOrdered) + @($finalQuarantine)
$oldestOverallHours = Get-OldestAgeHours -Items $allItemsForAge

$posture = [ordered]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    allowed_approve_risk = $allowedApproveRisk
    max_eligible = $MaxEligible
    paths = [ordered]@{
        pending = $PendingPath
        quarantine = $quarantinePath
        archive = $archivePath
    }
    counts = [ordered]@{
        eligible_total = $eligibleOrdered.Count
        quarantine_total = $finalQuarantine.Count
        eligible_by_risk = $riskCountsEligible
        quarantine_by_risk = $riskCountsQuarantine
    }
    age_hours = [ordered]@{
        oldest_eligible = $oldestEligibleHours
        oldest_quarantine = $oldestQuarantineHours
        oldest_overall = $oldestOverallHours
    }
    dedup_removals_count = ($dedupRemovedPending + $dedupRemovedQuarantine)
    dedup_breakdown = [ordered]@{
        pending_input = $dedupRemovedPending
        quarantine_merge = $dedupRemovedQuarantine
    }
    throttle_removals_count = $throttleRemoved
}

$posture | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $posturePath -Encoding UTF8

Write-FloodLog ("Eligible queue count: {0}" -f $eligibleOrdered.Count)
Write-FloodLog ("Quarantine queue count: {0}" -f $finalQuarantine.Count)
Write-FloodLog ("Archive written: {0}" -f $archivePath)
Write-FloodLog ("Posture report: {0}" -f $posturePath)
