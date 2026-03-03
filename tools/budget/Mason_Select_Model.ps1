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

$script:RepoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$script:ModelPolicyPath = Join-Path $script:RepoRoot "config\model_policy.json"
$script:ModelPolicyCache = $null

$budgetScript = Join-Path $PSScriptRoot "Mason_Budget.ps1"
if (-not (Test-Path -LiteralPath $budgetScript)) {
    throw "Missing dependency: $budgetScript"
}
. $budgetScript -RootPath $script:RepoRoot

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

function Get-ModelPolicy {
    if ($script:ModelPolicyCache) {
        return $script:ModelPolicyCache
    }

    $loaded = Read-JsonSafe -Path $script:ModelPolicyPath -Default $null
    if (-not $loaded) {
        $loaded = [pscustomobject]@{
            enabled = $true
            tier_ladder = @(
                [pscustomobject]@{ tier = "PRIMARY"; model_env = "MASON_MODEL_PRIMARY"; default = "gpt-5.1" },
                [pscustomobject]@{ tier = "SECONDARY"; model_env = "MASON_MODEL_SECONDARY"; default = "gpt-5.1" },
                [pscustomobject]@{ tier = "TERTIARY"; model_env = "MASON_MODEL_TERTIARY"; default = "gpt-5.1" }
            )
            degrade_thresholds = [pscustomobject]@{
                weekly_remaining_cad_to_use_secondary  = 10.0
                weekly_remaining_cad_to_use_tertiary   = 3.0
                weekly_remaining_cad_to_stop_paid_calls = 0.0
                weekly_remaining_usd_to_use_secondary  = 10.0
                weekly_remaining_usd_to_use_tertiary   = 3.0
                weekly_remaining_usd_to_stop_paid_calls = 0.0
            }
            when_budget_exhausted = "storage_only"
        }
    }

    $script:ModelPolicyCache = $loaded
    return $loaded
}

function Resolve-ModelForTier {
    param(
        [Parameter(Mandatory = $true)]$ModelPolicy,
        [Parameter(Mandatory = $true)][string]$Tier
    )

    $tierItem = $null
    foreach ($candidate in @($ModelPolicy.tier_ladder)) {
        if (-not $candidate) { continue }
        if ([string]$candidate.tier -eq $Tier) {
            $tierItem = $candidate
            break
        }
    }

    if (-not $tierItem) {
        return [pscustomobject]@{
            tier      = $Tier
            model_env = "MASON_MODEL"
            model     = if ($env:MASON_MODEL) { [string]$env:MASON_MODEL } else { "gpt-5.1" }
        }
    }

    $envVar = [string]$tierItem.model_env
    if (-not $envVar.Trim()) { $envVar = "MASON_MODEL" }

    $model = ""
    if (Test-Path ("Env:{0}" -f $envVar)) {
        $model = [string](Get-Item ("Env:{0}" -f $envVar)).Value
    }
    if (-not $model.Trim() -and $env:MASON_MODEL) {
        $model = [string]$env:MASON_MODEL
    }
    if (-not $model.Trim()) {
        $model = if ($tierItem.default) { [string]$tierItem.default } else { "gpt-5.1" }
    }

    return [pscustomobject]@{
        tier      = $Tier
        model_env = $envVar
        model     = $model
    }
}

