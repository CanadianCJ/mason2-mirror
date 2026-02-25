[CmdletBinding()]
param(
    [string]$RootDir = $null,
    [string]$OutputPath = $null,
    [int]$MaxItems = 25
)

$ErrorActionPreference = "Stop"

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Read-JsonFile {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return @()
    }

    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if (-not $raw -or -not $raw.Trim()) {
        return @()
    }

    try {
        return ($raw | ConvertFrom-Json -ErrorAction Stop)
    }
    catch {
        return @()
    }
}

function Ensure-Array {
    param($Value)

    if ($null -eq $Value) { return @() }
    if ($Value -is [string]) { return @($Value) }
    if ($Value -is [System.Collections.IEnumerable]) { return @($Value) }
    return @($Value)
}

function Normalize-Component {
    param([string]$Value)

    $raw = [string]$Value
    if (-not $raw.Trim()) { return "unknown" }
    $norm = $raw.Trim().ToLowerInvariant()

    if ($norm -like "*mason*") { return "mason" }
    if ($norm -like "*athena*") { return "athena" }
    if ($norm -like "*onyx*") { return "onyx" }
    return $norm
}

function Resolve-Component {
    param($Item)

    foreach ($field in @("component_id", "area", "teacher_domain", "domain")) {
        if ($Item -and ($Item.PSObject.Properties.Name -contains $field)) {
            $resolved = Normalize-Component -Value ([string]$Item.$field)
            if ($resolved -and $resolved -ne "unknown") {
                return $resolved
            }
        }
    }

    return "unknown"
}

function Normalize-RiskLabel {
    param($Value)

    $raw = [string]$Value
    if (-not $raw.Trim()) { return "R0" }

    if ($raw -match '^\s*[Rr]?(\d)\s*$') {
        return ("R{0}" -f [int]$Matches[1])
    }

    switch ($raw.Trim().ToLowerInvariant()) {
        "observe_only" { return "R0" }
        "low" { return "R1" }
        "medium" { return "R2" }
        "high" { return "R3" }
        default { return "R0" }
    }
}

function Resolve-WhyThisHelps {
    param($Item)

    $description = ""
    if ($Item -and ($Item.PSObject.Properties.Name -contains "description")) {
        $description = [string]$Item.description
    }

    if ($description -match '(?is)why this helps:\s*(.+)$') {
        return ($Matches[1].Trim())
    }

    if ($description.Trim()) {
        return $description.Trim()
    }

    return "Improves reliability and operator safety."
}

function Resolve-OperatorSummary {
    param($Item)

    if ($Item -and ($Item.PSObject.Properties.Name -contains "operator_summary")) {
        $summary = [string]$Item.operator_summary
        if ($summary.Trim()) {
            return $summary.Trim()
        }
    }

    return Resolve-WhyThisHelps -Item $Item
}

function Get-DateSortKey {
    param($Item)

    foreach ($field in @("decision_at", "created_at")) {
        if ($Item -and ($Item.PSObject.Properties.Name -contains $field)) {
            $value = [string]$Item.$field
            $dt = [DateTime]::MinValue
            if ([DateTime]::TryParse($value, [ref]$dt)) {
                return $dt.ToUniversalTime()
            }
        }
    }

    return [DateTime]::MinValue
}

if (-not $RootDir) {
    if ($PSCommandPath) {
        $RootDir = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    }
    else {
        $RootDir = "C:\Users\Chris\Desktop\Mason2"
    }
}

$approvalsPath = Join-Path $RootDir "state\knowledge\pending_patch_runs.json"
if (-not $OutputPath) {
    $OutputPath = Join-Path $RootDir "reports\codex_workorder_latest.txt"
}

if ($MaxItems -lt 1) { $MaxItems = 1 }
if ($MaxItems -gt 200) { $MaxItems = 200 }

$rawApprovals = Ensure-Array (Read-JsonFile -Path $approvalsPath)

$selected = @()
foreach ($item in $rawApprovals) {
    if (-not $item) { continue }

    $status = [string]$item.status
    if (-not $status.Trim()) { continue }
    $statusNorm = $status.Trim().ToLowerInvariant()
    if ($statusNorm -ne "approve" -and $statusNorm -ne "approved") {
        continue
    }

    $riskLabel = Normalize-RiskLabel -Value $item.risk_level
    if ($riskLabel -ne "R1") {
        continue
    }

    $selected += ,$item
}

$selected = @(
    $selected |
    Sort-Object { Get-DateSortKey -Item $_ } -Descending |
    Select-Object -First $MaxItems
)

$lines = New-Object System.Collections.Generic.List[string]
$generatedAt = (Get-Date).ToUniversalTime().ToString("o")
$lines.Add("Codex Work Order - R1 Approved Changes")
$lines.Add(("Generated (UTC): {0}" -f $generatedAt))
$lines.Add(("Source approvals: {0}" -f $approvalsPath))
$lines.Add("")
$lines.Add("GOAL")
$lines.Add("Apply the approved R1 changes below with deterministic tests and no out-of-scope edits.")
$lines.Add("")
$lines.Add("SCOPE (STRICT)")
$lines.Add("Edit only files required by the listed approvals.")
$lines.Add("No other files.")
$lines.Add("")
$lines.Add("Run in Codex")
$lines.Add(("Run from: {0}" -f $RootDir))
$lines.Add("Use this work order and execute each item with tests.")
$lines.Add("")

if ($selected.Count -eq 0) {
    $lines.Add("No approved R1 items are currently available.")
}
else {
    $i = 1
    foreach ($item in $selected) {
        $id = [string]$item.id
        $title = [string]$item.title
        $risk = Normalize-RiskLabel -Value $item.risk_level
        $component = Resolve-Component -Item $item
        $why = Resolve-WhyThisHelps -Item $item
        $summary = Resolve-OperatorSummary -Item $item

        if (-not $id.Trim()) { $id = ("r1-item-{0}" -f $i) }
        if (-not $title.Trim()) { $title = "(untitled approval item)" }

        $lines.Add(("{0}. [{1}] {2} ({3}, {4})" -f $i, $id, $title, $component, $risk))
        $lines.Add(("   Operator summary: {0}" -f $summary))
        $lines.Add(("   Why this helps: {0}" -f $why))

        $actions = @()
        if ($item.PSObject.Properties.Name -contains "actions") {
            if ($item.actions -is [string]) {
                if ([string]$item.actions -and ([string]$item.actions).Trim()) {
                    $actions = @(([string]$item.actions).Trim())
                }
            }
            elseif ($item.actions -is [System.Collections.IEnumerable]) {
                foreach ($action in $item.actions) {
                    $a = [string]$action
                    if ($a.Trim()) {
                        $actions += ,$a.Trim()
                    }
                }
            }
        }

        if ($actions.Count -gt 0) {
            $lines.Add("   Proposed actions:")
            foreach ($action in $actions) {
                $lines.Add(("   - {0}" -f $action))
            }
        }
        else {
            $lines.Add("   Proposed actions: (none provided)")
        }

        $lines.Add("")
        $i++
    }
}

$outDir = Split-Path -Parent $OutputPath
if ($outDir) { Ensure-Directory -Path $outDir }
Set-Content -LiteralPath $OutputPath -Value ($lines -join [Environment]::NewLine) -Encoding UTF8

$result = [ordered]@{
    ok = $true
    count = $selected.Count
    output_path = $OutputPath
    generated_at = $generatedAt
}

Write-Output ($result | ConvertTo-Json -Depth 10 -Compress)
