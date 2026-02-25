param([ValidateSet("On","Off")] [string]$Mode="On")
$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base=Split-Path -Parent $PSCommandPath }
$ctrl = Join-Path $Base "control"; if(-not (Test-Path $ctrl)){ New-Item -ItemType Directory -Force $ctrl | Out-Null }
$flag = Join-Path $ctrl "quiet_hours.on"
if($Mode -eq "On"){ "1" | Set-Content -Encoding ASCII $flag } else { if(Test-Path $flag){ Remove-Item $flag -Force } }
"[QuietHours] $Mode"