function Get-ModelSelection {
    [CmdletBinding()]
    param()

    $modelPolicy = Get-ModelPolicy
    $budgetState = Update-BudgetState
    $remainingCad = 0.0
    try { $remainingCad = [double]$budgetState.weekly_remaining_cad } catch { $remainingCad = 0.0 }
    if ($remainingCad -le 0.0) {
        $legacyUsd = 0.0
        $fxRate = 1.35
        try { $legacyUsd = [double]$budgetState.weekly_remaining_usd } catch { $legacyUsd = 0.0 }
        try { $fxRate = [double]$budgetState.fx_rate_usd_to_cad } catch { $fxRate = 1.35 }
        if ($fxRate -le 0.0) { $fxRate = 1.35 }
        if ($legacyUsd -gt 0.0) {
            $remainingCad = $legacyUsd * $fxRate
        }
    }
    if ($remainingCad -lt 0.0) { $remainingCad = 0.0 }

    $remainingUsd = 0.0
    try { $remainingUsd = [double]$budgetState.weekly_remaining_usd } catch { $remainingUsd = 0.0 }
    if ($remainingUsd -le 0.0) {
        $fxRateForUsd = 1.35
        try { $fxRateForUsd = [double]$budgetState.fx_rate_usd_to_cad } catch { $fxRateForUsd = 1.35 }
        if ($fxRateForUsd -le 0.0) { $fxRateForUsd = 1.35 }
        $remainingUsd = $remainingCad / $fxRateForUsd
    }

    $thresholdSecondary = 10.0
    $thresholdTertiary = 3.0
    $thresholdStopPaid = 0.0
    if ($modelPolicy.degrade_thresholds) {
        try { $thresholdSecondary = [double]$modelPolicy.degrade_thresholds.weekly_remaining_cad_to_use_secondary } catch { }
        try { $thresholdTertiary = [double]$modelPolicy.degrade_thresholds.weekly_remaining_cad_to_use_tertiary } catch { }
        try { $thresholdStopPaid = [double]$modelPolicy.degrade_thresholds.weekly_remaining_cad_to_stop_paid_calls } catch { }
        if ($thresholdSecondary -eq 10.0 -and ($modelPolicy.degrade_thresholds.PSObject.Properties.Name -contains "weekly_remaining_usd_to_use_secondary")) {
            try {
                $legacySecondaryUsd = [double]$modelPolicy.degrade_thresholds.weekly_remaining_usd_to_use_secondary
                $fxLegacy = 1.35
                try { $fxLegacy = [double]$budgetState.fx_rate_usd_to_cad } catch { $fxLegacy = 1.35 }
                if ($fxLegacy -le 0.0) { $fxLegacy = 1.35 }
                $thresholdSecondary = $legacySecondaryUsd * $fxLegacy
            } catch { }
        }
        if ($thresholdTertiary -eq 3.0 -and ($modelPolicy.degrade_thresholds.PSObject.Properties.Name -contains "weekly_remaining_usd_to_use_tertiary")) {
            try {
                $legacyTertiaryUsd = [double]$modelPolicy.degrade_thresholds.weekly_remaining_usd_to_use_tertiary
                $fxLegacy = 1.35
                try { $fxLegacy = [double]$budgetState.fx_rate_usd_to_cad } catch { $fxLegacy = 1.35 }
                if ($fxLegacy -le 0.0) { $fxLegacy = 1.35 }
                $thresholdTertiary = $legacyTertiaryUsd * $fxLegacy
            } catch { }
        }
        if ($thresholdStopPaid -eq 0.0 -and ($modelPolicy.degrade_thresholds.PSObject.Properties.Name -contains "weekly_remaining_usd_to_stop_paid_calls")) {
            try {
                $legacyStopUsd = [double]$modelPolicy.degrade_thresholds.weekly_remaining_usd_to_stop_paid_calls
                $fxLegacy = 1.35
                try { $fxLegacy = [double]$budgetState.fx_rate_usd_to_cad } catch { $fxLegacy = 1.35 }
                if ($fxLegacy -le 0.0) { $fxLegacy = 1.35 }
                $thresholdStopPaid = $legacyStopUsd * $fxLegacy
            } catch { }
        }
    }

    $selectedTier = "PRIMARY"
    $mode = "llm"
    $reason = "within_primary_budget"

    if ([bool]$modelPolicy.enabled -and [bool]$budgetState.enabled) {
        if ($remainingCad -le $thresholdStopPaid) {
            $mode = [string]$modelPolicy.when_budget_exhausted
            if (-not $mode.Trim()) { $mode = "storage_only" }
            $selectedTier = "TERTIARY"
            $reason = "budget_exhausted"
        }
        elseif ($remainingCad -le $thresholdTertiary) {
            $selectedTier = "TERTIARY"
            $reason = "budget_low_use_tertiary"
        }
        elseif ($remainingCad -le $thresholdSecondary) {
            $selectedTier = "SECONDARY"
            $reason = "budget_warning_use_secondary"
        }
    }

    $resolved = Resolve-ModelForTier -ModelPolicy $modelPolicy -Tier $selectedTier
    return [pscustomobject]@{
        mode          = $mode
        tier          = $resolved.tier
        model         = $resolved.model
        model_env     = $resolved.model_env
        reason        = $reason
        remaining_cad = [Math]::Round($remainingCad, 6)
        remaining_usd = [Math]::Round($remainingUsd, 6)
        currency      = "CAD"
        budget_state  = $budgetState
    }
}

if ($MyInvocation.InvocationName -ne ".") {
    Get-ModelSelection | ConvertTo-Json -Depth 12
}
