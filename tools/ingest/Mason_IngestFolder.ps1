[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string[]]$InputPaths = @(),
    [string]$Label = "autopilot",
    [string]$RunId = "",
    [switch]$ForceStorageOnly,
    [switch]$IgnoreDebounce
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

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object,
        [int]$Depth = 14
    )
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $json = $Object | ConvertTo-Json -Depth $Depth
    Set-Content -LiteralPath $Path -Value $json -Encoding UTF8
}

function To-Array {
    param($Value)
    if ($null -eq $Value) { return @() }
    if ($Value -is [System.Array]) { return $Value }
    return @($Value)
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

function Convert-ToRedactedText {
    param(
        [Parameter(Mandatory = $true)][string]$Text
    )

    $redacted = $Text

    # API-like keys
    $redacted = [regex]::Replace($redacted, "(?i)\bsk-proj-[A-Za-z0-9_\-]{8,}\b", "[REDACTED_OPENAI_KEY]")
    $redacted = [regex]::Replace($redacted, "(?i)\bsk-[A-Za-z0-9_\-]{8,}\b", "[REDACTED_OPENAI_KEY]")

    # GitHub tokens
    $redacted = [regex]::Replace($redacted, "(?i)\b(?:ghp|gho|ghu|ghs)_[A-Za-z0-9_]{20,}\b", "[REDACTED_GITHUB_TOKEN]")
    $redacted = [regex]::Replace($redacted, "(?i)\bgithub_pat_[A-Za-z0-9_]{20,}\b", "[REDACTED_GITHUB_TOKEN]")

    # Private key blocks
    $redacted = [regex]::Replace(
        $redacted,
        "(?is)-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----.*?-----END [A-Z0-9 ]*PRIVATE KEY-----",
        "[REDACTED_PRIVATE_KEY_BLOCK]"
    )

    return $redacted
}

function Get-TextChunks {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][int]$MaxChars,
        [Parameter(Mandatory = $true)][int]$MaxChunks
    )

    $clean = $Text
    if (-not $clean) { return @() }
    if ($MaxChars -lt 1) { $MaxChars = 6000 }
    if ($MaxChunks -lt 1) { $MaxChunks = 200 }

    $chunks = New-Object System.Collections.Generic.List[string]
    $offset = 0
    while ($offset -lt $clean.Length -and $chunks.Count -lt $MaxChunks) {
        $len = [Math]::Min($MaxChars, $clean.Length - $offset)
        $chunks.Add($clean.Substring($offset, $len)) | Out-Null
        $offset += $len
    }

    return @($chunks.ToArray())
}

function ConvertTo-SafeFileToken {
    param([string]$Text)
    if (-not $Text) { return "item" }
    $safe = ($Text -replace "[^a-zA-Z0-9_\-]+", "_").Trim("_")
    if (-not $safe) { $safe = "item" }
    if ($safe.Length -gt 64) { $safe = $safe.Substring(0, 64) }
    return $safe
}

function Write-PendingChunk {
    param(
        [Parameter(Mandatory = $true)][string]$PendingRoot,
        [Parameter(Mandatory = $true)][string]$RunIdValue,
        [Parameter(Mandatory = $true)][string]$SourceFile,
        [Parameter(Mandatory = $true)][int]$ChunkIndex,
        [Parameter(Mandatory = $true)][string]$ChunkTextRedacted,
        [Parameter(Mandatory = $true)][string]$Reason,
        [string]$SuggestedModel = "",
        [string]$SuggestedTier = ""
    )

    $runDir = Join-Path $PendingRoot $RunIdValue
    if (-not (Test-Path -LiteralPath $runDir)) {
        New-Item -ItemType Directory -Path $runDir -Force | Out-Null
    }

    $token = ConvertTo-SafeFileToken -Text ([System.IO.Path]::GetFileNameWithoutExtension($SourceFile))
    $pendingPath = Join-Path $runDir ("{0}_chunk{1:0000}.json" -f $token, $ChunkIndex)

    $payload = [ordered]@{
        run_id         = $RunIdValue
        queued_at_utc  = (Get-Date).ToUniversalTime().ToString("o")
        source_file    = $SourceFile
        chunk_index    = [int]$ChunkIndex
        reason         = $Reason
        suggested_tier = $SuggestedTier
        suggested_model = $SuggestedModel
        content_redacted = $ChunkTextRedacted
    }

    Write-JsonFile -Path $pendingPath -Object $payload -Depth 10
    return $pendingPath
}

