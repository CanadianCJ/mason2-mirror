[CmdletBinding()]
param(
    [string]$RootPath = "",
    [int]$HttpTimeoutSeconds = 10
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Normalize-Text {
    param($Value)
    return [regex]::Replace(([string]$Value), "\s+", " ").Trim()
}

function Limit-Text {
    param(
        [string]$Text,
        [int]$MaxLength = 240
    )

    $normalized = [string]$Text
    if ($normalized.Length -le $MaxLength) {
        return $normalized
    }
    return $normalized.Substring(0, $MaxLength).TrimEnd()
}

function Get-PropValue {
    param(
        $Object,
        [Parameter(Mandatory = $true)][string]$Name,
        $Default = $null
    )

    if ($null -eq $Object) {
        return $Default
    }

    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) {
            return $Object[$Name]
        }
        return $Default
    }

    $property = $Object.PSObject.Properties[$Name]
    if ($property) {
        return $property.Value
    }

    return $Default
}

function Test-ObjectHasKey {
    param(
        $Object,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if ($null -eq $Object) {
        return $false
    }

    if ($Object -is [System.Collections.IDictionary]) {
        return $Object.Contains($Name)
    }

    return [bool]$Object.PSObject.Properties[$Name]
}

function Read-JsonSafe {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        $Default = $null
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $Default
    }

    try {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
        if (-not $raw.Trim()) {
            return $Default
        }
        return $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return $Default
    }
}

function Ensure-Parent {
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
        [int]$Depth = 20
    )

    Ensure-Parent -Path $Path
    $Object | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Resolve-RepoRoot {
    param([string]$OverrideRoot)

    if ($OverrideRoot -and (Test-Path -LiteralPath $OverrideRoot)) {
        return (Resolve-Path -LiteralPath $OverrideRoot).Path
    }

    return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

function Resolve-RepoPath {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$PathValue
    )

    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        return $PathValue
    }

    return Join-Path $RepoRoot $PathValue
}

function Invoke-TextUrl {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$TimeoutSeconds = 10
    )

    $request = @{
        Uri         = $Url
        Method      = "Get"
        TimeoutSec  = $TimeoutSeconds
        ErrorAction = "Stop"
    }
    if ((Get-Command Invoke-WebRequest).Parameters.ContainsKey("UseBasicParsing")) {
        $request["UseBasicParsing"] = $true
    }

    try {
        $response = Invoke-WebRequest @request
        return [pscustomobject]@{
            ok          = $true
            status_code = [int]$response.StatusCode
            content     = [string]$response.Content
            error       = ""
            content_type = Normalize-Text ($response.Headers["Content-Type"])
        }
    }
    catch {
        $statusCode = 0
        try {
            if ($_.Exception.Response.StatusCode) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }
        }
        catch {
        }
        return [pscustomobject]@{
            ok           = $false
            status_code  = $statusCode
            content      = ""
            error        = Normalize-Text $_.Exception.Message
            content_type = ""
        }
    }
}

function Get-PathTextContent {
    param([Parameter(Mandatory = $true)][string]$Path)

    try {
        return [string](Get-Content -LiteralPath $Path -Raw -Encoding UTF8)
    }
    catch {
        return ""
    }
}

function Test-IsJsonPath {
    param([string]$Path)
    return ([System.IO.Path]::GetExtension($Path).ToLowerInvariant() -eq ".json")
}

function Test-IsLikelyPathString {
    param([string]$Value)

    $text = Normalize-Text $Value
    if (-not $text) {
        return $false
    }

    if ($text -match '^[A-Za-z]:\\') {
        return $true
    }
    if ($text -match '^https?://') {
        return $true
    }
    if ($text -match '^[.]{0,2}[\\/].+') {
        return $true
    }
    if ($text -match '[/\\].+\.[A-Za-z0-9]{2,5}$') {
        return $true
    }

    return $false
}

function Should-IncludeJsonString {
    param(
        [string]$KeyName,
        [string]$Value
    )

    $normalizedKey = (Normalize-Text $KeyName).ToLowerInvariant()
    if ($normalizedKey -match '(^|_)(path|paths|artifact|artifacts|url|uri|id|ids|component_id|reference_path|manual_path|command|script|endpoint|port|file|dir|directory|generated_at|timestamp|created_at|updated_at|last_write_utc|sort_order|count|status|severity|risk_level|action_posture|provenance)($|_)') {
        return $false
    }

    if (Test-IsLikelyPathString -Value $Value) {
        return $false
    }

    $trimmed = Normalize-Text $Value
    if (-not $trimmed) {
        return $false
    }
    if ($trimmed.Length -lt 2) {
        return $false
    }

    return $true
}

