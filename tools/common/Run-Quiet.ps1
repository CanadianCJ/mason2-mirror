# Run-Quiet.ps1 — hide child consoles from any Mason scripts (PS 5.1-safe)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Start-QuietProcess {
    param(
        [Parameter(Mandatory=$true)][string]$FilePath,
        [string]$ArgumentList = '',
        [string]$WorkingDirectory = $null,
        [switch]$Wait,
        [int]$TimeoutSec = 0
    )
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName  = $FilePath
    $psi.Arguments = $ArgumentList
    if ($WorkingDirectory) { $psi.WorkingDirectory = $WorkingDirectory }

    # Keep it invisible
    $psi.CreateNoWindow  = $true
    $psi.UseShellExecute = $false
    $psi.WindowStyle     = [System.Diagnostics.ProcessWindowStyle]::Hidden
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi
    [void]$p.Start()

    if ($Wait) {
        if ($TimeoutSec -gt 0) { $null = $p.WaitForExit($TimeoutSec * 1000) }
        else { $p.WaitForExit() }
    }
    return $p
}

function Start-QuietPwsh {
    param(
        [Parameter(Mandatory=$true)][string]$ScriptPath,
        [string]$ScriptArgs = ''
    )
    $exe = 'powershell.exe'
    $args = @(
        '-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden',
        '-File', ('"{0}"' -f $ScriptPath)
    )
    if ($ScriptArgs) { $args += $ScriptArgs }
    Start-QuietProcess -FilePath $exe -ArgumentList ($args -join ' ')
}
