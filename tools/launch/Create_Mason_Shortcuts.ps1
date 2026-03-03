[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-OrUpdateShortcut {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$TargetPath,
        [Parameter(Mandatory = $true)][string]$Arguments,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory,
        [Parameter(Mandatory = $true)][string]$IconLocation
    )

    $shortcut = $script:WshShell.CreateShortcut($Path)
    $shortcut.TargetPath = $TargetPath
    $shortcut.Arguments = $Arguments
    $shortcut.WorkingDirectory = $WorkingDirectory
    $shortcut.IconLocation = $IconLocation
    $shortcut.Save()

    return $Path
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $scriptDir '..\..'))
$launcherDir = Join-Path $repoRoot 'reports\launcher'
New-Item -ItemType Directory -Path $launcherDir -Force | Out-Null

$fullStackWrapper = Join-Path $repoRoot 'tools\launch\Start_Mason_FullStack.ps1'
$coreOnlyWrapper = Join-Path $repoRoot 'tools\launch\Start_Mason_CoreOnly.ps1'
$doctorScript = Join-Path $repoRoot 'tools\launch\Launch_Doctor.ps1'
$athenaStartScript = Join-Path $repoRoot 'Start-Athena.ps1'
$onyxSearchRoot = Join-Path $repoRoot 'Component - Onyx App\onyx_business_manager'

if (-not (Test-Path -LiteralPath $fullStackWrapper)) {
    throw "Wrapper not found: $fullStackWrapper"
}
if (-not (Test-Path -LiteralPath $coreOnlyWrapper)) {
    throw "Wrapper not found: $coreOnlyWrapper"
}
if (-not (Test-Path -LiteralPath $doctorScript)) {
    throw "Doctor script not found: $doctorScript"
}

$desktopDir = [Environment]::GetFolderPath('Desktop')
$startMenuPrograms = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$startMenuMasonDir = Join-Path $startMenuPrograms 'Mason'
New-Item -ItemType Directory -Path $startMenuMasonDir -Force | Out-Null

$powershellExe = (Get-Command powershell.exe -ErrorAction Stop).Source
$iconPath = Join-Path $repoRoot 'docs\assets\mason.ico'
$iconLocation = if (Test-Path -LiteralPath $iconPath) { $iconPath } else { $powershellExe }

$fullStackArgs = '-NoExit -NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $fullStackWrapper
$coreOnlyArgs = '-NoExit -NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $coreOnlyWrapper
$doctorArgs = '-NoExit -NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $doctorScript
$athenaArgs = '-NoExit -NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $athenaStartScript

$script:WshShell = New-Object -ComObject WScript.Shell

$createdOrUpdated = New-Object System.Collections.Generic.List[string]
$healedLegacy = New-Object System.Collections.Generic.List[string]

$shortcutMap = @(
    [pscustomobject]@{
        Path = Join-Path $desktopDir 'Mason Start (FullStack).lnk'
        Arguments = $fullStackArgs
    },
    [pscustomobject]@{
        Path = Join-Path $desktopDir 'Mason Start (CoreOnly).lnk'
        Arguments = $coreOnlyArgs
    },
    [pscustomobject]@{
        Path = Join-Path $startMenuMasonDir 'Mason Start (FullStack).lnk'
        Arguments = $fullStackArgs
    },
    [pscustomobject]@{
        Path = Join-Path $startMenuMasonDir 'Mason Start (CoreOnly).lnk'
        Arguments = $coreOnlyArgs
    },
    [pscustomobject]@{
        Path = Join-Path $desktopDir 'Mason Doctor.lnk'
        Arguments = $doctorArgs
    },
    [pscustomobject]@{
        Path = Join-Path $startMenuMasonDir 'Mason Doctor.lnk'
        Arguments = $doctorArgs
    },
    [pscustomobject]@{
        Path = Join-Path $desktopDir 'Athena Console.lnk'
        Arguments = $athenaArgs
    },
    [pscustomobject]@{
        Path = Join-Path $startMenuMasonDir 'Athena Console.lnk'
        Arguments = $athenaArgs
    }
)

