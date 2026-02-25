param(
    [string]$RootPath      = "C:\Users\Chris\Desktop\Mason2",
    [string]$PatchPlanPath = "",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

if (-not $PatchPlanPath) {
    $PatchPlanPath = Join-Path $RootPath "reports\mason_patch_plan.json"
}

$reportsDir = Join-Path $RootPath "reports"
if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}

$logFile    = Join-Path $reportsDir "mason_patch_apply_log.txt"
$backupDir  = Join-Path $reportsDir "patch_backups"

if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

function Write-PatchLog {
    param([string]$Message)
    $line = "$(Get-Date -Format o) `t $Message"
    Add-Content -LiteralPath $logFile -Value $line
    Write-Host $Message
}

if (-not (Test-Path $PatchPlanPath)) {
    Write-PatchLog "Patch plan file not found: $PatchPlanPath"
    exit 1
}

Write-PatchLog "=== Mason Apply PatchPlan START ==="
Write-PatchLog "RootPath      = $RootPath"
Write-PatchLog "PatchPlanPath = $PatchPlanPath"
Write-PatchLog "DryRun        = $DryRun"

$rawJson = Get-Content -LiteralPath $PatchPlanPath -Raw
try {
    $plan = $rawJson | ConvertFrom-Json
} catch {
    Write-PatchLog "ERROR: Failed to parse patch plan JSON: $($_.Exception.Message)"
    exit 1
}

if (-not $plan.patches -or $plan.patches.Count -eq 0) {
    Write-PatchLog "No patches found in patch plan."
    Write-Host "No patches to apply."
    Write-PatchLog "=== Mason Apply PatchPlan END (no patches) ==="
    exit 0
}

# Only allow low-risk, auto_apply patches to touch files
# For now, only text-like docs/config/report files
$allowedAutoExts = @(".txt", ".md", ".json", ".log", ".cfg")

function Get-Ext {
    param([string]$Path)
    return [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
}

function Ensure-ParentDir {
    param([string]$FullPath)
    $dir = Split-Path -Path $FullPath -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

function Apply-Patch {
    param(
        [pscustomobject]$Patch
    )

    if ($Patch.area -ne "mason") {
        Write-PatchLog "SKIP: Patch id=$($Patch.id) area=$($Patch.area) (only 'mason' allowed)."
        return
    }

    if ($Patch.risk_level -gt 0 -or -not $Patch.auto_apply) {
        Write-PatchLog "SKIP: Patch id=$($Patch.id) risk_level=$($Patch.risk_level) auto_apply=$($Patch.auto_apply) (manual review required)."
        return
    }

    $rel = $Patch.target_relative
    if (-not $rel) {
        Write-PatchLog "SKIP: Patch id=$($Patch.id) has no target_relative."
        return
    }

    $targetFull = Join-Path $RootPath $rel
    $ext = Get-Ext $targetFull
    if ($allowedAutoExts -notcontains $ext) {
        Write-PatchLog "SKIP: Patch id=$($Patch.id) target extension '$ext' not allowed for auto-apply."
        return
    }

    $mode = $Patch.mode
    $mode = if ($mode) { $mode } else { "replace_snippet" }

    if ($mode -ne "replace_snippet" -and $mode -ne "create_or_replace") {
        Write-PatchLog "SKIP: Patch id=$($Patch.id) unsupported mode '$mode'."
        return
    }

    $exists = Test-Path $targetFull -PathType Leaf
    $original = ""

    if ($mode -eq "replace_snippet") {
        if (-not $exists) {
            Write-PatchLog "SKIP: Patch id=$($Patch.id) mode=replace_snippet but target does not exist: $targetFull"
            return
        }
        $original = Get-Content -LiteralPath $targetFull -Raw

        $match = $Patch.match
        $replacement = $Patch.replacement

        if (-not $match) {
            Write-PatchLog "SKIP: Patch id=$($Patch.id) mode=replace_snippet but 'match' is empty."
            return
        }
        if (-not $original.Contains($match)) {
            Write-PatchLog "SKIP: Patch id=$($Patch.id) match text not found in $targetFull."
            return
        }

        $newContent = $original.Replace($match, $replacement)
    }
    elseif ($mode -eq "create_or_replace") {
        if ($exists) {
            $original = Get-Content -LiteralPath $targetFull -Raw
        } else {
            $original = ""
        }

        if (-not $Patch.new_content) {
            Write-PatchLog "SKIP: Patch id=$($Patch.id) mode=create_or_replace but 'new_content' is null or empty."
            return
        }

        $newContent = $Patch.new_content
    }

    if ($null -eq $newContent -or $newContent -eq $original) {
        Write-PatchLog "SKIP: Patch id=$($Patch.id) produced no effective change."
        return
    }

    if ($DryRun) {
        Write-PatchLog "DRYRUN: Patch id=$($Patch.id) WOULD update $targetFull"
        return
    }

    Ensure-ParentDir -FullPath $targetFull

    if ($exists) {
        $backupName = ("{0:yyyyMMdd_HHmmss_fff}__{1}" -f (Get-Date), [System.IO.Path]::GetFileName($targetFull))
        $backupPath = Join-Path $backupDir $backupName
        Copy-Item -LiteralPath $targetFull -Destination $backupPath -Force
        Write-PatchLog "Backup created: $backupPath (for $targetFull)"
    }

    Set-Content -LiteralPath $targetFull -Value $newContent -Encoding UTF8
    Write-PatchLog "APPLIED: Patch id=$($Patch.id) updated $targetFull (exists=$exists)."
}

foreach ($p in $plan.patches) {
    Apply-Patch -Patch $p
}

Write-PatchLog "=== Mason Apply PatchPlan END ==="
