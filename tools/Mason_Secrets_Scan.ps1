[CmdletBinding()]
param(
    [string]$RootPath = "",
    [switch]$FailOnViolation,
    [switch]$EnforceLoopback
)

$ErrorActionPreference = "Stop"

function Write-ScanLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [Mason_Secrets_Scan] [$Level] $Message"
}

function To-RelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $rootNorm = [System.IO.Path]::GetFullPath($Root)
    $pathNorm = [System.IO.Path]::GetFullPath($Path)
    if ($pathNorm.StartsWith($rootNorm, [System.StringComparison]::OrdinalIgnoreCase)) {
        $rel = $pathNorm.Substring($rootNorm.Length).TrimStart('\', '/')
        return ($rel -replace "\\", "/")
    }
    return ($Path -replace "\\", "/")
}

function Get-ListeningSocketsForPort {
    param([int]$Port)

    $listeners = @()

    if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
        try {
            $rows = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue
            foreach ($row in @($rows)) {
                $listeners += [pscustomobject]@{
                    local_address = [string]$row.LocalAddress
                    local_port    = [int]$row.LocalPort
                    owning_pid    = [int]$row.OwningProcess
                }
            }
            return $listeners
        }
        catch {
            # fallback to netstat
        }
    }

    try {
        $netstat = netstat -ano -p tcp
        foreach ($line in $netstat) {
            if ($line -notmatch "LISTENING") { continue }
            if ($line -notmatch "^\s*TCP\s+(\S+):(\d+)\s+\S+\s+LISTENING\s+(\d+)") { continue }

            $addr = $Matches[1]
            $linePort = [int]$Matches[2]
            $ownerPid = [int]$Matches[3]
            if ($linePort -ne $Port) { continue }

            $listeners += [pscustomobject]@{
                local_address = $addr
                local_port    = $linePort
                owning_pid    = $ownerPid
            }
        }
    }
    catch {
        return @()
    }

    return $listeners
}

function Get-MasonPortsFromConfig {
    param([string]$ServicesPath)

    $ports = New-Object System.Collections.Generic.List[int]

    if (-not (Test-Path -LiteralPath $ServicesPath)) {
        return @()
    }

    try {
        $cfg = Get-Content -LiteralPath $ServicesPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return @()
    }

    if ($cfg -and ($cfg.PSObject.Properties.Name -contains "ports")) {
        foreach ($p in @($cfg.ports)) {
            if ($p -and ($p.PSObject.Properties.Name -contains "port")) {
                $val = 0
                if ([int]::TryParse([string]$p.port, [ref]$val)) {
                    if (-not $ports.Contains($val)) {
                        $ports.Add($val)
                    }
                }
            }
        }
    }

    return @($ports)
}

function Invoke-LoopbackEnforcement {
    param(
        [string]$Root,
        [switch]$RunEnforcement
    )

    $toolsPath = Join-Path $Root "tools"
    $firewallScript = Join-Path $toolsPath "Mason_Firewall_LoopbackOnly.ps1"
    $result = [ordered]@{
        firewall_script_present = (Test-Path -LiteralPath $firewallScript)
        enforcement_attempted   = $false
        enforcement_success     = $false
        enforcement_error       = $null
        rules                   = @()
    }

    if ($RunEnforcement -and $result.firewall_script_present) {
        $result.enforcement_attempted = $true
        try {
            & $firewallScript
            $result.enforcement_success = $true
        }
        catch {
            $result.enforcement_error = $_.Exception.Message
        }
    }

    $ruleNames = @(
        "Mason2-7001-Allow-Loopback",
        "Mason2-7001-Block-Remote"
    )
    foreach ($ruleName in $ruleNames) {
        $present = $false
        if (Get-Command Get-NetFirewallRule -ErrorAction SilentlyContinue) {
            try {
                $rule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($rule) { $present = $true }
            }
            catch {
                $present = $false
            }
        }
        $result.rules += [pscustomobject]@{
            name    = $ruleName
            present = $present
        }
    }

    return [pscustomobject]$result
}

