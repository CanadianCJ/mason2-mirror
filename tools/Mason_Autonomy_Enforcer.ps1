param()

$ErrorActionPreference = "Stop"

$basePath     = "C:\Users\Chris\Desktop\Mason2"
$policyPath   = Join-Path $basePath "policies\Mason_AutonomyPolicy.json"
$queuePending = Join-Path $basePath "queue\pending"
$logsFolder   = Join-Path $basePath "logs"
$logPath      = Join-Path $logsFolder "mason_autonomy_enforcer.log"

if (-not (Test-Path $logsFolder)) {
    New-Item -ItemType Directory -Path $logsFolder -ErrorAction SilentlyContinue | Out-Null
}

function Write-Log {
    param(
        [string]$Message
    )
    $ts = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    Add-Content -Path $logPath -Value "[$ts] $Message"
}

function Set-TaskProperty {
    param(
        [Parameter(Mandatory = $true)] $Object,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)] $Value
    )

    $prop = $Object.PSObject.Properties[$Name]
    if ($prop) {
        $prop.Value = $Value
    } else {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
}

Write-Log "=== Mason_Autonomy_Enforcer started ==="

if (-not (Test-Path $policyPath)) {
    Write-Log "Autonomy policy not found at $policyPath. Exiting."
    exit 0
}

$policyJson = Get-Content -Path $policyPath -Raw
$policy     = $policyJson | ConvertFrom-Json

if (-not (Test-Path $queuePending)) {
    Write-Log "Queue pending folder not found at $queuePending. Nothing to do."
    Write-Log "=== Mason_Autonomy_Enforcer completed ==="
    exit 0
}

$taskFiles = Get-ChildItem -Path $queuePending -Filter "*.json" -File
if (-not $taskFiles) {
    Write-Log "No pending task json files in $queuePending."
    Write-Log "=== Mason_Autonomy_Enforcer completed ==="
    exit 0
}

$policyChanged = $false

function Get-DomainLevelInfo {
    param(
        [string]$Area,
        [string]$Domain
    )

    # Get area
    $areaProp = $policy.areas.PSObject.Properties[$Area]
    if (-not $areaProp) {
        Write-Log "Unknown area '$Area' in task; skipping."
        return $null
    }
    $areaConfig = $areaProp.Value

    # Ensure domains object exists
    if (-not $areaConfig.domains) {
        $areaConfig | Add-Member -NotePropertyName "domains" -NotePropertyValue ([PSCustomObject]@{}) -Force
    }

    # Does domain exist already?
    $domainProp = $areaConfig.domains.PSObject.Properties[$Domain]
    if ($domainProp) {
        $domainConfig = $domainProp.Value
    }
    else {
        # Create using new_domain_defaults
        $defaultsProp = $policy.PSObject.Properties["new_domain_defaults"]
        if (-not $defaultsProp) {
            Write-Log "No new_domain_defaults in policy; cannot create domain '$Domain' for area '$Area'."
            return $null
        }

        $defaults = $defaultsProp.Value

        $domainConfig = [PSCustomObject]@{
            level        = $defaults.level
            target_level = $defaults.target_level
            notes        = $defaults.notes
        }

        $areaConfig.domains | Add-Member -NotePropertyName $Domain -NotePropertyValue $domainConfig
        Write-Log "Created new domain '$Domain' under area '$Area' with level $($domainConfig.level)."
        $script:policyChanged = $true
    }

    return $domainConfig
}

foreach ($file in $taskFiles) {
    $fullPath = $file.FullName

    try {
        $taskJson = Get-Content -Path $fullPath -Raw
        if (-not $taskJson) {
            Write-Log "File $fullPath is empty; skipping."
            continue
        }

        $task = $taskJson | ConvertFrom-Json
    }
    catch {
        Write-Log "Failed to parse json file $fullPath : $_"
        continue
    }

    $area = $task.area
    $risk = $task.risk

    if (-not $area -or -not $risk) {
        Write-Log "Task file $fullPath missing area or risk; skipping."
        continue
    }

    # Domain: use task.domain if present, otherwise infer or default
    $domain = $task.domain
    if (-not $domain) {
        # Simple defaults for now; Mason can refine later
        if ($area -eq "pc" -and $task.id -like "pc-gentle-temp-clean*") {
            $domain = "hygiene"
        }
        elseif ($area -eq "mason" -and $task.id -like "m2-forensics-cleanup*") {
            $domain = "hygiene"
        }
        else {
            $domain = "stability"
        }

        Set-TaskProperty -Object $task -Name "domain" -Value $domain
        Write-Log "Inferred domain '$domain' for task $($file.Name) (area=$area, risk=$risk)."
    }

    $domainInfo = Get-DomainLevelInfo -Area $area -Domain $domain
    if (-not $domainInfo) {
        Write-Log "No domain info for area=$area, domain=$domain; leaving task manual."
        continue
    }

    $level = $domainInfo.level
    $levelKey = [string]$level

    $levelProp = $policy.levels.PSObject.Properties[$levelKey]
    if (-not $levelProp) {
        Write-Log "No level definition for level='$levelKey' in policy; leaving $($file.Name) manual."
        continue
    }

    $levelConfig  = $levelProp.Value
    $allowedRisks = $levelConfig.allowed_risks

    if (-not $allowedRisks -or -not ($allowedRisks -contains $risk)) {
        Write-Log "Risk '$risk' not allowed for area=$area, domain=$domain, level=$levelKey; leaving $($file.Name) manual."
        continue
    }

    # At this point, policy allows auto-apply for this (area, domain, risk)
    try {
        Set-TaskProperty -Object $task -Name "auto_apply" -Value $true

        # Decide mode based on risk
        $modeVal = ""
        if ($risk -eq "medium" -or $risk -eq "high_scoped") {
            $modeVal = "experiment"
        }
        elseif ($risk -eq "low") {
            $modeVal = "auto"
        }

        if ($modeVal) {
            Set-TaskProperty -Object $task -Name "mode" -Value $modeVal
        }

        # Write back to file
        $newJson = $task | ConvertTo-Json -Depth 10
        Set-Content -Path $fullPath -Value $newJson -Encoding UTF8

        Write-Log "Enabled auto_apply for $fullPath (area=$area, domain=$domain, risk=$risk, level=$levelKey, mode=$modeVal)"
    }
    catch {
        Write-Log "Failed to update task file $fullPath : $_"
        continue
    }
}

if ($policyChanged) {
    try {
        $updatedPolicyJson = $policy | ConvertTo-Json -Depth 10
        Set-Content -Path $policyPath -Value $updatedPolicyJson -Encoding UTF8
        Write-Log "Policy updated on disk with new domains."
    }
    catch {
        Write-Log "Failed to write updated policy back to $policyPath : $_"
    }
}

Write-Log "=== Mason_Autonomy_Enforcer completed ==="