function Collect-JsonDisplayStrings {
    param(
        $Value,
        [string]$PathPrefix = ""
    )

    $results = [System.Collections.Generic.List[object]]::new()

    function Visit-JsonNode {
        param(
            $Node,
            [string]$CurrentPath
        )

        if ($null -eq $Node) {
            return
        }

        if ($Node -is [string]) {
            $leaf = ($CurrentPath -split '\.')[-1]
            if (Should-IncludeJsonString -KeyName $leaf -Value $Node) {
                [void]$results.Add([pscustomobject]@{
                    key_path = $CurrentPath
                    text     = Normalize-Text $Node
                })
            }
            return
        }

        if ($Node -is [System.Collections.IDictionary]) {
            foreach ($key in @($Node.Keys)) {
                $nextPath = if ($CurrentPath) { "$CurrentPath.$key" } else { [string]$key }
                Visit-JsonNode -Node $Node[$key] -CurrentPath $nextPath
            }
            return
        }

        if ($Node -is [System.Collections.IEnumerable] -and -not ($Node -is [string])) {
            $index = 0
            foreach ($item in $Node) {
                $nextPath = if ($CurrentPath) { "$CurrentPath[$index]" } else { "[$index]" }
                Visit-JsonNode -Node $item -CurrentPath $nextPath
                $index += 1
            }
            return
        }

        foreach ($property in @($Node.PSObject.Properties)) {
            $nextPath = if ($CurrentPath) { "$CurrentPath.$($property.Name)" } else { [string]$property.Name }
            Visit-JsonNode -Node $property.Value -CurrentPath $nextPath
        }
    }

    Visit-JsonNode -Node $Value -CurrentPath $PathPrefix
    return @($results)
}

function Get-SurfaceTextSamples {
    param(
        [Parameter(Mandatory = $true)][string]$SurfaceKind,
        [Parameter(Mandatory = $true)][string]$Location,
        [string]$Content = ""
    )

    if ($SurfaceKind -eq "json") {
        $data = Read-JsonSafe -Path $Location -Default $null
        if ($null -eq $data) {
            return @()
        }
        return @(Collect-JsonDisplayStrings -Value $data)
    }

    if ($SurfaceKind -eq "json_live") {
        try {
            $data = $Content | ConvertFrom-Json -ErrorAction Stop
            return @(Collect-JsonDisplayStrings -Value $data)
        }
        catch {
            return @()
        }
    }

    $text = if ($Content) { [string]$Content } else { Get-PathTextContent -Path $Location }
    if (-not (Normalize-Text $text)) {
        return @()
    }

    return @([pscustomobject]@{
        key_path = "raw_text"
        text     = $text
    })
}

function Get-LeakSeverity {
    param(
        [string]$ExposureScope,
        [string]$DetectedTerm
    )

    $publicScopes = @("tenant_customer", "public_export", "billing_facing", "support_facing", "generated_customer_artifact")
    if ($publicScopes -contains $ExposureScope) {
        return "critical"
    }
    if ($ExposureScope -eq "unknown_unclassified") {
        return "medium"
    }
    return "low"
}

function Get-ExposureSurfaceStatus {
    param(
        [string]$ExposureScope,
        [int]$LeakCount,
        [bool]$ScanOk
    )

    if (-not $ScanOk) {
        return "WARN"
    }

    if ($LeakCount -gt 0) {
        if (@("tenant_customer", "public_export", "billing_facing", "support_facing", "generated_customer_artifact") -contains $ExposureScope) {
            return "FAIL"
        }
        return "WARN"
    }

    return "PASS"
}

function Add-SeverityCount {
    param(
        [Parameter(Mandatory = $true)]$Target,
        [Parameter(Mandatory = $true)][string]$Severity
    )

    $current = [int](Get-PropValue -Object $Target -Name $Severity -Default 0)
    $Target[$Severity] = $current + 1
}

