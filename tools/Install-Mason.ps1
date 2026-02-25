<#  Install-Mason.ps1  —  per-user, idempotent bootstrap for Mason2
    - URLACLs for 7001 (localhost/127.0.0.1/[::1]) to CURRENT USER
    - Loopback-only FW rule (optional but harmless)
    - Logon tasks: Mason-7001 (Mini_File_Server_7001.ps1) + Mason-NodeAgent (NodeAgent.ps1)
    - Starts both tasks now and runs a quick health check
#>

[CmdletBinding()]
param(
  [int]$Port = 7001,
  [int]$ServerRunSeconds = 864000  # 10 days; task restarts on failure anyway
)

$ErrorActionPreference = 'Stop'

function Write-Info($msg){ Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Ok($msg){ Write-Host "[ OK ] $msg" -ForegroundColor Green }
function Write-Warn2($msg){ Write-Warning $msg }
function Test-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $pr = [Security.Principal.WindowsPrincipal]$id
  return $pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# --- Resolve base paths ---
$Base = $env:MASON2_BASE
if ([string]::IsNullOrWhiteSpace($Base)) {
  $Base = Split-Path -Parent $PSCommandPath
  Write-Info "MASON2_BASE not set; using script folder: $Base"
} else {
  Write-Info "Using MASON2_BASE=$Base"
}

$Tools = Join-Path $Base 'tools'
$Lib   = Join-Path $Base 'lib\Mason.Base.psm1'
$Srv   = Join-Path $Tools 'Mini_File_Server_7001.ps1'
$Node  = Join-Path $Tools 'NodeAgent.ps1'
$Smoke = Join-Path $Tools 'Smoke.ps1'

$needed = @($Lib,$Srv,$Node)
$missing = $needed | Where-Object { -not (Test-Path -LiteralPath $_) }
if ($missing) {
  $missing | ForEach-Object { Write-Warn2 "Missing file: $_" }
  throw "One or more required files are missing. Fix and re-run."
}

# Persist per-user env var (helps scheduled tasks)
if ($env:MASON2_BASE -ne $Base) {
  [Environment]::SetEnvironmentVariable('MASON2_BASE', $Base, 'User')
  Write-Ok "Set per-user env MASON2_BASE=$Base"
}

# --- Helpers: URLACL ensure (admin), FW rule ensure (no-op if exists) ---
function Test-UrlAcl([string]$Url){
  $out = & netsh http show urlacl 2>&1 | Out-String
  return ($out -match [Regex]::Escape("Reserved URL            : $Url"))
}
function Ensure-UrlAcl([string]$Url,[string]$User){
  if (Test-UrlAcl $Url) {
    Write-Ok "URLACL exists: $Url"
    return
  }
  if (-not (Test-Admin)) {
    Write-Warn2 ("URLACL missing but this session is not elevated. " +
                 "Run an admin PowerShell and execute: netsh http add urlacl url={0} user={1}" -f $Url, $User)
    return
  }
  Write-Info "Adding URLACL: $Url → $User"
  & netsh http add urlacl url="$Url" user="$User" | Out-Null
  Write-Ok "URLACL added: $Url"
}

function Ensure-FirewallRule([string]$Name, [int]$LocalPort){
  try {
    $rule = Get-NetFirewallRule -DisplayName $Name -ErrorAction SilentlyContinue
    if ($rule) { Write-Ok "FW rule exists: $Name"; return }
    Write-Info "Adding FW rule (loopback only) for TCP $LocalPort"
    New-NetFirewallRule -DisplayName $Name -Direction Inbound -LocalPort $LocalPort `
      -Protocol TCP -Action Allow -Profile Any -LocalAddress @('127.0.0.1','::1') | Out-Null
    Write-Ok "FW rule added: $Name"
  } catch {
    # fixed formatting — no "$name:" parsing issue anymore
    Write-Warning ("[FW] could not ensure rule {0}: {1}" -f $Name, $_.Exception.Message)
  }
}

# --- URLACLs for HTTP listener (three loopback prefixes) ---
$me   = "$env:USERDOMAIN\$env:USERNAME"
$u1   = "http://localhost:$Port/"
$u2   = "http://127.0.0.1:$Port/"
$u3   = "http://[::1]:$Port/"

Ensure-UrlAcl $u1 $me
Ensure-UrlAcl $u2 $me
Ensure-UrlAcl $u3 $me

# --- Optional: firewall (loopback) ---
Ensure-FirewallRule ("Mason2-HTTP-$Port (loopback)") $Port

# --- Scheduled Tasks (per-user, AtLogOn) ---
$settings = New-ScheduledTaskSettingsSet `
  -RestartCount 3 `
  -RestartInterval (New-TimeSpan -Minutes 1) `
  -AllowStartIfOnBatteries `
  -StartWhenAvailable `
  -MultipleInstances IgnoreNew

$trg = New-ScheduledTaskTrigger -AtLogOn
$prn = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Limited

# File server task
$actSrv = New-ScheduledTaskAction -Execute 'powershell.exe' `
  -Argument ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`" -RunSeconds {1}" -f $Srv, $ServerRunSeconds)

# NodeAgent task
$actNode = New-ScheduledTaskAction -Execute 'powershell.exe' `
  -Argument ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $Node)

# Register/update tasks
$taskNames = @(
  @{ Name='Mason-7001';     Action=$actSrv  },
  @{ Name='Mason-NodeAgent';Action=$actNode }
)

foreach($t in $taskNames){
  $name = $t.Name
  $act  = $t.Action
  try{
    if (Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue) {
      Unregister-ScheduledTask -TaskName $name -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
      Write-Info "Replaced existing scheduled task: $name"
    } else {
      Write-Info "Registering scheduled task: $name"
    }
    Register-ScheduledTask -TaskName $name -Action $act -Trigger $trg -Principal $prn -Settings $settings -Description "Mason2: $name" | Out-Null
    Write-Ok "Task ready: $name"
  } catch {
    Write-Warning ("[TASK] failed to register {0}: {1}" -f $name, $_.Exception.Message)
  }
}

# --- Start tasks now (best-effort) ---
foreach($name in @('Mason-7001','Mason-NodeAgent')){
  try {
    Start-ScheduledTask -TaskName $name | Out-Null
    Write-Ok "Task started: $name"
  } catch {
    Write-Warning ("[TASK] could not start {0}: {1}" -f $name, $_.Exception.Message)
  }
}

# --- Quick health check for the file server ---
Start-Sleep -Milliseconds 700
try {
  $resp = Invoke-WebRequest -UseBasicParsing -TimeoutSec 5 -Uri "http://127.0.0.1:$Port/healthz"
  if ($resp.Content.Trim() -eq 'ok') {
    Write-Ok ("Server {0} healthy at http://127.0.0.1:{0}/healthz" -f $Port)
  } else {
    Write-Warn2 ("Healthz returned unexpected content: {0}" -f $resp.Content.Trim())
  }
} catch {
  Write-Warn2 ("Health check failed: {0}" -f $_.Exception.Message)
  Write-Info "Tip: If you skipped URLACL (non-admin), run an elevated PowerShell and add:"
  Write-Host ("  netsh http add urlacl url=http://localhost:{0}/  user=""{1}""" -f $Port, $me)
  Write-Host ("  netsh http add urlacl url=http://127.0.0.1:{0}/ user=""{1}""" -f $Port, $me)
  Write-Host ("  netsh http add urlacl url=http://[::1]:{0}/     user=""{1}""" -f $Port, $me)
}

# --- Optional: quick pack sanity ---
if (Test-Path -LiteralPath $Smoke) {
  try {
    Write-Info "Running Smoke.ps1..."
    & $Smoke
  } catch {
    Write-Warning ("Smoke test failed: {0}" -f $_.Exception.Message)
  }
}