function Collect-SecretHits {
    param(
        [string]$Root,
        [string[]]$RegexPatterns,
        [string[]]$AllowedFiles
    )

    $violations = New-Object System.Collections.Generic.List[object]
    $allowedHits = 0
    $filesScanned = 0

    $rg = Get-Command rg -ErrorAction SilentlyContinue
    if ($rg) {
        $rgArgs = @(
            "--line-number",
            "--no-heading",
            "--color", "never",
            "--hidden",
            "-g", "!**/.git/**",
            "-g", "!**/.git_backup_*/**",
            "-g", "!**/Component - Onyx App/**",
            "-g", "!**/node_modules/**",
            "-g", "!**/dist/**",
            "-g", "!**/build/**",
            "-g", "!**/archives/**",
            "-g", "!**/archive/**",
            "-g", "!**/artifacts/**",
            "-g", "!**/backups/**",
            "-g", "!**/Mason2-code-export-*.txt",
            "-g", "!**/Mason2-code-slice-*.txt",
            "-g", "!**/*.zip",
            "-g", "!**/*.7z",
            "-g", "!**/*.rar"
        )
        foreach ($pattern in $RegexPatterns) {
            $rgArgs += @("-e", $pattern)
        }
        $rgArgs += $Root

        $hits = & $rg.Source @rgArgs 2>$null
        foreach ($line in @($hits)) {
            if (-not $line) { continue }
            if ($line -notmatch "^(.*?):(\d+):") { continue }

            $absPath = $Matches[1]
            $lineNo = [int]$Matches[2]
            $relPath = To-RelativePath -Root $Root -Path $absPath
            $relNorm = $relPath.ToLowerInvariant()

            if ($AllowedFiles.Contains($relNorm)) {
                $allowedHits++
                continue
            }

            $violations.Add([pscustomobject]@{
                file         = $relPath
                line         = $lineNo
                pattern_name = "possible_secret"
            })
        }

        $violationArray = @()
        try {
            $violationArray = @($violations.ToArray())
        }
        catch {
            $violationArray = @($violations)
        }

        return [pscustomobject]@{
            files_scanned = $filesScanned
            allowed_hits  = $allowedHits
            violations    = $violationArray
            method        = "rg"
        }
    }

    $excludeRegex = "\\\.git\\|\\\.git_backup_|\\Component - Onyx App\\|\\node_modules\\|\\dist\\|\\build\\|\\archives\\|\\archive\\|\\artifacts\\|\\backups\\"
    $textExt = @(".ps1", ".psm1", ".json", ".yaml", ".yml", ".toml", ".ini", ".txt", ".md", ".py", ".js", ".ts", ".tsx", ".jsx", ".html", ".css", ".xml", ".cmd", ".bat", ".sh", ".env")
    $combinedRegex = ($RegexPatterns -join "|")

    $allFiles = Get-ChildItem -Path $Root -Recurse -File -ErrorAction SilentlyContinue
    foreach ($file in $allFiles) {
        if ($file.FullName -match $excludeRegex) { continue }
        if ($file.Length -gt 2MB) { continue }
        if ($file.Name -like "Mason2-code-export-*.txt" -or $file.Name -like "Mason2-code-slice-*.txt") { continue }

        $ext = $file.Extension.ToLowerInvariant()
        if ($file.Name -ieq ".env") { $ext = ".env" }
        if (-not $textExt.Contains($ext)) { continue }

        $filesScanned++
        $relPath = To-RelativePath -Root $Root -Path $file.FullName
        $relNorm = $relPath.ToLowerInvariant()

        $matches = Select-String -Path $file.FullName -Pattern $combinedRegex -AllMatches -ErrorAction SilentlyContinue
        foreach ($match in @($matches)) {
            $lineNo = if ($match.LineNumber) { [int]$match.LineNumber } else { 1 }
            if ($AllowedFiles.Contains($relNorm)) {
                $allowedHits++
                continue
            }
            $violations.Add([pscustomobject]@{
                file         = $relPath
                line         = $lineNo
                pattern_name = "possible_secret"
            })
        }
    }

    $violationArray = @()
    try {
        $violationArray = @($violations.ToArray())
    }
    catch {
        $violationArray = @($violations)
    }

    return [pscustomobject]@{
        files_scanned = $filesScanned
        allowed_hits  = $allowedHits
        violations    = $violationArray
        method        = "select-string"
    }
}

$scriptRoot = $PSScriptRoot
if (-not $scriptRoot) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if (-not $RootPath) {
    $RootPath = Split-Path -Parent $scriptRoot
}

$reportsDir = Join-Path $RootPath "reports"
$stateDir = Join-Path $RootPath "state\knowledge"
$configDir = Join-Path $RootPath "config"
New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null

$servicesPath = Join-Path $configDir "services.json"
$pendingPath = Join-Path $stateDir "pending_patch_runs.json"
$trustPath = Join-Path $stateDir "trust_index.json"
$riskPolicyPath = Join-Path $configDir "risk_policy.json"
$securityReportPath = Join-Path $reportsDir "security_posture.json"

$allowedSecretFiles = @(
    "config/secrets_mason.json",
    "config/.env",
    ".env"
) | ForEach-Object { $_.ToLowerInvariant() }

$regexPatterns = @(
    "sk-proj-[A-Za-z0-9_-]{20,}",
    "\bsk-[A-Za-z0-9]{20,}\b",
    "\bAKIA[0-9A-Z]{16}\b",
    "\bghp_[A-Za-z0-9]{30,}\b",
    "\bAIza[0-9A-Za-z\-_]{35}\b",
    "\bxox[baprs]-[A-Za-z0-9-]{10,}\b",
    "-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"
)

$scan = Collect-SecretHits -Root $RootPath -RegexPatterns $regexPatterns -AllowedFiles $allowedSecretFiles
$violations = @($scan.violations)

$portList = Get-MasonPortsFromConfig -ServicesPath $servicesPath
if ($portList.Count -eq 0) {
    $portList = @(7001, 5353, 8000, 8484)
}

