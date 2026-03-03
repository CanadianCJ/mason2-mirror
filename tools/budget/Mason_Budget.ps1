[CmdletBinding()]
param(
    [string]$RootPath = "",
    [ValidateSet("Summary", "RecordUsage", "ShouldAllow")]
    [string]$Operation = "Summary",
    [string]$RunId = "manual",
    [string]$Op = "ingest_chunk",
    [string]$Model = "",
    [int]$InputTokens = 0,
    [int]$OutputTokens = 0,
    [double]$EstimatedCostUsd = 0.0
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

$script:RepoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$script:BudgetPolicyPath = Join-Path $script:RepoRoot "config\budget_policy.json"
$script:CurrencyPolicyPath = Join-Path $script:RepoRoot "config\currency_policy.json"
$script:BudgetPolicyCache = $null
$script:CurrencyPolicyCache = $null

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

function Ensure-ParentDirectory {
    param([Parameter(Mandatory = $true)][string]$Path)
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object,
        [int]$Depth = 12
    )
    Ensure-ParentDirectory -Path $Path
    $json = $Object | ConvertTo-Json -Depth $Depth
    Set-Content -LiteralPath $Path -Value $json -Encoding UTF8
}

function Resolve-PolicyPath {
    param(
        [Parameter(Mandatory = $true)][string]$PathValue
    )

    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        return $PathValue
    }
    return Join-Path $script:RepoRoot $PathValue
}

function Get-NumberValue {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string[]]$Names,
        [double]$Default = 0.0,
        [switch]$AllowMissing
    )

    foreach ($name in $Names) {
        if (-not $name) { continue }
        if (-not ($Object.PSObject.Properties.Name -contains $name)) { continue }
        $raw = $Object.$name
        if ($null -eq $raw) { continue }
        try {
            return [double]$raw
        }
        catch {
            continue
        }
    }

    if ($AllowMissing) {
        return [double]::NaN
    }
    return [double]$Default
}

function Get-CurrencyPolicy {
    if ($script:CurrencyPolicyCache) {
        return $script:CurrencyPolicyCache
    }

    $loaded = Read-JsonSafe -Path $script:CurrencyPolicyPath -Default $null
    if (-not $loaded) {
        $loaded = [pscustomobject]@{
            base_currency  = "CAD"
            locale         = "en-CA"
            usd_to_cad_rate = 1.35
            rate_source    = "manual"
            updated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
        }
    }

    $baseCurrency = [string]$loaded.base_currency
    if (-not $baseCurrency.Trim()) { $baseCurrency = "CAD" }

    $locale = [string]$loaded.locale
    if (-not $locale.Trim()) { $locale = "en-CA" }

    $rate = 1.35
    try { $rate = [double]$loaded.usd_to_cad_rate } catch { $rate = 1.35 }
    if ($rate -le 0.0) { $rate = 1.35 }

    $rateSource = [string]$loaded.rate_source
    if (-not $rateSource.Trim()) { $rateSource = "manual" }

    $updatedAt = [string]$loaded.updated_at_utc
    if (-not $updatedAt.Trim()) { $updatedAt = (Get-Date).ToUniversalTime().ToString("o") }

    $loaded | Add-Member -NotePropertyName base_currency -NotePropertyValue $baseCurrency -Force
    $loaded | Add-Member -NotePropertyName locale -NotePropertyValue $locale -Force
    $loaded | Add-Member -NotePropertyName usd_to_cad_rate -NotePropertyValue ([Math]::Round($rate, 8)) -Force
    $loaded | Add-Member -NotePropertyName rate_source -NotePropertyValue $rateSource -Force
    $loaded | Add-Member -NotePropertyName updated_at_utc -NotePropertyValue $updatedAt -Force

    $script:CurrencyPolicyCache = $loaded
    return $loaded
}

