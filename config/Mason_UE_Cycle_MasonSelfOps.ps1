$ErrorActionPreference = "Stop"

$Base          = "C:\Users\Chris\Desktop\Mason2"
$IntakeScript  = Join-Path $Base "tools\Mason_UE_Intake_Scan.ps1"
$ChangesLog    = Join-Path $Base "logs\mason_changes.log"
$IndexPath     = Join-Path $Base "state\knowledge\ue_knowledge_index.json"
$SelfOpsPlan   = Join-Path $Base "reports\mason_self_ops_health_plan.json"
$AutoPolicy    = Join-Path $Base "config\mason_autonomy_policy.json"
$UEConfig      = Join-Path $Base "config\universal_evolution.json"

New-Item -ItemType Directory -Force -Path (Split-Path $ChangesLog) | Out-Null

function Write-UELog {
    param([string]$Message)
    $ts   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$ts] [UE-MasonSelfOps] $Message"
    Add-Content -Path $ChangesLog -Value $line
    Write-Host $line
}

Write-UELog "Starting Mason self-ops UE cycle..."

# 1) UE intake – detect any new/changed knowledge/config/docs
Write-UELog "Running UE intake scan..."
& $IntakeScript

# 2) Load knowledge index
$index = $null
if (Test-Path $IndexPath) {
    try {
        $indexJson = Get-Content $IndexPath -Raw
        $index     = $indexJson | ConvertFrom-Json
        Write-UELog "Loaded knowledge index with $($index.files.Keys.Count) tracked file(s)."
    } catch {
        Write-UELog "WARNING: Failed to read knowledge index: $($_.Exception.Message)"
    }
} else {
    Write-UELog "WARNING: Knowledge index not found after intake."
}

# 3) Load UE config (universal_evolution)
$ue = $null
if (Test-Path $UEConfig) {
    try {
        $ueJson = Get-Content $UEConfig -Raw
        $ue     = $ueJson | ConvertFrom-Json
        Write-UELog "Loaded universal_evolution.json."
    } catch {
        Write-UELog "WARNING: Failed to parse universal_evolution.json: $($_.Exception.Message)"
    }
}

$masonProgram = $null
if ($ue -ne $null -and $ue.programs) {
    $masonProgram = $ue.programs | Where-Object { $_.id -eq "mason_self_ops" -and $_.enabled }
    if ($masonProgram) {
        Write-UELog "UE program 'mason_self_ops' is enabled (cadence=${($masonProgram.cadence_hours)}h)."
    } else {
        Write-UELog "UE program 'mason_self_ops' not enabled; cycle will do intake only."
    }
} else {
    Write-UELog "No UE programs found; cycle will do intake only."
}

# 4) Load self-ops plan (what Mason already knows he should improve)
$selfOps = $null
if (Test-Path $SelfOpsPlan) {
    try {
        $selfOpsJson = Get-Content $SelfOpsPlan -Raw
        $selfOps     = $selfOpsJson | ConvertFrom-Json
        Write-UELog "Loaded mason_self_ops_health_plan.json."
    } catch {
        Write-UELog "WARNING: Failed to parse self-ops plan: $($_.Exception.Message)"
    }
} else {
    Write-UELog "WARNING: Self-ops plan not found; you may need to run Mason_Learner.ps1 with the self-ops seed."
}

# 5) Load autonomy policy (what Mason is allowed to auto-change)
$autoPolicy = $null
if (Test-Path $AutoPolicy) {
    try {
        $autoPolicyJson = Get-Content $AutoPolicy -Raw
        $autoPolicy     = $autoPolicyJson | ConvertFrom-Json
        Write-UELog "Loaded autonomy policy."
    } catch {
        Write-UELog "WARNING: Failed to read autonomy policy: $($_.Exception.Message)"
    }
} else {
    Write-UELog "WARNING: Autonomy policy not found; using defaults in scripts."
}

# 6) Decide what to do this cycle (v1: awareness only)
if ($masonProgram -and $selfOps -ne $null) {
    Write-UELog "Self-ops plan is present; future versions of this script will turn recommendations into patch runs."
} else {
    Write-UELog "UE program or self-ops plan missing; no recommendations applied this cycle."
}

Write-UELog "UE cycle complete (intake + plan review)."
