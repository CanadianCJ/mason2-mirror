[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$WorkspaceId = "",
    [string]$ClientName = "client"
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

function ConvertTo-SafeToken {
    param([string]$Text)
    $raw = ([string]$Text).Trim().ToLowerInvariant()
    if (-not $raw) { $raw = "client" }
    $safe = ($raw -replace "[^a-z0-9_-]+", "-").Trim("-")
    if (-not $safe) { $safe = "client" }
    if ($safe.Length -gt 48) { $safe = $safe.Substring(0, 48).Trim("-") }
    if (-not $safe) { $safe = "client" }
    return $safe
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object,
        [int]$Depth = 10
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Set-Content -LiteralPath $Path -Value ($Object | ConvertTo-Json -Depth $Depth) -Encoding UTF8
}

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$workspaceRoot = Join-Path $repoRoot "state\workspaces"
New-Item -ItemType Directory -Path $workspaceRoot -Force | Out-Null

$safeClient = ConvertTo-SafeToken -Text $ClientName
if (-not $WorkspaceId) {
    $WorkspaceId = "{0}-{1}" -f $safeClient, (Get-Date -Format "yyyyMMddHHmmss")
}
$workspaceIdSafe = ConvertTo-SafeToken -Text $WorkspaceId
$workspacePath = Join-Path $workspaceRoot $workspaceIdSafe
$alreadyExists = Test-Path -LiteralPath $workspacePath

$uploadsDir = Join-Path $workspacePath "uploads"
$outputsDir = Join-Path $workspacePath "outputs"
$reportsDir = Join-Path $workspacePath "reports"

New-Item -ItemType Directory -Path $workspacePath -Force | Out-Null
New-Item -ItemType Directory -Path $uploadsDir -Force | Out-Null
New-Item -ItemType Directory -Path $outputsDir -Force | Out-Null
New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null

$metaPath = Join-Path $workspacePath "workspace.json"
$metadata = [ordered]@{
    workspace_id     = $workspaceIdSafe
    client_name      = $ClientName
    updated_at_utc   = (Get-Date).ToUniversalTime().ToString("o")
    paths            = [ordered]@{
        root    = $workspacePath
        uploads = $uploadsDir
        outputs = $outputsDir
        reports = $reportsDir
    }
}

if (-not $alreadyExists) {
    $metadata.created_at_utc = $metadata.updated_at_utc
}
elseif (Test-Path -LiteralPath $metaPath) {
    try {
        $old = Get-Content -LiteralPath $metaPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        if ($old -and ($old.PSObject.Properties.Name -contains "created_at_utc") -and $old.created_at_utc) {
            $metadata.created_at_utc = [string]$old.created_at_utc
        }
        else {
            $metadata.created_at_utc = $metadata.updated_at_utc
        }
    }
    catch {
        $metadata.created_at_utc = $metadata.updated_at_utc
    }
}

Write-JsonFile -Path $metaPath -Object $metadata -Depth 10

[pscustomobject]@{
    ok             = $true
    workspace_id   = $workspaceIdSafe
    workspace_path = $workspacePath
    created        = (-not $alreadyExists)
    metadata_path  = $metaPath
    uploads_path   = $uploadsDir
    outputs_path   = $outputsDir
    reports_path   = $reportsDir
} | ConvertTo-Json -Depth 8