function Get-BudgetPolicy {
    if ($script:BudgetPolicyCache) {
        return $script:BudgetPolicyCache
    }

    $currency = Get-CurrencyPolicy
    $loaded = Read-JsonSafe -Path $script:BudgetPolicyPath -Default $null
    if (-not $loaded) {
        $loaded = [pscustomobject]@{
            enabled                = $false
            weekly_budget_cad      = 0.0
            weekly_budget_currency = "CAD"
            cost_source_currency   = "USD"
            reset_timezone         = "America/Toronto"
            reset_weekday          = "MONDAY"
            reset_hour_local       = 0
            reset_minute_local     = 0
            ledger_path            = (Join-Path $script:RepoRoot "state\knowledge\budget_ledger.jsonl")
            budget_state_path      = (Join-Path $script:RepoRoot "state\knowledge\budget_state.json")
            spend_estimation       = [pscustomobject]@{
                enabled = $true
                model_costs_usd_per_1m_tokens = [pscustomobject]@{
                    PRIMARY   = [pscustomobject]@{ input = 0.0; output = 0.0 }
                    SECONDARY = [pscustomobject]@{ input = 0.0; output = 0.0 }
                    TERTIARY  = [pscustomobject]@{ input = 0.0; output = 0.0 }
                }
            }
        }
    }

    $weeklyCad = Get-NumberValue -Object $loaded -Names @("weekly_budget_cad", "weekly_limit_cad", "weekly_cad_limit") -AllowMissing
    if ([double]::IsNaN($weeklyCad)) {
        $legacyUsd = Get-NumberValue -Object $loaded -Names @("weekly_usd_limit", "weekly_budget_usd", "weekly_limit_usd") -AllowMissing
        if (-not [double]::IsNaN($legacyUsd)) {
            $weeklyCad = $legacyUsd * [double]$currency.usd_to_cad_rate
        }
    }
    if ([double]::IsNaN($weeklyCad)) {
        $weeklyCad = 0.0
    }
    if ($weeklyCad -lt 0.0) { $weeklyCad = 0.0 }

    $budgetCurrency = [string]$loaded.weekly_budget_currency
    if (-not $budgetCurrency.Trim()) { $budgetCurrency = [string]$currency.base_currency }

    $costCurrency = [string]$loaded.cost_source_currency
    if (-not $costCurrency.Trim()) { $costCurrency = "USD" }

    $loaded | Add-Member -NotePropertyName weekly_budget_cad -NotePropertyValue ([Math]::Round($weeklyCad, 6)) -Force
    $loaded | Add-Member -NotePropertyName weekly_budget_currency -NotePropertyValue $budgetCurrency -Force
    $loaded | Add-Member -NotePropertyName cost_source_currency -NotePropertyValue $costCurrency -Force
    $loaded | Add-Member -NotePropertyName ledger_path_resolved -NotePropertyValue (Resolve-PolicyPath -PathValue ([string]$loaded.ledger_path)) -Force
    $loaded | Add-Member -NotePropertyName budget_state_path_resolved -NotePropertyValue (Resolve-PolicyPath -PathValue ([string]$loaded.budget_state_path)) -Force

    $script:BudgetPolicyCache = $loaded
    return $loaded
}

function Get-TimeZoneForPolicy {
    param(
        [Parameter(Mandatory = $true)]$Policy
    )

    $tzId = [string]$Policy.reset_timezone
    if (-not $tzId.Trim()) {
        $tzId = "America/Toronto"
    }

    $candidates = @($tzId)
    if ($tzId -eq "America/Toronto") {
        $candidates += "Eastern Standard Time"
    }

    foreach ($candidate in $candidates) {
        try {
            return [System.TimeZoneInfo]::FindSystemTimeZoneById($candidate)
        }
        catch {
            continue
        }
    }

    throw "Unable to resolve timezone for budget policy. Tried: $($candidates -join ', ')"
}

