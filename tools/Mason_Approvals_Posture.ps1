[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$PendingPath = "",
    [string]$QuarantinePath = "",
    [string]$OutputPath = "",
    [int]$TopCategories = 10
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-PostureLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [Mason_Approvals_Posture] [$Level] $Message"
}

function To-Array {
    param($Value)
    if ($null -eq $Value) { return @() }
    if ($Value -is [System.Array]) { return $Value }
    return @($Value)
}

function Read-JsonArray {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return @()
    }
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if (-not $raw.Trim()) {
        return @()
    }
    return To-Array ($raw | ConvertFrom-Json -ErrorAction Stop)
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
        return [Math]::Min(3, [Math]::Max(0, [int]$m.Groups[1].Value))
    }

    switch ($text) {
        "observe_only" { return 0 }
        "observe-only" { return 0 }
        "low" { return 1 }
        "medium" { return 2 }
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
    return $null
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
        $risk = Convert-ToRiskInt $item.risk_level
        $key = [string]$risk
        if (-not $counts.Contains($key)) { $counts[$key] = 0 }
        $counts[$key] = [int]$counts[$key] + 1
    }
    return $counts
}

function Get-StatusCounts {
    param($Items)

    $counts = @{}
    foreach ($item in @($Items)) {
        $status = "pending"
        if ($item.PSObject.Properties.Name -contains "status" -and $item.status) {
            $status = ([string]$item.status).Trim().ToLowerInvariant()
        }
        if (-not $status) { $status = "pending" }
        if (-not $counts.ContainsKey($status)) {
            $counts[$status] = 0
        }
        $counts[$status] = [int]$counts[$status] + 1
    }
    return [ordered]@{} + $counts
}

function Get-OldestAgeHours {
    param($Items)

    $oldest = $null
    foreach ($item in @($Items)) {
        $dt = Normalize-CreatedAt $item.created_at
        if (-not $dt) { continue }
        if ($null -eq $oldest -or $dt -lt $oldest) {
            $oldest = $dt
        }
    }
    if ($null -eq $oldest) { return $null }
    return [math]::Round(((Get-Date).ToUniversalTime() - $oldest).TotalHours, 2)
}

function Get-TopCategoryCounts {
    param(
        $Items,
        [int]$Limit = 10
    )

    $bucket = @{}
    foreach ($item in @($Items)) {
        $parts = @()
        foreach ($field in @("component_id", "area", "domain", "source")) {
            if ($item.PSObject.Properties.Name -contains $field -and $item.$field) {
                $parts += ([string]$item.$field).Trim().ToLowerInvariant()
            }
        }
        $category = if ($parts.Count -gt 0) { ($parts -join "/") } else { "uncategorized" }
        if (-not $bucket.ContainsKey($category)) {
            $bucket[$category] = 0
        }
        $bucket[$category] = [int]$bucket[$category] + 1
    }

    $rows = @()
    foreach ($key in $bucket.Keys) {
        $rows += [pscustomobject]@{
            category = $key
            count    = [int]$bucket[$key]
        }
    }
    return @($rows | Sort-Object -Property @{Expression = "count"; Descending = $true}, @{Expression = "category"; Descending = $false} | Select-Object -First $Limit)
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
if (-not $QuarantinePath) {
    $QuarantinePath = Join-Path $RootPath "state\knowledge\pending_patch_runs_quarantine.json"
}
if (-not $OutputPath) {
    $OutputPath = Join-Path $RootPath "reports\approvals_posture.json"
}

$eligible = Read-JsonArray -Path $PendingPath
$quarantine = Read-JsonArray -Path $QuarantinePath

$report = [ordered]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    paths = [ordered]@{
        pending    = $PendingPath
        quarantine = $QuarantinePath
        output     = $OutputPath
    }
    counts = [ordered]@{
        eligible_total = @($eligible).Count
        quarantine_total = @($quarantine).Count
        eligible_by_risk = Get-RiskCounts -Items $eligible
        quarantine_by_risk = Get-RiskCounts -Items $quarantine
        eligible_by_status = Get-StatusCounts -Items $eligible
        quarantine_by_status = Get-StatusCounts -Items $quarantine
    }
    age_hours = [ordered]@{
        oldest_eligible = Get-OldestAgeHours -Items $eligible
        oldest_quarantine = Get-OldestAgeHours -Items $quarantine
        oldest_overall = Get-OldestAgeHours -Items (@($eligible) + @($quarantine))
    }
    top_categories = [ordered]@{
        eligible = Get-TopCategoryCounts -Items $eligible -Limit $TopCategories
        quarantine = Get-TopCategoryCounts -Items $quarantine -Limit $TopCategories
    }
}

$outDir = Split-Path -Parent $OutputPath
if ($outDir -and -not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}
$report | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $OutputPath -Encoding UTF8

Write-PostureLog ("Posture report written: {0}" -f $OutputPath)