$repoRoot = Resolve-RepoRoot -OverrideRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
$configDir = Join-Path $repoRoot "config"
$policyPath = Join-Path $configDir "brand_exposure_policy.json"
$summaryPath = Join-Path $reportsDir "brand_exposure_isolation_last.json"
$auditPath = Join-Path $reportsDir "brand_leak_audit_last.json"
$publicPolicyLastPath = Join-Path $reportsDir "public_vocabulary_policy_last.json"

$policy = Read-JsonSafe -Path $policyPath -Default $null
if (-not $policy) {
    throw "Missing or unreadable brand exposure policy: $policyPath"
}

$scanTargets = @((Get-PropValue -Object $policy -Name "scan_targets" -Default @()))
$bannedPublicTerms = @((Get-PropValue -Object $policy -Name "banned_public_terms" -Default @()) | ForEach-Object { Normalize-Text $_ } | Where-Object { $_ })
$ownerInternalAllowed = @((Get-PropValue -Object $policy -Name "owner_internal_allowed_names" -Default @()) | ForEach-Object { Normalize-Text $_ } | Where-Object { $_ })
$customerPublicAllowed = @((Get-PropValue -Object $policy -Name "customer_public_allowed_names" -Default @()) | ForEach-Object { Normalize-Text $_ } | Where-Object { $_ })

$surfaceRecords = [System.Collections.Generic.List[object]]::new()
$leakRecords = [System.Collections.Generic.List[object]]::new()
$severitySummary = [ordered]@{
    critical = 0
    high     = 0
    medium   = 0
    low      = 0
}
$publicScopes = @("tenant_customer", "public_export", "billing_facing", "support_facing", "generated_customer_artifact")
$internalScopes = @("owner_only", "internal_operator")
$ownerInternalHitCount = 0
$publicSafeSurfaceCount = 0
$publicLeakCount = 0
$internalSurfaceCount = 0
$scanWarnings = 0