$onyxLauncherPath = $null
if (Test-Path -LiteralPath $onyxSearchRoot) {
    $onyxLauncher = Get-ChildItem -LiteralPath $onyxSearchRoot -Filter 'Start-Onyx5353.ps1' -File -Recurse -ErrorAction SilentlyContinue |
        Sort-Object FullName |
        Select-Object -First 1
    if ($onyxLauncher) {
        $onyxLauncherPath = $onyxLauncher.FullName
    }
}

if ($onyxLauncherPath) {
    $onyxArgs = '-NoExit -NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $onyxLauncherPath
    $shortcutMap += @(
        [pscustomobject]@{
            Path = Join-Path $desktopDir 'Onyx Start.lnk'
            Arguments = $onyxArgs
        },
        [pscustomobject]@{
            Path = Join-Path $startMenuMasonDir 'Onyx Start.lnk'
            Arguments = $onyxArgs
        }
    )
}

foreach ($entry in $shortcutMap) {
    $savedPath = New-OrUpdateShortcut `
        -Path $entry.Path `
        -TargetPath $powershellExe `
        -Arguments $entry.Arguments `
        -WorkingDirectory $repoRoot `
        -IconLocation $iconLocation
    $createdOrUpdated.Add($savedPath)
}

# Optional self-heal: rewrite known old Mason start shortcuts to the FullStack wrapper.
$legacyCandidates = @(
    (Join-Path $desktopDir 'Start Mason.lnk'),
    (Join-Path $desktopDir 'Mason Start.lnk'),
    (Join-Path $startMenuPrograms 'Start Mason.lnk'),
    (Join-Path $startMenuPrograms 'Mason Start.lnk'),
    (Join-Path $startMenuMasonDir 'Start Mason.lnk'),
    (Join-Path $startMenuMasonDir 'Mason Start.lnk')
) | Select-Object -Unique

foreach ($legacyPath in $legacyCandidates) {
    if (-not (Test-Path -LiteralPath $legacyPath)) {
        continue
    }

    $legacyShortcut = $script:WshShell.CreateShortcut($legacyPath)
    $legacyArgs = [string]$legacyShortcut.Arguments
    $needsRewrite = $false

    if ($legacyArgs -match 'Start_Mason2\.ps1' -or
        $legacyArgs -match 'Mason_Start_All\.ps1' -or
        $legacyArgs -match 'Mason_Start_Core_NoApps\.ps1' -or
        $legacyArgs -match 'Start_Mason_FullStack\.ps1' -or
        $legacyArgs -match 'Start_Mason_CoreOnly\.ps1') {
        $needsRewrite = $true
    }

    if ($needsRewrite) {
        $legacyShortcut.TargetPath = $powershellExe
        $legacyShortcut.Arguments = $fullStackArgs
        $legacyShortcut.WorkingDirectory = $repoRoot
        $legacyShortcut.IconLocation = $iconLocation
        $legacyShortcut.Save()
        $healedLegacy.Add($legacyPath)
    }
}

Write-Host 'Created or updated shortcuts:'
foreach ($path in ($createdOrUpdated | Sort-Object -Unique)) {
    Write-Host $path
}

if ($healedLegacy.Count -gt 0) {
    Write-Host 'Self-healed legacy shortcuts:'
    foreach ($path in ($healedLegacy | Sort-Object -Unique)) {
        Write-Host $path
    }
}
else {
    Write-Host 'Self-healed legacy shortcuts: none'
}

Write-Host ('Log folder: {0}' -f $launcherDir)
Write-Host ('Wrapper script: {0}' -f $fullStackWrapper)
Write-Host ('Wrapper script: {0}' -f $coreOnlyWrapper)
Write-Host ('Wrapper script: {0}' -f $doctorScript)
Write-Host ('Athena script: {0}' -f $athenaStartScript)
if ($onyxLauncherPath) {
    Write-Host ('Onyx launcher: {0}' -f $onyxLauncherPath)
}
else {
    Write-Host 'Onyx launcher: not found'
}