function Get-TierCostRates {
    param(
        [Parameter(Mandatory = $true)]$BudgetPolicy,
        [Parameter(Mandatory = $true)][string]$Tier
    )

    $inRate = 0.0
    $outRate = 0.0

    if ($BudgetPolicy -and $BudgetPolicy.spend_estimation -and $BudgetPolicy.spend_estimation.model_costs_usd_per_1m_tokens) {
        $map = $BudgetPolicy.spend_estimation.model_costs_usd_per_1m_tokens
        if ($map.PSObject.Properties.Name -contains $Tier) {
            try { $inRate = [double]$map.$Tier.input } catch { $inRate = 0.0 }
            try { $outRate = [double]$map.$Tier.output } catch { $outRate = 0.0 }
        }
    }

    if ($inRate -lt 0.0) { $inRate = 0.0 }
    if ($outRate -lt 0.0) { $outRate = 0.0 }

    return [pscustomobject]@{
        input  = $inRate
        output = $outRate
    }
}

function Get-UsageEstimate {
    param(
        [Parameter(Mandatory = $true)][string]$ChunkText,
        [Parameter(Mandatory = $true)]$BudgetPolicy,
        [Parameter(Mandatory = $true)][string]$Tier
    )

    $inputTokens = [int][Math]::Ceiling(($ChunkText.Length / 3.0))
    if ($inputTokens -lt 1) { $inputTokens = 1 }
    $outputTokens = [int][Math]::Max(64, [Math]::Ceiling($inputTokens * 0.2))

    $rates = Get-TierCostRates -BudgetPolicy $BudgetPolicy -Tier $Tier
    $cost = (($inputTokens * [double]$rates.input) + ($outputTokens * [double]$rates.output)) / 1000000.0

    return [pscustomobject]@{
        input_tokens  = $inputTokens
        output_tokens = $outputTokens
        est_cost_usd  = [Math]::Round($cost, 8)
    }
}

function Get-ResponseUsage {
    param(
        $Response,
        [Parameter(Mandatory = $true)]$Fallback
    )

    $inputTokens = [int]$Fallback.input_tokens
    $outputTokens = [int]$Fallback.output_tokens

    if ($Response -and ($Response.PSObject.Properties.Name -contains "usage") -and $Response.usage) {
        $usage = $Response.usage
        foreach ($name in @("input_tokens", "prompt_tokens")) {
            if ($usage.PSObject.Properties.Name -contains $name) {
                try { $inputTokens = [int]$usage.$name; break } catch { }
            }
        }
        foreach ($name in @("output_tokens", "completion_tokens")) {
            if ($usage.PSObject.Properties.Name -contains $name) {
                try { $outputTokens = [int]$usage.$name; break } catch { }
            }
        }
    }

    return [pscustomobject]@{
        input_tokens  = [Math]::Max(0, $inputTokens)
        output_tokens = [Math]::Max(0, $outputTokens)
    }
}

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$configPath = Join-Path $repoRoot "config\ingest_policy.json"
$reportsDir = Join-Path $repoRoot "reports"
$knowledgeDir = Join-Path $repoRoot "knowledge"
$knowledgeIndexPath = Join-Path $knowledgeDir "index_latest.json"
$pendingRoot = Join-Path $knowledgeDir "pending_llm"
$statusPath = Join-Path $reportsDir "ingest_autopilot_status.json"

