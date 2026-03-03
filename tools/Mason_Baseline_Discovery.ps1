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
    return (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

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
        return $Default
    }
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object,
        [int]$Depth = 16
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Set-Content -LiteralPath $Path -Value ($Object | ConvertTo-Json -Depth $Depth) -Encoding UTF8
}

function Get-RelativePathSafe {
    param(
        [Parameter(Mandatory = $true)][string]$BasePath,
        [Parameter(Mandatory = $true)][string]$FullPath
    )
    try {
        $baseResolved = (Resolve-Path -LiteralPath $BasePath -ErrorAction Stop).Path
        $fullResolved = (Resolve-Path -LiteralPath $FullPath -ErrorAction Stop).Path
        if ($fullResolved.StartsWith($baseResolved, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $fullResolved.Substring($baseResolved.Length).TrimStart("\", "/")
        }
        return $fullResolved
    }
    catch {
        return $FullPath
    }
}

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
$reportPath = Join-Path $reportsDir "baseline_discovery.json"
$portsPath = Join-Path $repoRoot "config\ports.json"
$servicesPath = Join-Path $repoRoot "config\windows_services.json"
$componentRegistryPath = Join-Path $repoRoot "config\component_registry.json"
$mirrorManifestPath = Join-Path $repoRoot "docs\mirror_manifest.json"
$mirrorPolicyPath = Join-Path $repoRoot "config\mirror_policy.json"

$rootEntrypoints = @(
    "Start_Mason2.ps1",
    "Start_Athena.ps1",
    "Start-Athena.ps1",
    "Start_Mason_Onyx_Stack.ps1",
    "Start_All.ps1",
    "Start_Stack.ps1",
    "Start-MasonStack.ps1"
)

$entrypoints = New-Object System.Collections.Generic.List[object]
foreach ($name in $rootEntrypoints) {
    $path = Join-Path $repoRoot $name
    if (Test-Path -LiteralPath $path) {
        $entrypoints.Add([ordered]@{
                name = $name
                path = $path
            }) | Out-Null
    }
}

$wrapperScripts = @(
    Get-ChildItem -LiteralPath (Join-Path $repoRoot "tools\launch") -File -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty FullName
)

$onyxLaunchers = @(
    Get-ChildItem -LiteralPath (Join-Path $repoRoot "Component - Onyx App\onyx_business_manager") `
        -File -Filter "*Onyx5353.ps1" -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty FullName
)

$masonConsoleServer = Join-Path $repoRoot "MasonConsole\server.py"
$portsObj = Read-JsonSafe -Path $portsPath -Default $null
$servicesObj = Read-JsonSafe -Path $servicesPath -Default $null
$componentRegistry = Read-JsonSafe -Path $componentRegistryPath -Default $null
$mirrorManifest = Read-JsonSafe -Path $mirrorManifestPath -Default $null
$mirrorPolicy = Read-JsonSafe -Path $mirrorPolicyPath -Default $null

$report = [ordered]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    repo_root = $repoRoot
    canonical_entrypoint = [ordered]@{
        path = (Join-Path $repoRoot "Start_Mason2.ps1")
        exists = (Test-Path -LiteralPath (Join-Path $repoRoot "Start_Mason2.ps1"))
    }
    root_entrypoints_present = @($entrypoints.ToArray())
    wrapper_entrypoints = $wrapperScripts
    onyx_launchers = $onyxLaunchers
    masonconsole_server = [ordered]@{
        path = $masonConsoleServer
        exists = (Test-Path -LiteralPath $masonConsoleServer)
    }
    contracts = [ordered]@{
        ports_path = $portsPath
        ports = $portsObj
        windows_services_path = $servicesPath
        windows_services = $servicesObj
        component_registry_path = $componentRegistryPath
        component_registry = $componentRegistry
    }
    mirror = [ordered]@{
        manifest_path = $mirrorManifestPath
        manifest = $mirrorManifest
        policy_path = $mirrorPolicyPath
        policy = $mirrorPolicy
        allowlist_source = if ($mirrorPolicy) { "config/mirror_policy.json" } else { "tools/Write_MirrorManifest.ps1" }
    }
}

Write-JsonFile -Path $reportPath -Object $report -Depth 24

[pscustomobject]@{
    ok = $true
    report = $reportPath
    canonical_entrypoint = $report.canonical_entrypoint.path
    onyx_launchers_count = @($onyxLaunchers).Count
} | ConvertTo-Json -Depth 8