foreach ($target in $scanTargets) {
    $surfaceIdBase = Normalize-Text (Get-PropValue -Object $target -Name "surface_id" -Default "")
    $surfaceType = Normalize-Text (Get-PropValue -Object $target -Name "surface_type" -Default "artifact")
    $exposureScope = Normalize-Text (Get-PropValue -Object $target -Name "exposure_scope" -Default "unknown_unclassified")
    $targetKind = Normalize-Text (Get-PropValue -Object $target -Name "target_kind" -Default "path")
    $resolvedItems = [System.Collections.Generic.List[object]]::new()

    switch ($targetKind) {
        "path" {
            $pathText = Normalize-Text (Get-PropValue -Object $target -Name "path" -Default "")
            $resolvedPath = Resolve-RepoPath -RepoRoot $repoRoot -PathValue $pathText
            [void]$resolvedItems.Add([pscustomobject]@{
                surface_id = $surfaceIdBase
                target_kind = "path"
                location = $resolvedPath
            })
        }
        "glob" {
            $glob = Normalize-Text (Get-PropValue -Object $target -Name "glob" -Default "")
            $matches = @(Get-ChildItem -Path (Join-Path $repoRoot $glob) -File -ErrorAction SilentlyContinue | Sort-Object FullName)
            if ($matches.Count -eq 0) {
                [void]$resolvedItems.Add([pscustomobject]@{
                    surface_id = $surfaceIdBase
                    target_kind = "glob"
                    location = Join-Path $repoRoot $glob
                })
            }
            else {
                foreach ($match in $matches) {
                    $matchSurfaceId = "{0}:{1}" -f $surfaceIdBase, $match.BaseName
                    [void]$resolvedItems.Add([pscustomobject]@{
                        surface_id = $matchSurfaceId
                        target_kind = "path"
                        location = $match.FullName
                    })
                }
            }
        }
        "url" {
            $url = Normalize-Text (Get-PropValue -Object $target -Name "url" -Default "")
            [void]$resolvedItems.Add([pscustomobject]@{
                surface_id = $surfaceIdBase
                target_kind = "url"
                location = $url
            })
        }
        default {
            [void]$resolvedItems.Add([pscustomobject]@{
                surface_id = $surfaceIdBase
                target_kind = $targetKind
                location = Normalize-Text (Get-PropValue -Object $target -Name "path" -Default "")
            })
        }
    }

    foreach ($item in @($resolvedItems)) {
        $artifactOrPath = [string]$item.location
        $scanOk = $true
        $scanError = ""
        $surfaceKind = "text"
        $content = ""

        if ($item.target_kind -eq "url") {
            $probe = Invoke-TextUrl -Url $artifactOrPath -TimeoutSeconds $HttpTimeoutSeconds
            $scanOk = [bool]$probe.ok
            $scanError = [string]$probe.error
            $content = [string]$probe.content
            $surfaceKind = if ($artifactOrPath -like "*/api/stack_status") { "json_live" } else { "text" }
        }
        else {
            if (-not (Test-Path -LiteralPath $artifactOrPath)) {
                $scanOk = $false
                $scanError = "Surface path is missing."
            }
            else {
                $surfaceKind = if (Test-IsJsonPath -Path $artifactOrPath) { "json" } else { "text" }
            }
        }

        $samples = @()
        if ($scanOk) {
            $samples = @(Get-SurfaceTextSamples -SurfaceKind $surfaceKind -Location $artifactOrPath -Content $content)
        }

        $surfaceLeakCount = 0
        $internalTermHits = 0
        foreach ($sample in $samples) {
            $text = [string](Get-PropValue -Object $sample -Name "text" -Default "")
            if (-not $text) {
                continue
            }

            foreach ($term in $ownerInternalAllowed) {
                if ($text -match ("(?i)\b{0}\b" -f [regex]::Escape($term))) {
                    $internalTermHits += 1
                    if ($internalScopes -contains $exposureScope) {
                        $ownerInternalHitCount += 1
                    }
                }
            }

            if ($internalScopes -contains $exposureScope) {
                continue
            }

            foreach ($bannedTerm in $bannedPublicTerms) {
                if ($text -notmatch ("(?i)\b{0}\b" -f [regex]::Escape($bannedTerm))) {
                    continue
                }

                $surfaceLeakCount += 1
                if ($publicScopes -contains $exposureScope) {
                    $publicLeakCount += 1
                }
                $severity = Get-LeakSeverity -ExposureScope $exposureScope -DetectedTerm $bannedTerm
                Add-SeverityCount -Target $severitySummary -Severity $severity
                $recommendedAction = if ($publicScopes -contains $exposureScope) {
                    "Replace '$bannedTerm' with Onyx or an approved public-safe label in $artifactOrPath."
                }
                else {
                    "Review the exposure classification for $artifactOrPath before this content is reused publicly."
                }
                [void]$leakRecords.Add([pscustomobject]@{
                    surface_id         = [string]$item.surface_id
                    surface_type       = $surfaceType
                    exposure_scope     = $exposureScope
                    artifact_or_path   = $artifactOrPath
                    detected_term      = $bannedTerm
                    severity           = $severity
                    status             = "open"
                    sample_key_path    = Normalize-Text (Get-PropValue -Object $sample -Name "key_path" -Default "")
                    sample_text        = Limit-Text (Normalize-Text $text)
                    recommended_action = $recommendedAction
                })
            }
        }

        $surfaceStatus = Get-ExposureSurfaceStatus -ExposureScope $exposureScope -LeakCount $surfaceLeakCount -ScanOk $scanOk
        if ($surfaceStatus -eq "WARN") {
            $scanWarnings += 1
        }

        if ($publicScopes -contains $exposureScope -and $surfaceLeakCount -eq 0 -and $scanOk) {
            $publicSafeSurfaceCount += 1
        }
        if ($internalScopes -contains $exposureScope) {
            $internalSurfaceCount += 1
        }

        [void]$surfaceRecords.Add([pscustomobject]@{
            surface_id           = [string]$item.surface_id
            surface_type         = $surfaceType
            exposure_scope       = $exposureScope
            artifact_or_path     = $artifactOrPath
            scan_status          = if ($scanOk) { "scanned" } else { "unreadable" }
            status               = $surfaceStatus
            leak_count           = [int]$surfaceLeakCount
            detected_internal_terms = [int]$internalTermHits
            recommended_action   = if ($scanOk) {
                if ($surfaceLeakCount -gt 0) {
                    "Replace internal brand references with Onyx or approved public-safe labels before reuse."
                }
                else {
                    "No action required."
                }
            }
            else {
                "Restore or reclassify the surface, then rerun the brand exposure audit."
            }
            scan_error           = $scanError
        })
    }
}