function Get-WeekWindow {
    param(
        [Parameter(Mandatory = $true)]$Policy
    )

    $tz = Get-TimeZoneForPolicy -Policy $Policy
    $nowUtc = (Get-Date).ToUniversalTime()
    $nowLocal = [System.TimeZoneInfo]::ConvertTimeFromUtc($nowUtc, $tz)

    $weekdayRaw = [string]$Policy.reset_weekday
    if (-not $weekdayRaw.Trim()) {
        $weekdayRaw = "MONDAY"
    }
    $weekday = [System.DayOfWeek]::Monday
    try {
        $weekday = [System.DayOfWeek]([System.Enum]::Parse([System.DayOfWeek], $weekdayRaw, $true))
    }
    catch {
        $weekday = [System.DayOfWeek]::Monday
    }

    $hour = 0
    $minute = 0
    try { $hour = [int]$Policy.reset_hour_local } catch { $hour = 0 }
    try { $minute = [int]$Policy.reset_minute_local } catch { $minute = 0 }
    $hour = [Math]::Min(23, [Math]::Max(0, $hour))
    $minute = [Math]::Min(59, [Math]::Max(0, $minute))

    $daysBack = (([int]$nowLocal.DayOfWeek - [int]$weekday) + 7) % 7
    $candidateDate = $nowLocal.Date.AddDays(-1 * $daysBack)
    $startLocal = [datetime]::new(
        $candidateDate.Year,
        $candidateDate.Month,
        $candidateDate.Day,
        $hour,
        $minute,
        0,
        [System.DateTimeKind]::Unspecified
    )
    if ($nowLocal -lt $startLocal) {
        $startLocal = $startLocal.AddDays(-7)
    }

    $endLocal = $startLocal.AddDays(7)
    $startUtc = [System.TimeZoneInfo]::ConvertTimeToUtc($startLocal, $tz)
    $endUtc = [System.TimeZoneInfo]::ConvertTimeToUtc($endLocal, $tz)

    return [pscustomobject]@{
        timezone_id      = $tz.Id
        week_start_local = $startLocal.ToString("yyyy-MM-ddTHH:mm:ss")
        week_end_local   = $endLocal.ToString("yyyy-MM-ddTHH:mm:ss")
        week_start_utc   = $startUtc.ToString("o")
        week_end_utc     = $endUtc.ToString("o")
        reset_at_utc     = $endUtc.ToString("o")
    }
}

function Get-LedgerEvents {
    param(
        [Parameter(Mandatory = $true)]$Policy
    )

    $ledgerPath = [string]$Policy.ledger_path_resolved
    if (-not (Test-Path -LiteralPath $ledgerPath)) {
        return @()
    }

    $events = New-Object System.Collections.Generic.List[object]
    foreach ($line in Get-Content -LiteralPath $ledgerPath -Encoding UTF8) {
        $trimmed = [string]$line
        if (-not $trimmed.Trim()) { continue }
        try {
            $parsed = $trimmed | ConvertFrom-Json -ErrorAction Stop
            $events.Add($parsed) | Out-Null
        }
        catch {
            continue
        }
    }

    return @($events.ToArray())
}

function Get-WeeklySpend {
    [CmdletBinding()]
    param()

    $policy = Get-BudgetPolicy
    $currency = Get-CurrencyPolicy
    $window = Get-WeekWindow -Policy $policy
    $weekStartUtc = [datetime]::Parse($window.week_start_utc).ToUniversalTime()
    $weekEndUtc = [datetime]::Parse($window.week_end_utc).ToUniversalTime()
    $fxRate = [double]$currency.usd_to_cad_rate
    if ($fxRate -le 0.0) { $fxRate = 1.35 }

    $sumCad = 0.0
    $sumUsd = 0.0
    $count = 0

    foreach ($event in Get-LedgerEvents -Policy $policy) {
        if (-not $event) { continue }
        $tsRaw = ""
        if ($event.PSObject.Properties.Name -contains "ts") {
            $tsRaw = [string]$event.ts
        }
        if (-not $tsRaw.Trim()) { continue }

        $ts = [datetime]::MinValue
        if (-not [datetime]::TryParse($tsRaw, [ref]$ts)) { continue }
        $tsUtc = $ts.ToUniversalTime()
        if ($tsUtc -lt $weekStartUtc -or $tsUtc -ge $weekEndUtc) { continue }

        $eventFx = Get-NumberValue -Object $event -Names @("fx_rate_usd_to_cad") -Default $fxRate
        if ($eventFx -le 0.0) { $eventFx = $fxRate }

        $usageUsd = Get-NumberValue -Object $event -Names @("usage_usd", "est_cost_usd", "cost_usd") -AllowMissing
        $usageCad = Get-NumberValue -Object $event -Names @("usage_cad", "est_cost_cad", "cost_cad") -AllowMissing

        if ([double]::IsNaN($usageUsd) -and -not [double]::IsNaN($usageCad)) {
            $usageUsd = if ($eventFx -gt 0.0) { [double]$usageCad / $eventFx } else { 0.0 }
        }
        if ([double]::IsNaN($usageCad) -and -not [double]::IsNaN($usageUsd)) {
            $usageCad = [double]$usageUsd * $eventFx
        }

        if ([double]::IsNaN($usageUsd)) { $usageUsd = 0.0 }
        if ([double]::IsNaN($usageCad)) { $usageCad = 0.0 }
        if ($usageUsd -lt 0.0) { $usageUsd = 0.0 }
        if ($usageCad -lt 0.0) { $usageCad = 0.0 }

        $sumUsd += $usageUsd
        $sumCad += $usageCad
        $count++
    }

    return [pscustomobject]@{
        weekly_spend_cad = [Math]::Round($sumCad, 6)
        spent_cad        = [Math]::Round($sumCad, 6)
        weekly_spend_usd = [Math]::Round($sumUsd, 6)
        spent_usd        = [Math]::Round($sumUsd, 6)
        event_count      = [int]$count
        fx_rate_usd_to_cad = [Math]::Round($fxRate, 8)
        budget_currency  = [string]$policy.weekly_budget_currency
        cost_source_currency = [string]$policy.cost_source_currency
        locale           = [string]$currency.locale
        window           = $window
    }
}

