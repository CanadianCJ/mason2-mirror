[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$InputPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-NormalizeLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [Mason_Risk_Normalize] [$Level] $Message"
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
    if ($null -eq $Value) {
        return $map
    }

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
        "readonly" { return 0 }
        "read_only" { return 0 }
        "low" { return 1 }
        "medium" { return 2 }
        "med" { return 2 }
        "high" { return 3 }
        "critical" { return 3 }
        default { return 1 }
    }
}

function Normalize-Status {
    param($StatusValue)

    $raw = [string]$StatusValue
    if (-not $raw.Trim()) { return "pending" }

    $text = $raw.Trim().ToLowerInvariant()
    switch ($text) {
        "approve" { return "approved" }
        "approved" { return "approved" }
        "reject" { return "rejected" }
        "rejected" { return "rejected" }
        "executed" { return "executed" }
        "pending" { return "pending" }
        "queued" { return "queued" }
        "failed" { return "failed" }
        "error" { return "error" }
        "skipped" { return "skipped" }
        "approved_dry_run" { return "approved_dry_run" }
        default { return $text }
    }
}

function Guess-Source {
    param($Item)

    $id = ""
    if ($Item.Contains("id") -and $Item.id) {
        $id = ([string]$Item.id).ToLowerInvariant()
    }

    foreach ($field in @("source", "component_id", "area", "domain", "teacher_domain", "teacher_area")) {
        if ($Item.Contains($field) -and $Item[$field]) {
            $value = ([string]$Item[$field]).ToLowerInvariant()
            if ($value -like "*teacher*") { return "teacher" }
            if ($value -like "*onyx*") { return "onyx" }
            if ($value -like "*manual*") { return "manual" }
        }
    }

    if ($id -like "teacher-*") { return "teacher" }
    if ($id -like "onyx*") { return "onyx" }

    return "manual"
}

function Normalize-CreatedAt {
    param($CreatedAtValue)

    if ($CreatedAtValue) {
        $dt = [datetime]::MinValue
        if ([datetime]::TryParse([string]$CreatedAtValue, [ref]$dt)) {
            return $dt.ToUniversalTime().ToString("o")
        }
    }
    return (Get-Date).ToUniversalTime().ToString("o")
}

$scriptRoot = $PSScriptRoot
if (-not $scriptRoot) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if (-not $RootPath) {
    $RootPath = Split-Path -Parent $scriptRoot
}
if (-not $InputPath) {
    $InputPath = Join-Path $RootPath "state\knowledge\pending_patch_runs.json"
}

$reportsDir = Join-Path $RootPath "reports"
New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
$reportPath = Join-Path $reportsDir "risk_normalize_report.json"

if (-not (Test-Path -LiteralPath $InputPath)) {
    "[]" | Set-Content -LiteralPath $InputPath -Encoding UTF8
}

$raw = Get-Content -LiteralPath $InputPath -Raw -Encoding UTF8
$items = @()
if ($raw.Trim()) {
    $items = To-Array ($raw | ConvertFrom-Json -ErrorAction Stop)
}

$normalized = New-Object System.Collections.Generic.List[object]
$changedRisk = 0
$defaultedRisk = 0
$defaultedStatus = 0
$defaultedSource = 0
$defaultedCreatedAt = 0

foreach ($item in $items) {
    if ($null -eq $item) { continue }

    $map = To-OrderedMap -Value $item

    $originalRisk = $null
    if ($map.Contains("risk_level")) {
        $originalRisk = $map["risk_level"]
    }
    elseif ($map.Contains("risk")) {
        $originalRisk = $map["risk"]
    }

    $riskInt = Convert-ToRiskInt -RiskValue $originalRisk
    if ($null -eq $originalRisk -or -not ([string]$originalRisk).Trim()) {
        $defaultedRisk++
    }
    elseif (([string]$originalRisk).Trim() -ne ([string]$riskInt)) {
        $changedRisk++
    }
    $map["risk_level"] = [int]$riskInt

    $hadStatus = ($map.Contains("status") -and ([string]$map["status"]).Trim())
    $map["status"] = Normalize-Status -StatusValue $map["status"]
    if (-not $hadStatus) {
        $defaultedStatus++
    }

    $hadSource = ($map.Contains("source") -and ([string]$map["source"]).Trim())
    if (-not $hadSource) {
        $defaultedSource++
    }
    $map["source"] = Guess-Source -Item $map

    $hadCreatedAt = ($map.Contains("created_at") -and ([string]$map["created_at"]).Trim())
    if (-not $hadCreatedAt) {
        $defaultedCreatedAt++
    }
    $map["created_at"] = Normalize-CreatedAt -CreatedAtValue $map["created_at"]

    $normalized.Add([pscustomobject]$map)
}

$normalized | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $InputPath -Encoding UTF8

$report = [ordered]@{
    generated_at_utc     = (Get-Date).ToUniversalTime().ToString("o")
    input_path           = $InputPath
    item_count           = $normalized.Count
    changed_risk_count   = $changedRisk
    defaulted_risk_count = $defaultedRisk
    defaulted_status_count = $defaultedStatus
    defaulted_source_count = $defaultedSource
    defaulted_created_at_count = $defaultedCreatedAt
}
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $reportPath -Encoding UTF8

Write-NormalizeLog ("Normalized {0} item(s)." -f $normalized.Count)
Write-NormalizeLog ("Input updated: {0}" -f $InputPath)
Write-NormalizeLog ("Report written: {0}" -f $reportPath)
