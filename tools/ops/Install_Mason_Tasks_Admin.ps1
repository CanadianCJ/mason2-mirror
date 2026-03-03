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

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object,
        [int]$Depth = 12
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $Object | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Test-IsAdministrator {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function Test-TaskExists {
    param([string]$TaskPathAndName)
    $null = schtasks /Query /TN $TaskPathAndName 2>$null
    return ($LASTEXITCODE -eq 0)
}

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
$reportPath = Join-Path $reportsDir "tasks_install_report.json"
$ingestInstaller = Join-Path $repoRoot "tools\ingest\Install_Mason_Ingest_Autopilot_Task.ps1"
$mirrorInstaller = Join-Path $repoRoot "tools\sync\Install_Mason_Mirror_Update_Task.ps1"

$result = [ordered]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    repo_root        = $repoRoot
    is_elevated      = Test-IsAdministrator
    steps            = [ordered]@{
        install_ingest_task = [ordered]@{ ok = $false; error = $null }
        install_mirror_task = [ordered]@{ ok = $false; error = $null }
        verify_ingest_task  = [ordered]@{ ok = $false; task = "\\Mason2\\Mason2 Ingest Autopilot" }
        verify_mirror_task  = [ordered]@{ ok = $false; task = "\\Mason2\\Mason2 Mirror Update" }
    }
    ok = $false
}

if (-not $result.is_elevated) {
    $result.steps.install_ingest_task.error = "Run this script in an elevated PowerShell session (Run as Administrator)."
    $result.steps.install_mirror_task.error = "Run this script in an elevated PowerShell session (Run as Administrator)."
    Write-JsonFile -Path $reportPath -Object $result
    Write-Host "Elevation required. Re-run as Administrator."
    exit 2
}

try {
    & $ingestInstaller -RootPath $repoRoot | Out-Null
    $result.steps.install_ingest_task.ok = $true
}
catch {
    $result.steps.install_ingest_task.error = $_.Exception.Message
}

try {
    & $mirrorInstaller -RootPath $repoRoot | Out-Null
    $result.steps.install_mirror_task.ok = $true
}
catch {
    $result.steps.install_mirror_task.error = $_.Exception.Message
}

$result.steps.verify_ingest_task.ok = Test-TaskExists -TaskPathAndName "\Mason2\Mason2 Ingest Autopilot"
$result.steps.verify_mirror_task.ok = Test-TaskExists -TaskPathAndName "\Mason2\Mason2 Mirror Update"

$result.ok = (
    [bool]$result.steps.install_ingest_task.ok -and
    [bool]$result.steps.install_mirror_task.ok -and
    [bool]$result.steps.verify_ingest_task.ok -and
    [bool]$result.steps.verify_mirror_task.ok
)

Write-JsonFile -Path $reportPath -Object $result

if ($result.ok) {
    exit 0
}
exit 1