$publicSurfacesClean = ($publicLeakCount -eq 0)
$ownerInternalSurfacesIntact = ($internalSurfaceCount -gt 0 -and $ownerInternalHitCount -gt 0)
$overallStatus = "PASS"
if (-not $publicSurfacesClean) {
    $overallStatus = "FAIL"
}
elseif ($scanWarnings -gt 0 -or -not $ownerInternalSurfacesIntact) {
    $overallStatus = "WARN"
}

$publicBrandPosture = if ($publicSurfacesClean) { "clean" } else { "leak_detected" }
$internalBrandPosture = if ($ownerInternalSurfacesIntact) { "preserved" } else { "watch" }
$recommendedNextAction = "No action required."
if (-not $publicSurfacesClean -and $leakRecords.Count -gt 0) {
    $recommendedNextAction = [string]$leakRecords[0].recommended_action
}
elseif ($scanWarnings -gt 0) {
    $recommendedNextAction = "Review unreadable or unclassified brand surfaces, then rerun tools/ops/Run_Brand_Exposure_Isolation.ps1."
}
elseif (-not $ownerInternalSurfacesIntact) {
    $recommendedNextAction = "Confirm owner-only surfaces still expose the internal Mason vocabulary where intended."
}

$policyLast = [ordered]@{
    timestamp_utc                = (Get-Date).ToUniversalTime().ToString("o")
    policy_version               = [int](Get-PropValue -Object $policy -Name "version" -Default 1)
    owner_internal_allowed_names = $ownerInternalAllowed
    customer_public_allowed_names = $customerPublicAllowed
    banned_public_terms          = $bannedPublicTerms
    allowed_exceptions           = @((Get-PropValue -Object $policy -Name "allowed_exceptions" -Default @()))
    public_facing_naming_rules   = @((Get-PropValue -Object $policy -Name "public_facing_naming_rules" -Default @()))
    internal_facing_naming_rules = @((Get-PropValue -Object $policy -Name "internal_facing_naming_rules" -Default @()))
    remediation_guidance         = Get-PropValue -Object $policy -Name "remediation_guidance" -Default @{}
    scan_targets_count           = @($scanTargets).Count
    command_run                  = 'powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\ops\Run_Brand_Exposure_Isolation.ps1'
    repo_root                    = $repoRoot
}

$audit = [ordered]@{
    timestamp_utc                = (Get-Date).ToUniversalTime().ToString("o")
    surfaces_scanned_count       = @($surfaceRecords).Count
    exposures_found_count        = @($leakRecords).Count
    severity_summary             = $severitySummary
    leak_records                 = @($leakRecords)
    per_surface_classification   = @($surfaceRecords)
    recommended_remediations     = @($leakRecords | Select-Object -ExpandProperty recommended_action -Unique)
    public_surfaces_clean        = [bool]$publicSurfacesClean
    owner_internal_surfaces_intact = [bool]$ownerInternalSurfacesIntact
    command_run                  = 'powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\ops\Run_Brand_Exposure_Isolation.ps1'
    repo_root                    = $repoRoot
}

$summary = [ordered]@{
    timestamp_utc                 = (Get-Date).ToUniversalTime().ToString("o")
    overall_status                = $overallStatus
    public_brand_posture          = $publicBrandPosture
    internal_brand_posture        = $internalBrandPosture
    total_surfaces_scanned        = @($surfaceRecords).Count
    public_safe_surface_count     = [int]$publicSafeSurfaceCount
    public_leak_count             = [int]$publicLeakCount
    internal_surface_count        = [int]$internalSurfaceCount
    recommended_next_action       = $recommendedNextAction
    owner_only_wording_preserved  = [bool]$ownerInternalSurfacesIntact
    customer_only_wording_isolated = [bool]$publicSurfacesClean
    command_run                   = 'powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\ops\Run_Brand_Exposure_Isolation.ps1'
    repo_root                     = $repoRoot
}

Write-JsonFile -Path $publicPolicyLastPath -Object $policyLast
Write-JsonFile -Path $auditPath -Object $audit
Write-JsonFile -Path $summaryPath -Object $summary

$summary | ConvertTo-Json -Depth 12 | Write-Output