function Get-WeeklyRemaining {
    [CmdletBinding()]
    param()

    $policy = Get-BudgetPolicy
    $limitCad = 0.0
    try { $limitCad = [double]$policy.weekly_budget_cad } catch { $limitCad = 0.0 }
    if ($limitCad -lt 0.0) { $limitCad = 0.0 }

    $spend = Get-WeeklySpend
    $remainingCad = [Math]::Max(0.0, $limitCad - [double]$spend.weekly_spend_cad)
    return [Math]::Round($remainingCad, 6)
}

function Write-BudgetState {
    param(
        [Parameter(Mandatory = $true)]$Policy,
        [Parameter(Mandatory = $true)]$Spend,
        [Parameter(Mandatory = $true)]$Currency
    )

    $limitCad = 0.0
    try { $limitCad = [double]$Policy.weekly_budget_cad } catch { $limitCad = 0.0 }
    if ($limitCad -lt 0.0) { $limitCad = 0.0 }

    $spentCad = [Math]::Max(0.0, [double]$Spend.weekly_spend_cad)
    $spentUsd = [Math]::Max(0.0, [double]$Spend.weekly_spend_usd)

    $fxRate = [double]$Currency.usd_to_cad_rate
    if ($fxRate -le 0.0) { $fxRate = 1.35 }

    $remainingCad = [Math]::Max(0.0, $limitCad - $spentCad)
    $budgetUsd = if ($fxRate -gt 0.0) { [Math]::Round($limitCad / $fxRate, 6) } else { 0.0 }
    $remainingUsd = if ($fxRate -gt 0.0) { [Math]::Round($remainingCad / $fxRate, 6) } else { 0.0 }

    $state = [ordered]@{
        enabled                = [bool]$Policy.enabled
        currency               = [string]$Currency.base_currency
        locale                 = [string]$Currency.locale
        fx_rate_usd_to_cad     = [Math]::Round($fxRate, 8)
        rate_source            = [string]$Currency.rate_source
        weekly_budget_currency = [string]$Policy.weekly_budget_currency
        cost_source_currency   = [string]$Policy.cost_source_currency

        weekly_budget_cad      = [Math]::Round($limitCad, 6)
        budget_cad             = [Math]::Round($limitCad, 6)
        weekly_limit_cad       = [Math]::Round($limitCad, 6)
        weekly_spend_cad       = [Math]::Round($spentCad, 6)
        spent_cad              = [Math]::Round($spentCad, 6)
        weekly_remaining_cad   = [Math]::Round($remainingCad, 6)
        remaining_cad          = [Math]::Round($remainingCad, 6)

        weekly_limit_usd       = [Math]::Round($budgetUsd, 6)
        budget_usd             = [Math]::Round($budgetUsd, 6)
        weekly_spend_usd       = [Math]::Round($spentUsd, 6)
        spent_usd              = [Math]::Round($spentUsd, 6)
        weekly_remaining_usd   = [Math]::Round($remainingUsd, 6)
        remaining_usd          = [Math]::Round($remainingUsd, 6)

        week_start_local       = $Spend.window.week_start_local
        week_end_local         = $Spend.window.week_end_local
        week_start_utc         = $Spend.window.week_start_utc
        week_end_utc           = $Spend.window.week_end_utc
        reset_at_utc           = $Spend.window.reset_at_utc
        timezone_id            = $Spend.window.timezone_id
        ledger_path            = [string]$Policy.ledger_path_resolved
        last_update_utc        = (Get-Date).ToUniversalTime().ToString("o")
    }

    Write-JsonFile -Path ([string]$Policy.budget_state_path_resolved) -Object $state -Depth 14
    return [pscustomobject]$state
}