if (-not (Test-Path -LiteralPath $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}
if (-not (Test-Path -LiteralPath $pendingRoot)) {
    New-Item -ItemType Directory -Path $pendingRoot -Force | Out-Null
}

$budgetScriptPath = Join-Path $repoRoot "tools\budget\Mason_Budget.ps1"
$selectModelPath = Join-Path $repoRoot "tools\budget\Mason_Select_Model.ps1"
if (-not (Test-Path -LiteralPath $budgetScriptPath)) {
    throw "Missing dependency: $budgetScriptPath"
}
if (-not (Test-Path -LiteralPath $selectModelPath)) {
    throw "Missing dependency: $selectModelPath"
}

$requestedRunId = $RunId
$requestedInputPaths = @($InputPaths)
$requestedLabel = $Label
$forceStorageOnlyEnabled = [bool]$ForceStorageOnly

. $budgetScriptPath -RootPath $repoRoot
. $selectModelPath -RootPath $repoRoot

$RunId = $requestedRunId
$InputPaths = $requestedInputPaths
$Label = $requestedLabel

$policy = Read-JsonSafe -Path $configPath -Default $null
if (-not $policy) {
    throw "Missing ingest policy: $configPath"
}

if (-not [bool]$policy.enabled) {
    $disabled = [ordered]@{
        run_id           = $RunId
        generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
        status           = "disabled"
        reason           = "config.ingest_policy.enabled=false"
    }
    Write-JsonFile -Path $statusPath -Object $disabled -Depth 8
    $disabled | ConvertTo-Json -Depth 8
    exit 0
}

if (-not $RunId) {
    $RunId = Get-Date -Format "yyyyMMdd_HHmmss"
}

$allowedExt = @()
foreach ($ext in To-Array $policy.allowed_ext) {
    if (-not $ext) { continue }
    $value = ([string]$ext).Trim().ToLowerInvariant()
    if (-not $value.StartsWith(".")) {
        $value = "." + $value
    }
    if ($value) { $allowedExt += $value }
}
$allowedExt = @($allowedExt | Select-Object -Unique)
if ($allowedExt.Count -eq 0) {
    $allowedExt = @(".txt", ".md", ".log", ".json")
}

$maxChars = 6000
$maxChunksPerFile = 200
$maxFilesPerRun = 300
$debounceSeconds = 5
try { $maxChars = [int]$policy.max_chars_per_chunk } catch { }
try { $maxChunksPerFile = [int]$policy.max_chunks_per_file } catch { }
try { $maxFilesPerRun = [int]$policy.max_files_per_run } catch { }
try { $debounceSeconds = [int]$policy.debounce_seconds } catch { }

if ($maxChars -lt 1) { $maxChars = 6000 }
if ($maxChunksPerFile -lt 1) { $maxChunksPerFile = 200 }
if ($maxFilesPerRun -lt 1) { $maxFilesPerRun = 300 }
if ($debounceSeconds -lt 0) { $debounceSeconds = 0 }

if (-not $InputPaths -or $InputPaths.Count -eq 0) {
    $InputPaths = @([string]$policy.drop_dir)
}

$debounceCutoff = (Get-Date).ToUniversalTime().AddSeconds(-1 * $debounceSeconds)
$candidateFiles = New-Object System.Collections.Generic.List[object]
$seenPaths = @{}

foreach ($input in @($InputPaths)) {
    if (-not $input) { continue }
    if (-not (Test-Path -LiteralPath $input)) { continue }

    $item = Get-Item -LiteralPath $input -ErrorAction SilentlyContinue
    if (-not $item) { continue }

    if ($item.PSIsContainer) {
        foreach ($file in Get-ChildItem -LiteralPath $item.FullName -Recurse -File -ErrorAction SilentlyContinue) {
            $ext = ([string]$file.Extension).ToLowerInvariant()
            if ($allowedExt -notcontains $ext) { continue }
            if (-not $IgnoreDebounce -and $file.LastWriteTimeUtc -gt $debounceCutoff) { continue }
            $full = $file.FullName
            if ($seenPaths.ContainsKey($full)) { continue }
            $seenPaths[$full] = $true
            $candidateFiles.Add($file) | Out-Null
        }
    }
    else {
        $ext = ([string]$item.Extension).ToLowerInvariant()
        if ($allowedExt -contains $ext -and ($IgnoreDebounce -or $item.LastWriteTimeUtc -le $debounceCutoff)) {
            $full = $item.FullName
            if (-not $seenPaths.ContainsKey($full)) {
                $seenPaths[$full] = $true
                $candidateFiles.Add($item) | Out-Null
            }
        }
    }
}

$orderedFiles = @($candidateFiles.ToArray() | Sort-Object FullName | Select-Object -First $maxFilesPerRun)
$budgetPolicy = Get-BudgetPolicy

$indexChunks = New-Object System.Collections.Generic.List[object]
$indexFiles = New-Object System.Collections.Generic.List[object]
$summaryDecisions = New-Object System.Collections.Generic.List[string]
$summaryRules = New-Object System.Collections.Generic.List[string]
$summaryDoneItems = New-Object System.Collections.Generic.List[string]
$summaryOpenItems = New-Object System.Collections.Generic.List[string]
$summaryTags = New-Object System.Collections.Generic.List[string]

$countFiles = 0
$countChunksTotal = 0
$countChunksSent = 0
$countChunksPending = 0
$countChunksFailed = 0

$modeByPolicy = "llm"
if ($policy.mode) {
    $modeByPolicy = ([string]$policy.mode).ToLowerInvariant()
}

foreach ($file in $orderedFiles) {
    $countFiles++
    $relative = Get-RelativePathSafe -BasePath $repoRoot -FullPath $file.FullName

    $raw = ""
    try {
        $raw = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        try {
            $raw = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction Stop
        }
        catch {
            $raw = ""
        }
    }

    if (-not $raw) {
        $indexFiles.Add([ordered]@{
                path               = $file.FullName
                relative_path      = $relative
                bytes              = [int64]$file.Length
                chunks_total       = 0
                chunks_llm_called  = 0
                chunks_pending_llm = 0
                status             = "empty"
            }) | Out-Null
        continue
    }

    $content = $raw
    if ([bool]$policy.redact_secrets) {
        $content = Convert-ToRedactedText -Text $content
    }

    $chunks = Get-TextChunks -Text $content -MaxChars $maxChars -MaxChunks $maxChunksPerFile
    $fileSent = 0
    $filePending = 0

    $chunkIndex = 0
    foreach ($chunk in $chunks) {
        $chunkIndex++
        $countChunksTotal++

        $selection = Get-ModelSelection
        $tier = [string]$selection.tier
        if (-not $tier.Trim()) { $tier = "PRIMARY" }
        $model = [string]$selection.model

        $estimate = Get-UsageEstimate -ChunkText $chunk -BudgetPolicy $budgetPolicy -Tier $tier
        $effectiveStorageOnly = $forceStorageOnlyEnabled -or $modeByPolicy -ne "llm" -or ([string]$selection.mode).ToLowerInvariant() -eq "storage_only"

        $shouldCall = $false
        if (-not $effectiveStorageOnly) {
            $shouldCall = ShouldAllowPaidCall -op "ingest_chunk" -est_cost_usd ([double]$estimate.est_cost_usd)
        }

        $chunkLabel = "{0}|{1}|chunk:{2}" -f $Label, ([System.IO.Path]::GetFileName($file.FullName)), $chunkIndex
        $chunkRecord = [ordered]@{
            run_id           = $RunId
            source_file      = $file.FullName
            relative_path    = $relative
            chunk_index      = [int]$chunkIndex
            chunk_chars      = [int]$chunk.Length
            pending_llm      = $false
            mode             = if ($effectiveStorageOnly) { "storage_only" } else { "llm" }
            model            = $model
            tier             = $tier
            est_input_tokens = [int]$estimate.input_tokens
            est_output_tokens = [int]$estimate.output_tokens
            est_cost_usd     = [double]$estimate.est_cost_usd
            label            = $chunkLabel
            created_at_utc   = (Get-Date).ToUniversalTime().ToString("o")
            summary          = ""
            decisions        = @()
            rules            = @()
            done_items       = @()
            open_items       = @()
            tags             = @()
            error            = $null
            pending_queue_path = $null
        }

        if ($shouldCall) {
            $payload = @{
                content   = $chunk
                label     = $chunkLabel
                max_chars = $maxChars
            } | ConvertTo-Json -Depth 6

            try {
                $response = Invoke-RestMethod -Uri ([string]$policy.ingest_url) -Method Post -ContentType "application/json" -Body $payload -ErrorAction Stop
                $usage = Get-ResponseUsage -Response $response -Fallback $estimate

                $rates = Get-TierCostRates -BudgetPolicy $budgetPolicy -Tier $tier
                $actualCost = (([double]$usage.input_tokens * [double]$rates.input) + ([double]$usage.output_tokens * [double]$rates.output)) / 1000000.0
                RecordUsage `
                    -run_id $RunId `
                    -op "ingest_chunk" `
                    -model $model `
                    -input_tokens ([int]$usage.input_tokens) `
                    -output_tokens ([int]$usage.output_tokens) `
                    -est_cost_usd ([double][Math]::Round($actualCost, 8)) | Out-Null

                $chunkRecord.summary = if ($response.PSObject.Properties.Name -contains "summary") { [string]$response.summary } else { "" }
                $chunkRecord.decisions = @((To-Array $response.decisions) | ForEach-Object { [string]$_ })
                $chunkRecord.rules = @((To-Array $response.rules) | ForEach-Object { [string]$_ })
                $chunkRecord.done_items = @((To-Array $response.done_items) | ForEach-Object { [string]$_ })
                $chunkRecord.open_items = @((To-Array $response.open_items) | ForEach-Object { [string]$_ })
                $chunkRecord.tags = @((To-Array $response.tags) | ForEach-Object { [string]$_ })
                $chunkRecord.actual_input_tokens = [int]$usage.input_tokens
                $chunkRecord.actual_output_tokens = [int]$usage.output_tokens
                $chunkRecord.actual_cost_usd = [double][Math]::Round($actualCost, 8)

                foreach ($d in $chunkRecord.decisions) { if ($d) { $summaryDecisions.Add($d) | Out-Null } }
                foreach ($r in $chunkRecord.rules) { if ($r) { $summaryRules.Add($r) | Out-Null } }
                foreach ($d in $chunkRecord.done_items) { if ($d) { $summaryDoneItems.Add($d) | Out-Null } }
                foreach ($o in $chunkRecord.open_items) { if ($o) { $summaryOpenItems.Add($o) | Out-Null } }
                foreach ($t in $chunkRecord.tags) { if ($t) { $summaryTags.Add($t) | Out-Null } }

                $countChunksSent++
                $fileSent++
            }
            catch {
                $countChunksFailed++
                $countChunksPending++
                $filePending++
                $chunkRecord.pending_llm = $true
                $chunkRecord.mode = "storage_only"
                $chunkRecord.error = $_.Exception.Message
                $pendingPath = Write-PendingChunk `
                    -PendingRoot $pendingRoot `
                    -RunIdValue $RunId `
                    -SourceFile $file.FullName `
                    -ChunkIndex $chunkIndex `
                    -ChunkTextRedacted $chunk `
                    -Reason "ingest_call_failed" `
                    -SuggestedModel $model `
                    -SuggestedTier $tier
                $chunkRecord.pending_queue_path = Get-RelativePathSafe -BasePath $repoRoot -FullPath $pendingPath
            }
        }
        else {
            $countChunksPending++
            $filePending++
            $chunkRecord.pending_llm = $true
            $chunkRecord.mode = "storage_only"
            $chunkRecord.error = if ($effectiveStorageOnly) { "storage_only_mode" } else { "budget_exhausted" }
            $pendingPath = Write-PendingChunk `
                -PendingRoot $pendingRoot `
                -RunIdValue $RunId `
                -SourceFile $file.FullName `
                -ChunkIndex $chunkIndex `
                -ChunkTextRedacted $chunk `
                -Reason $chunkRecord.error `
                -SuggestedModel $model `
                -SuggestedTier $tier
            $chunkRecord.pending_queue_path = Get-RelativePathSafe -BasePath $repoRoot -FullPath $pendingPath
        }

        $indexChunks.Add($chunkRecord) | Out-Null
    }

    $indexFiles.Add([ordered]@{
            path               = $file.FullName
            relative_path      = $relative
            bytes              = [int64]$file.Length
            chunks_total       = @($chunks).Count
            chunks_llm_called  = $fileSent
            chunks_pending_llm = $filePending
            status             = if ($filePending -gt 0 -and $fileSent -eq 0) { "pending_llm" } elseif ($filePending -gt 0) { "partial" } else { "processed" }
        }) | Out-Null
}

$budgetState = Update-BudgetState
$indexPath = Join-Path $reportsDir ("ingest_index_{0}.json" -f $RunId)
$indexObject = [ordered]@{
    run_id           = $RunId
    created_at_utc   = (Get-Date).ToUniversalTime().ToString("o")
    label            = $Label
    source           = "ingest_autopilot"
    ingest_url       = [string]$policy.ingest_url
    no_llm           = ($countChunksSent -eq 0)
    mode             = if ($countChunksSent -gt 0) { "llm" } else { "storage_only" }
    files            = @($indexFiles.ToArray())
    chunks           = @($indexChunks.ToArray())
    open_items       = @($summaryOpenItems | Select-Object -Unique)
    done_items       = @($summaryDoneItems | Select-Object -Unique)
    decisions        = @($summaryDecisions | Select-Object -Unique)
    rules            = @($summaryRules | Select-Object -Unique)
    tags             = @($summaryTags | Select-Object -Unique)
    stats            = [ordered]@{
        files_total        = $countFiles
        chunks_total       = $countChunksTotal
        chunks_llm_called  = $countChunksSent
        chunks_pending_llm = $countChunksPending
        chunks_failed      = $countChunksFailed
        budget_remaining_cad = [double]$budgetState.weekly_remaining_cad
        budget_remaining_usd = [double]$budgetState.weekly_remaining_usd
        fx_rate_usd_to_cad = [double]$budgetState.fx_rate_usd_to_cad
        budget_currency = [string]$budgetState.currency
    }
}
Write-JsonFile -Path $indexPath -Object $indexObject -Depth 20

$knowledgeIndex = [ordered]@{
    updated_at_utc    = (Get-Date).ToUniversalTime().ToString("o")
    run_id            = $RunId
    ingest_index_path = Get-RelativePathSafe -BasePath $repoRoot -FullPath $indexPath
    mode              = $indexObject.mode
    open_items        = $indexObject.open_items
    done_items        = $indexObject.done_items
    decisions         = $indexObject.decisions
    rules             = $indexObject.rules
    tags              = $indexObject.tags
    counts            = $indexObject.stats
}
Write-JsonFile -Path $knowledgeIndexPath -Object $knowledgeIndex -Depth 16

$statusObject = [ordered]@{
    run_id              = $RunId
    updated_at_utc      = (Get-Date).ToUniversalTime().ToString("o")
    mode                = if ($countChunksSent -gt 0) { "llm" } else { "storage_only" }
    files_processed     = $countFiles
    chunks_total        = $countChunksTotal
    chunks_llm_called   = $countChunksSent
    chunks_pending_llm  = $countChunksPending
    chunks_failed       = $countChunksFailed
    budget_remaining_cad = [double]$budgetState.weekly_remaining_cad
    budget_remaining_usd = [double]$budgetState.weekly_remaining_usd
    fx_rate_usd_to_cad = [double]$budgetState.fx_rate_usd_to_cad
    budget_currency    = [string]$budgetState.currency
    budget_reset_at_utc = [string]$budgetState.reset_at_utc
    ingest_index_path   = Get-RelativePathSafe -BasePath $repoRoot -FullPath $indexPath
    knowledge_index_path = Get-RelativePathSafe -BasePath $repoRoot -FullPath $knowledgeIndexPath
}
Write-JsonFile -Path $statusPath -Object $statusObject -Depth 12

$result = [ordered]@{
    ok            = $true
    run_id        = $RunId
    ingest_index  = $indexPath
    knowledge_index = $knowledgeIndexPath
    status_path   = $statusPath
    counts        = $statusObject
}
$result | ConvertTo-Json -Depth 12
