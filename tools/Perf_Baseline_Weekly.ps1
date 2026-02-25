$now=Get-Date
$cpu  = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3).CounterSamples.CookedValue | Measure-Object -Average | Select -ExpandProperty Average
$memf = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
$line = @{ ts=$now.ToString('s'); kind='perf_base'; cpu_pct=[math]::Round($cpu,1); mem_avail_mb=[int]$memf }
($line | ConvertTo-Json -Compress) + [Environment]::NewLine | Out-File -Append -Encoding UTF8 "$env:USERPROFILE\Desktop\Mason2\reports\perf_base.jsonl"
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase$ErrorActionPreference='Stop'
$now=Get-Date
$cpu  = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3).CounterSamples.CookedValue | Measure-Object -Average | Select -ExpandProperty Average
$memf = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
$line = @{ ts=$now.ToString('s'); kind='perf_base'; cpu_pct=[math]::Round($cpu,1); mem_avail_mb=[int]$memf }
($line | ConvertTo-Json -Compress) + [Environment]::NewLine | Out-File -Append -Encoding UTF8 "$env:USERPROFILE\Desktop\Mason2\reports\perf_base.jsonl"
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase$ErrorActionPreference='Stop'
$now=Get-Date
$cpu  = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3).CounterSamples.CookedValue | Measure-Object -Average | Select -ExpandProperty Average
$memf = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
$line = @{ ts=$now.ToString('s'); kind='perf_base'; cpu_pct=[math]::Round($cpu,1); mem_avail_mb=[int]$memf }
($line | ConvertTo-Json -Compress) + [Environment]::NewLine | Out-File -Append -Encoding UTF8 "$env:USERPROFILE\Desktop\Mason2\reports\perf_base.jsonl"
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase$ErrorActionPreference='Stop'
$now=Get-Date
$cpu  = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3).CounterSamples.CookedValue | Measure-Object -Average | Select -ExpandProperty Average
$memf = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
$line = @{ ts=$now.ToString('s'); kind='perf_base'; cpu_pct=[math]::Round($cpu,1); mem_avail_mb=[int]$memf }
($line | ConvertTo-Json -Compress) + [Environment]::NewLine | Out-File -Append -Encoding UTF8 "$env:USERPROFILE\Desktop\Mason2\reports\perf_base.jsonl"
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase$ErrorActionPreference='Stop'
$now=Get-Date
$cpu  = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3).CounterSamples.CookedValue | Measure-Object -Average | Select -ExpandProperty Average
$memf = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
$line = @{ ts=$now.ToString('s'); kind='perf_base'; cpu_pct=[math]::Round($cpu,1); mem_avail_mb=[int]$memf }
($line | ConvertTo-Json -Compress) + [Environment]::NewLine | Out-File -Append -Encoding UTF8 "$env:USERPROFILE\Desktop\Mason2\reports\perf_base.jsonl"
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase$ErrorActionPreference='Stop'
$now=Get-Date
$cpu  = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3).CounterSamples.CookedValue | Measure-Object -Average | Select -ExpandProperty Average
$memf = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
$line = @{ ts=$now.ToString('s'); kind='perf_base'; cpu_pct=[math]::Round($cpu,1); mem_avail_mb=[int]$memf }
($line | ConvertTo-Json -Compress) + [Environment]::NewLine | Out-File -Append -Encoding UTF8 "$env:USERPROFILE\Desktop\Mason2\reports\perf_base.jsonl"
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase$ErrorActionPreference='Stop'
$now=Get-Date
$cpu  = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3).CounterSamples.CookedValue | Measure-Object -Average | Select -ExpandProperty Average
$memf = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
$line = @{ ts=$now.ToString('s'); kind='perf_base'; cpu_pct=[math]::Round($cpu,1); mem_avail_mb=[int]$memf }
($line | ConvertTo-Json -Compress) + [Environment]::NewLine | Out-File -Append -Encoding UTF8 "$env:USERPROFILE\Desktop\Mason2\reports\perf_base.jsonl"
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$now=Get-Date
$cpu  = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3).CounterSamples.CookedValue | Measure-Object -Average | Select -ExpandProperty Average
$memf = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
$line = @{ ts=$now.ToString('s'); kind='perf_base'; cpu_pct=[math]::Round($cpu,1); mem_avail_mb=[int]$memf }
($line | ConvertTo-Json -Compress) + [Environment]::NewLine | Out-File -Append -Encoding UTF8 "$env:USERPROFILE\Desktop\Mason2\reports\perf_base.jsonl"