function Update-BudgetState {
    [CmdletBinding()]
    param()

    $policy = Get-BudgetPolicy
    $currency = Get-CurrencyPolicy
    $spend = Get-WeeklySpend
    return Write-BudgetState -Policy $policy -Spend $spend -Currency $currency
}

function RecordUsage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$run_id,
        [Parameter(Mandatory = $true)][string]$op,
        [Parameter(Mandatory = $true)][string]$model,
        [int]$input_tokens = 0,
        [int]$output_tokens = 0,
        [double]$est_cost_usd = 0.0
    )

    $policy = Get-BudgetPolicy
    $currency = Get-CurrencyPolicy
    $fxRate = [double]$currency.usd_to_cad_rate
    if ($fxRate -le 0.0) { $fxRate = 1.35 }

    $usageUsd = [Math]::Max(0.0, [double]$est_cost_usd)
    $usageCad = [Math]::Max(0.0, [double]$usageUsd * $fxRate)

    $line = [ordered]@{
        ts                  = (Get-Date).ToUniversalTime().ToString("o")
        run_id              = $run_id
        op                  = $op
        model               = $model
        input_tokens        = [Math]::Max(0, [int]$input_tokens)
        output_tokens       = [Math]::Max(0, [int]$output_tokens)
        usage_usd           = [Math]::Round($usageUsd, 8)
        usage_cad           = [Math]::Round($usageCad, 8)
        fx_rate_usd_to_cad  = [Math]::Round($fxRate, 8)
        rate_source         = [string]$currency.rate_source
        cost_source_currency = [string]$policy.cost_source_currency
        budget_currency     = [string]$policy.weekly_budget_currency

        est_cost_usd        = [Math]::Round($usageUsd, 8)
        est_cost_cad        = [Math]::Round($usageCad, 8)
    }

    Ensure-ParentDirectory -Path ([string]$policy.ledger_path_resolved)
    Add-Content -LiteralPath ([string]$policy.ledger_path_resolved) -Value (($line | ConvertTo-Json -Compress -Depth 10)) -Encoding UTF8

    return Update-BudgetState
}

function ShouldAllowPaidCall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$op,
        [double]$est_cost_usd = 0.0
    )

    $policy = Get-BudgetPolicy
    if (-not [bool]$policy.enabled) {
        return $true
    }

    $state = Update-BudgetState
    $remainingCad = 0.0
    try { $remainingCad = [double]$state.weekly_remaining_cad } catch { $remainingCad = 0.0 }

    $fxRate = Get-NumberValue -Object $state -Names @("fx_rate_usd_to_cad") -Default 1.35
    if ($fxRate -le 0.0) { $fxRate = 1.35 }

    $costUsd = [Math]::Max(0.0, [double]$est_cost_usd)
    $costCad = [double]$costUsd * $fxRate

    if ($remainingCad -le 0.0) {
        return $false
    }
    if ($costCad -gt 0.0 -and $remainingCad -lt $costCad) {
        return $false
    }
    return $true
}

if ($MyInvocation.InvocationName -ne ".") {
    switch ($Operation) {
        "Summary" {
            $summary = Update-BudgetState
            $summary | ConvertTo-Json -Depth 14
        }
        "RecordUsage" {
            $summary = RecordUsage -run_id $RunId -op $Op -model $Model -input_tokens $InputTokens -output_tokens $OutputTokens -est_cost_usd $EstimatedCostUsd
            $summary | ConvertTo-Json -Depth 14
        }
        "ShouldAllow" {
            $allow = ShouldAllowPaidCall -op $Op -est_cost_usd $EstimatedCostUsd
            [pscustomobject]@{
                allowed = [bool]$allow
                state   = Update-BudgetState
            } | ConvertTo-Json -Depth 14
        }
    }
}