$portChecks = @()
foreach ($port in $portList) {
    $listeners = Get-ListeningSocketsForPort -Port $port
    $loopbackOnly = $true

    foreach ($listener in $listeners) {
        $addr = [string]$listener.local_address
        if ($addr -notin @("127.0.0.1", "::1", "localhost")) {
            $loopbackOnly = $false
            break
        }
    }

    $portChecks += [pscustomobject]@{
        port           = [int]$port
        listener_count = @($listeners).Count
        listeners      = @($listeners)
        loopback_only  = $loopbackOnly
    }
}

$loopbackRuleCheck = Invoke-LoopbackEnforcement -Root $RootPath -RunEnforcement:$EnforceLoopback
$loopbackPass = (@($portChecks | Where-Object { -not $_.loopback_only }).Count -eq 0)
$rulePass = (@($loopbackRuleCheck.rules | Where-Object { -not $_.present }).Count -eq 0)

$pendingValid = $false
$trustValid = $false
$duplicateIds = 0
$r3AutoViolations = 0

$pendingItems = @()
if (Test-Path -LiteralPath $pendingPath) {
    try {
        $pendingParsed = Get-Content -LiteralPath $pendingPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        if ($pendingParsed -is [System.Array]) {
            $pendingItems = $pendingParsed
        }
        elseif ($pendingParsed) {
            $pendingItems = @($pendingParsed)
        }
        $pendingValid = $true
    }
    catch {
        $pendingValid = $false
    }
}

if (Test-Path -LiteralPath $trustPath) {
    try {
        $null = Get-Content -LiteralPath $trustPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        $trustValid = $true
    }
    catch {
        $trustValid = $false
    }
}

$idMap = @{}
foreach ($item in $pendingItems) {
    if (-not $item) { continue }
    if (-not ($item.PSObject.Properties.Name -contains "id")) { continue }
    $id = [string]$item.id
    if (-not $id.Trim()) { continue }
    if ($idMap.ContainsKey($id)) {
        $duplicateIds++
    }
    else {
        $idMap[$id] = $true
    }

    $riskText = ""
    if ($item.PSObject.Properties.Name -contains "risk_level") {
        $riskText = ([string]$item.risk_level).ToUpperInvariant()
    }
    $statusText = ""
    if ($item.PSObject.Properties.Name -contains "status") {
        $statusText = ([string]$item.status).ToLowerInvariant()
    }
    $decisionBy = ""
    if ($item.PSObject.Properties.Name -contains "decision_by") {
        $decisionBy = ([string]$item.decision_by).ToLowerInvariant()
    }

    if (($riskText -eq "R3" -or $riskText -eq "3") -and $decisionBy -like "*auto*" -and ($statusText -eq "approve" -or $statusText -eq "approved" -or $statusText -eq "executed")) {
        $r3AutoViolations++
    }
}

$riskGuardrailsPass = $true
if (Test-Path -LiteralPath $riskPolicyPath) {
    try {
        $risk = Get-Content -LiteralPath $riskPolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        if ($risk.global.high_risk_auto_apply) { $riskGuardrailsPass = $false }
        if ($risk.global.money_loop_enabled) { $riskGuardrailsPass = $false }
    }
    catch {
        $riskGuardrailsPass = $false
    }
}

$secretsPass = ($violations.Count -eq 0)
$approvalsPass = ($pendingValid -and $trustValid -and $duplicateIds -eq 0 -and $r3AutoViolations -eq 0 -and $riskGuardrailsPass)
$loopbackFullPass = ($loopbackPass -and $rulePass)

$posture = [ordered]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    root_path        = $RootPath
    secrets_scan     = [ordered]@{
        pass              = $secretsPass
        scan_method       = $scan.method
        files_scanned     = $scan.files_scanned
        allowed_hits      = $scan.allowed_hits
        violation_count   = $violations.Count
        violations        = @($violations | Select-Object -First 100)
        allowed_locations = $allowedSecretFiles
    }
    loopback_bindings = [ordered]@{
        pass                = $loopbackFullPass
        ports_checked       = @($portChecks)
        firewall_rule_check = $loopbackRuleCheck
    }
    approvals_integrity = [ordered]@{
        pass                       = $approvalsPass
        pending_json_valid         = $pendingValid
        trust_index_json_valid     = $trustValid
        duplicate_ids              = $duplicateIds
        r3_auto_approve_violations = $r3AutoViolations
        risk_guardrails_pass       = $riskGuardrailsPass
    }
}
$posture["overall_pass"] = [bool]($secretsPass -and $loopbackFullPass -and $approvalsPass)

$posture | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $securityReportPath -Encoding UTF8

if ($posture.overall_pass) {
    Write-ScanLog "Security posture PASS."
}
else {
    Write-ScanLog "Security posture FAIL." "WARN"
}
Write-ScanLog ("Report: {0}" -f $securityReportPath)

if ($FailOnViolation -and -not $posture.overall_pass) {
    exit 2
}
exit 0
