$ErrorActionPreference='Stop'
$rows=@()
Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
  try{
    $i = $_ | Get-ScheduledTaskInfo
    $act = ($_.Actions | ForEach-Object { [pscustomobject]@{ Execute=$_.Execute; Arguments=$_.Arguments } })
    $trg = ($_.Triggers | ForEach-Object { [pscustomobject]@{ TriggerType=$_.TriggerType; Repetition=$_.Repetition; StartBoundary=$_.StartBoundary } })
    $rows += [pscustomobject]@{
      TaskName=$_.TaskName; State=$_.State.ToString(); NextRun=$i.NextRunTime
      Actions=$act; Triggers=$trg; Principal=$_.Principal.UserId
    }
  }catch{}
}
($rows | ConvertTo-Json -Depth 6) | Out-File -FilePath (Join-Path $Base 'config\tasks_baseline.json') -Encoding UTF8
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$rows=@()
Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
  try{
    $i = $_ | Get-ScheduledTaskInfo
    $act = ($_.Actions | ForEach-Object { [pscustomobject]@{ Execute=$_.Execute; Arguments=$_.Arguments } })
    $trg = ($_.Triggers | ForEach-Object { [pscustomobject]@{ TriggerType=$_.TriggerType; Repetition=$_.Repetition; StartBoundary=$_.StartBoundary } })
    $rows += [pscustomobject]@{
      TaskName=$_.TaskName; State=$_.State.ToString(); NextRun=$i.NextRunTime
      Actions=$act; Triggers=$trg; Principal=$_.Principal.UserId
    }
  }catch{}
}
($rows | ConvertTo-Json -Depth 6) | Out-File -FilePath (Join-Path $Base 'config\tasks_baseline.json') -Encoding UTF8
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$rows=@()
Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
  try{
    $i = $_ | Get-ScheduledTaskInfo
    $act = ($_.Actions | ForEach-Object { [pscustomobject]@{ Execute=$_.Execute; Arguments=$_.Arguments } })
    $trg = ($_.Triggers | ForEach-Object { [pscustomobject]@{ TriggerType=$_.TriggerType; Repetition=$_.Repetition; StartBoundary=$_.StartBoundary } })
    $rows += [pscustomobject]@{
      TaskName=$_.TaskName; State=$_.State.ToString(); NextRun=$i.NextRunTime
      Actions=$act; Triggers=$trg; Principal=$_.Principal.UserId
    }
  }catch{}
}
($rows | ConvertTo-Json -Depth 6) | Out-File -FilePath (Join-Path $Base 'config\tasks_baseline.json') -Encoding UTF8
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$rows=@()
Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
  try{
    $i = $_ | Get-ScheduledTaskInfo
    $act = ($_.Actions | ForEach-Object { [pscustomobject]@{ Execute=$_.Execute; Arguments=$_.Arguments } })
    $trg = ($_.Triggers | ForEach-Object { [pscustomobject]@{ TriggerType=$_.TriggerType; Repetition=$_.Repetition; StartBoundary=$_.StartBoundary } })
    $rows += [pscustomobject]@{
      TaskName=$_.TaskName; State=$_.State.ToString(); NextRun=$i.NextRunTime
      Actions=$act; Triggers=$trg; Principal=$_.Principal.UserId
    }
  }catch{}
}
($rows | ConvertTo-Json -Depth 6) | Out-File -FilePath (Join-Path $Base 'config\tasks_baseline.json') -Encoding UTF8
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$rows=@()
Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
  try{
    $i = $_ | Get-ScheduledTaskInfo
    $act = ($_.Actions | ForEach-Object { [pscustomobject]@{ Execute=$_.Execute; Arguments=$_.Arguments } })
    $trg = ($_.Triggers | ForEach-Object { [pscustomobject]@{ TriggerType=$_.TriggerType; Repetition=$_.Repetition; StartBoundary=$_.StartBoundary } })
    $rows += [pscustomobject]@{
      TaskName=$_.TaskName; State=$_.State.ToString(); NextRun=$i.NextRunTime
      Actions=$act; Triggers=$trg; Principal=$_.Principal.UserId
    }
  }catch{}
}
($rows | ConvertTo-Json -Depth 6) | Out-File -FilePath (Join-Path $Base 'config\tasks_baseline.json') -Encoding UTF8
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$rows=@()
Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
  try{
    $i = $_ | Get-ScheduledTaskInfo
    $act = ($_.Actions | ForEach-Object { [pscustomobject]@{ Execute=$_.Execute; Arguments=$_.Arguments } })
    $trg = ($_.Triggers | ForEach-Object { [pscustomobject]@{ TriggerType=$_.TriggerType; Repetition=$_.Repetition; StartBoundary=$_.StartBoundary } })
    $rows += [pscustomobject]@{
      TaskName=$_.TaskName; State=$_.State.ToString(); NextRun=$i.NextRunTime
      Actions=$act; Triggers=$trg; Principal=$_.Principal.UserId
    }
  }catch{}
}
($rows | ConvertTo-Json -Depth 6) | Out-File -FilePath (Join-Path $Base 'config\tasks_baseline.json') -Encoding UTF8
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$rows=@()
Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
  try{
    $i = $_ | Get-ScheduledTaskInfo
    $act = ($_.Actions | ForEach-Object { [pscustomobject]@{ Execute=$_.Execute; Arguments=$_.Arguments } })
    $trg = ($_.Triggers | ForEach-Object { [pscustomobject]@{ TriggerType=$_.TriggerType; Repetition=$_.Repetition; StartBoundary=$_.StartBoundary } })
    $rows += [pscustomobject]@{
      TaskName=$_.TaskName; State=$_.State.ToString(); NextRun=$i.NextRunTime
      Actions=$act; Triggers=$trg; Principal=$_.Principal.UserId
    }
  }catch{}
}
($rows | ConvertTo-Json -Depth 6) | Out-File -FilePath (Join-Path $Base 'config\tasks_baseline.json') -Encoding UTF8
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
$rows=@()
Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
  try{
    $i = $_ | Get-ScheduledTaskInfo
    $act = ($_.Actions | ForEach-Object { [pscustomobject]@{ Execute=$_.Execute; Arguments=$_.Arguments } })
    $trg = ($_.Triggers | ForEach-Object { [pscustomobject]@{ TriggerType=$_.TriggerType; Repetition=$_.Repetition; StartBoundary=$_.StartBoundary } })
    $rows += [pscustomobject]@{
      TaskName=$_.TaskName; State=$_.State.ToString(); NextRun=$i.NextRunTime
      Actions=$act; Triggers=$trg; Principal=$_.Principal.UserId
    }
  }catch{}
}
($rows | ConvertTo-Json -Depth 6) | Out-File -FilePath (Join-Path $Base 'config\tasks_baseline.json') -Encoding UTF8
