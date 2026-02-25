# Stamped: 2025-11-05T17:02:01
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot 'Common.ps1')

Add-Type -AssemblyName PresentationCore,PresentationFramework

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Auto Ops" Width="800" Height="520" WindowStartupLocation="CenterScreen" Background="#1e1e1e" Foreground="#e6e6e6">
  <Grid Margin="12">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
      <Button Name="btnEnable"  Content="Enable Auto-Ops"  Padding="10,6"/>
      <Button Name="btnDisable" Content="Disable Auto-Ops" Padding="10,6" Margin="8,0,0,0"/>
      <Button Name="btnRefresh" Content="Refresh"          Padding="10,6" Margin="16,0,0,0"/>
      <Button Name="btnOpenLogs" Content="Open Logs"       Padding="10,6" Margin="8,0,0,0"/>
    </StackPanel>

    <ListView Name="lv" Grid.Row="1" Margin="0,0,0,8" Background="#252526" Foreground="#e6e6e6" BorderBrush="#3c3c3c">
      <ListView.View>
        <GridView>
          <GridViewColumn Header="Task"     DisplayMemberBinding="{Binding TaskName}" Width="220"/>
          <GridViewColumn Header="State"    DisplayMemberBinding="{Binding State}" Width="100"/>
          <GridViewColumn Header="LastRun"  DisplayMemberBinding="{Binding LastRunTime}" Width="200"/>
          <GridViewColumn Header="Result"   DisplayMemberBinding="{Binding LastTaskResult}" Width="100"/>
          <GridViewColumn Header="NextRun"  DisplayMemberBinding="{Binding NextRunTime}" Width="200"/>
        </GridView>
      </ListView.View>
    </ListView>

    <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right">
      <Button Name="btnRunCleanup" Content="Run Cleanup"      Padding="12,6"/>
      <Button Name="btnRunVerify"  Content="Run VerifyLatest" Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnRunTrim"    Content="Run Trim"         Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnRunApply"   Content="Run Verify+Apply" Padding="12,6" Margin="8,0,0,0"/>
      
      <Button Name="btnOpenReleases" Content="Open Releases" Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnOpenCurrent"  Content="Open Current"  Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnRollback"     Content="Rollback"      Padding="12,6" Margin="8,0,0,0"/>
<Button Name="btnClose"      Content="Close"            Padding="12,6" Margin="8,0,0,0"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$w      = [Windows.Markup.XamlReader]::Load($reader)

$lv             = $w.FindName('lv')
$btnRefresh     = $w.FindName('btnRefresh')
$btnOpenLogs    = $w.FindName('btnOpenLogs')
$btnEnable      = $w.FindName('btnEnable')
$btnDisable     = $w.FindName('btnDisable')
$btnRunCleanup  = $w.FindName('btnRunCleanup')
$btnRunVerify   = $w.FindName('btnRunVerify')
$btnRunTrim     = $w.FindName('btnRunTrim')
$btnRunApply    = $w.FindName('btnRunApply')
$btnClose       = $w.FindName('btnClose')

$taskNames = 'Mason2-CleanupStages','Mason2-VerifyLatest','Mason2-TrimReleases','Mason2-VerifyApply'

function Refresh-AutoOps {
  $lv.Items.Clear()
  foreach($t in (Get-ScheduledTask -TaskName 'Mason2-*' | Where-Object { $taskNames -contains $_.TaskName })) {
    $i = $t | Get-ScheduledTaskInfo
    [void]$lv.Items.Add([pscustomobject]@{
      TaskName       = $t.TaskName
      State          = $t.State
      LastRunTime    = $i.LastRunTime
      LastTaskResult = $i.LastTaskResult
      NextRunTime    = $i.NextRunTime
    })
  }
}

$btnRefresh.Add_Click({ Refresh-AutoOps })
$btnOpenLogs.Add_Click({ Start-Process explorer.exe (Join-Path $script:Paths.Base 'reports') })
$btnEnable.Add_Click({
  Start-Process -WindowStyle Hidden "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', (Join-Path $script:Paths.Tools 'Setup_ScheduledTasks.ps1'), '-Enable') | Out-Null
  Start-Sleep 1; Refresh-AutoOps
})
$btnDisable.Add_Click({
  Start-Process -WindowStyle Hidden "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', (Join-Path $script:Paths.Tools 'Setup_ScheduledTasks.ps1'), '-Disable') | Out-Null
  Start-Sleep 1; Refresh-AutoOps
})
$btnRunCleanup.Add_Click({ Start-ScheduledTask -TaskName 'Mason2-CleanupStages'; Start-Sleep 1; Refresh-AutoOps })
$btnRunVerify.Add_Click( { Start-ScheduledTask -TaskName 'Mason2-VerifyLatest';  Start-Sleep 1; Refresh-AutoOps })
$btnRunTrim.Add_Click(   { Start-ScheduledTask -TaskName 'Mason2-TrimReleases';  Start-Sleep 1; Refresh-AutoOps })
$btnRunApply.Add_Click(  { Start-ScheduledTask -TaskName 'Mason2-VerifyApply';   Start-Sleep 1; Refresh-AutoOps })
$btnClose.Add_Click(     { $w.Close() })

Refresh-AutoOps
$null = $w.ShowDialog()


# --- extra Auto-Ops buttons ---
$btnOpenReleases = $w.FindName('btnOpenReleases')
$btnOpenCurrent  = $w.FindName('btnOpenCurrent')
$btnRollback     = $w.FindName('btnRollback')

if($btnOpenReleases){ $btnOpenReleases.Add_Click({ Start-Process explorer.exe (Join-Path $script:Paths.Releases '.') }) }
if($btnOpenCurrent ){ $btnOpenCurrent.Add_Click( { Start-Process explorer.exe (Join-Path $script:Paths.Current  '.') }) }

if($btnRollback){
  $btnRollback.Add_Click({
    try{
      Start-Process -WindowStyle Hidden "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
        -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f (Join-Path $PSScriptRoot 'Rollback_Current.ps1')) | Out-Null
      Start-Sleep 1
      [System.Windows.MessageBox]::Show("Rollback attempted. Check 'dist\\current' and backups.","Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Auto Ops") | Out-Null
    }catch{
      [System.Windows.MessageBox]::Show($_.Exception.Message,"Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Auto Ops") | Out-Null
    }
  })
}
# --- end extra Auto-Ops buttons ---


_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot 'Common.ps1')

Add-Type -AssemblyName PresentationCore,PresentationFramework

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Auto Ops" Width="800" Height="520" WindowStartupLocation="CenterScreen" Background="#1e1e1e" Foreground="#e6e6e6">
  <Grid Margin="12">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
      <Button Name="btnEnable"  Content="Enable Auto-Ops"  Padding="10,6"/>
      <Button Name="btnDisable" Content="Disable Auto-Ops" Padding="10,6" Margin="8,0,0,0"/>
      <Button Name="btnRefresh" Content="Refresh"          Padding="10,6" Margin="16,0,0,0"/>
      <Button Name="btnOpenLogs" Content="Open Logs"       Padding="10,6" Margin="8,0,0,0"/>
    </StackPanel>

    <ListView Name="lv" Grid.Row="1" Margin="0,0,0,8" Background="#252526" Foreground="#e6e6e6" BorderBrush="#3c3c3c">
      <ListView.View>
        <GridView>
          <GridViewColumn Header="Task"     DisplayMemberBinding="{Binding TaskName}" Width="220"/>
          <GridViewColumn Header="State"    DisplayMemberBinding="{Binding State}" Width="100"/>
          <GridViewColumn Header="LastRun"  DisplayMemberBinding="{Binding LastRunTime}" Width="200"/>
          <GridViewColumn Header="Result"   DisplayMemberBinding="{Binding LastTaskResult}" Width="100"/>
          <GridViewColumn Header="NextRun"  DisplayMemberBinding="{Binding NextRunTime}" Width="200"/>
        </GridView>
      </ListView.View>
    </ListView>

    <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right">
      <Button Name="btnRunCleanup" Content="Run Cleanup"      Padding="12,6"/>
      <Button Name="btnRunVerify"  Content="Run VerifyLatest" Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnRunTrim"    Content="Run Trim"         Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnRunApply"   Content="Run Verify+Apply" Padding="12,6" Margin="8,0,0,0"/>
      
      <Button Name="btnOpenReleases" Content="Open Releases" Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnOpenCurrent"  Content="Open Current"  Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnRollback"     Content="Rollback"      Padding="12,6" Margin="8,0,0,0"/>
<Button Name="btnClose"      Content="Close"            Padding="12,6" Margin="8,0,0,0"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$w      = [Windows.Markup.XamlReader]::Load($reader)

$lv             = $w.FindName('lv')
$btnRefresh     = $w.FindName('btnRefresh')
$btnOpenLogs    = $w.FindName('btnOpenLogs')
$btnEnable      = $w.FindName('btnEnable')
$btnDisable     = $w.FindName('btnDisable')
$btnRunCleanup  = $w.FindName('btnRunCleanup')
$btnRunVerify   = $w.FindName('btnRunVerify')
$btnRunTrim     = $w.FindName('btnRunTrim')
$btnRunApply    = $w.FindName('btnRunApply')
$btnClose       = $w.FindName('btnClose')

$taskNames = 'Mason2-CleanupStages','Mason2-VerifyLatest','Mason2-TrimReleases','Mason2-VerifyApply'

function Refresh-AutoOps {
  $lv.Items.Clear()
  foreach($t in (Get-ScheduledTask -TaskName 'Mason2-*' | Where-Object { $taskNames -contains $_.TaskName })) {
    $i = $t | Get-ScheduledTaskInfo
    [void]$lv.Items.Add([pscustomobject]@{
      TaskName       = $t.TaskName
      State          = $t.State
      LastRunTime    = $i.LastRunTime
      LastTaskResult = $i.LastTaskResult
      NextRunTime    = $i.NextRunTime
    })
  }
}

$btnRefresh.Add_Click({ Refresh-AutoOps })
$btnOpenLogs.Add_Click({ Start-Process explorer.exe (Join-Path $script:Paths.Base 'reports') })
$btnEnable.Add_Click({
  Start-Process -WindowStyle Hidden "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', (Join-Path $script:Paths.Tools 'Setup_ScheduledTasks.ps1'), '-Enable') | Out-Null
  Start-Sleep 1; Refresh-AutoOps
})
$btnDisable.Add_Click({
  Start-Process -WindowStyle Hidden "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', (Join-Path $script:Paths.Tools 'Setup_ScheduledTasks.ps1'), '-Disable') | Out-Null
  Start-Sleep 1; Refresh-AutoOps
})
$btnRunCleanup.Add_Click({ Start-ScheduledTask -TaskName 'Mason2-CleanupStages'; Start-Sleep 1; Refresh-AutoOps })
$btnRunVerify.Add_Click( { Start-ScheduledTask -TaskName 'Mason2-VerifyLatest';  Start-Sleep 1; Refresh-AutoOps })
$btnRunTrim.Add_Click(   { Start-ScheduledTask -TaskName 'Mason2-TrimReleases';  Start-Sleep 1; Refresh-AutoOps })
$btnRunApply.Add_Click(  { Start-ScheduledTask -TaskName 'Mason2-VerifyApply';   Start-Sleep 1; Refresh-AutoOps })
$btnClose.Add_Click(     { $w.Close() })

Refresh-AutoOps
$null = $w.ShowDialog()


# --- extra Auto-Ops buttons ---
$btnOpenReleases = $w.FindName('btnOpenReleases')
$btnOpenCurrent  = $w.FindName('btnOpenCurrent')
$btnRollback     = $w.FindName('btnRollback')

if($btnOpenReleases){ $btnOpenReleases.Add_Click({ Start-Process explorer.exe (Join-Path $script:Paths.Releases '.') }) }
if($btnOpenCurrent ){ $btnOpenCurrent.Add_Click( { Start-Process explorer.exe (Join-Path $script:Paths.Current  '.') }) }

if($btnRollback){
  $btnRollback.Add_Click({
    try{
      Start-Process -WindowStyle Hidden "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
        -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f (Join-Path $PSScriptRoot 'Rollback_Current.ps1')) | Out-Null
      Start-Sleep 1
      [System.Windows.MessageBox]::Show("Rollback attempted. Check 'dist\\current' and backups.","Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Auto Ops") | Out-Null
    }catch{
      [System.Windows.MessageBox]::Show($_.Exception.Message,"Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Auto Ops") | Out-Null
    }
  })
}
# --- end extra Auto-Ops buttons ---


_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot 'Common.ps1')

Add-Type -AssemblyName PresentationCore,PresentationFramework

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Auto Ops" Width="800" Height="520" WindowStartupLocation="CenterScreen" Background="#1e1e1e" Foreground="#e6e6e6">
  <Grid Margin="12">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
      <Button Name="btnEnable"  Content="Enable Auto-Ops"  Padding="10,6"/>
      <Button Name="btnDisable" Content="Disable Auto-Ops" Padding="10,6" Margin="8,0,0,0"/>
      <Button Name="btnRefresh" Content="Refresh"          Padding="10,6" Margin="16,0,0,0"/>
      <Button Name="btnOpenLogs" Content="Open Logs"       Padding="10,6" Margin="8,0,0,0"/>
    </StackPanel>

    <ListView Name="lv" Grid.Row="1" Margin="0,0,0,8" Background="#252526" Foreground="#e6e6e6" BorderBrush="#3c3c3c">
      <ListView.View>
        <GridView>
          <GridViewColumn Header="Task"     DisplayMemberBinding="{Binding TaskName}" Width="220"/>
          <GridViewColumn Header="State"    DisplayMemberBinding="{Binding State}" Width="100"/>
          <GridViewColumn Header="LastRun"  DisplayMemberBinding="{Binding LastRunTime}" Width="200"/>
          <GridViewColumn Header="Result"   DisplayMemberBinding="{Binding LastTaskResult}" Width="100"/>
          <GridViewColumn Header="NextRun"  DisplayMemberBinding="{Binding NextRunTime}" Width="200"/>
        </GridView>
      </ListView.View>
    </ListView>

    <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right">
      <Button Name="btnRunCleanup" Content="Run Cleanup"      Padding="12,6"/>
      <Button Name="btnRunVerify"  Content="Run VerifyLatest" Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnRunTrim"    Content="Run Trim"         Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnRunApply"   Content="Run Verify+Apply" Padding="12,6" Margin="8,0,0,0"/>
      
      <Button Name="btnOpenReleases" Content="Open Releases" Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnOpenCurrent"  Content="Open Current"  Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnRollback"     Content="Rollback"      Padding="12,6" Margin="8,0,0,0"/>
<Button Name="btnClose"      Content="Close"            Padding="12,6" Margin="8,0,0,0"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$w      = [Windows.Markup.XamlReader]::Load($reader)

$lv             = $w.FindName('lv')
$btnRefresh     = $w.FindName('btnRefresh')
$btnOpenLogs    = $w.FindName('btnOpenLogs')
$btnEnable      = $w.FindName('btnEnable')
$btnDisable     = $w.FindName('btnDisable')
$btnRunCleanup  = $w.FindName('btnRunCleanup')
$btnRunVerify   = $w.FindName('btnRunVerify')
$btnRunTrim     = $w.FindName('btnRunTrim')
$btnRunApply    = $w.FindName('btnRunApply')
$btnClose       = $w.FindName('btnClose')

$taskNames = 'Mason2-CleanupStages','Mason2-VerifyLatest','Mason2-TrimReleases','Mason2-VerifyApply'

function Refresh-AutoOps {
  $lv.Items.Clear()
  foreach($t in (Get-ScheduledTask -TaskName 'Mason2-*' | Where-Object { $taskNames -contains $_.TaskName })) {
    $i = $t | Get-ScheduledTaskInfo
    [void]$lv.Items.Add([pscustomobject]@{
      TaskName       = $t.TaskName
      State          = $t.State
      LastRunTime    = $i.LastRunTime
      LastTaskResult = $i.LastTaskResult
      NextRunTime    = $i.NextRunTime
    })
  }
}

$btnRefresh.Add_Click({ Refresh-AutoOps })
$btnOpenLogs.Add_Click({ Start-Process explorer.exe (Join-Path $script:Paths.Base 'reports') })
$btnEnable.Add_Click({
  Start-Process -WindowStyle Hidden "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', (Join-Path $script:Paths.Tools 'Setup_ScheduledTasks.ps1'), '-Enable') | Out-Null
  Start-Sleep 1; Refresh-AutoOps
})
$btnDisable.Add_Click({
  Start-Process -WindowStyle Hidden "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', (Join-Path $script:Paths.Tools 'Setup_ScheduledTasks.ps1'), '-Disable') | Out-Null
  Start-Sleep 1; Refresh-AutoOps
})
$btnRunCleanup.Add_Click({ Start-ScheduledTask -TaskName 'Mason2-CleanupStages'; Start-Sleep 1; Refresh-AutoOps })
$btnRunVerify.Add_Click( { Start-ScheduledTask -TaskName 'Mason2-VerifyLatest';  Start-Sleep 1; Refresh-AutoOps })
$btnRunTrim.Add_Click(   { Start-ScheduledTask -TaskName 'Mason2-TrimReleases';  Start-Sleep 1; Refresh-AutoOps })
$btnRunApply.Add_Click(  { Start-ScheduledTask -TaskName 'Mason2-VerifyApply';   Start-Sleep 1; Refresh-AutoOps })
$btnClose.Add_Click(     { $w.Close() })

Refresh-AutoOps
$null = $w.ShowDialog()


# --- extra Auto-Ops buttons ---
$btnOpenReleases = $w.FindName('btnOpenReleases')
$btnOpenCurrent  = $w.FindName('btnOpenCurrent')
$btnRollback     = $w.FindName('btnRollback')

if($btnOpenReleases){ $btnOpenReleases.Add_Click({ Start-Process explorer.exe (Join-Path $script:Paths.Releases '.') }) }
if($btnOpenCurrent ){ $btnOpenCurrent.Add_Click( { Start-Process explorer.exe (Join-Path $script:Paths.Current  '.') }) }

if($btnRollback){
  $btnRollback.Add_Click({
    try{
      Start-Process -WindowStyle Hidden "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
        -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f (Join-Path $PSScriptRoot 'Rollback_Current.ps1')) | Out-Null
      Start-Sleep 1
      [System.Windows.MessageBox]::Show("Rollback attempted. Check 'dist\\current' and backups.","Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Auto Ops") | Out-Null
    }catch{
      [System.Windows.MessageBox]::Show($_.Exception.Message,"Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Auto Ops") | Out-Null
    }
  })
}
# --- end extra Auto-Ops buttons ---


_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot 'Common.ps1')

Add-Type -AssemblyName PresentationCore,PresentationFramework

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Auto Ops" Width="800" Height="520" WindowStartupLocation="CenterScreen" Background="#1e1e1e" Foreground="#e6e6e6">
  <Grid Margin="12">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
      <Button Name="btnEnable"  Content="Enable Auto-Ops"  Padding="10,6"/>
      <Button Name="btnDisable" Content="Disable Auto-Ops" Padding="10,6" Margin="8,0,0,0"/>
      <Button Name="btnRefresh" Content="Refresh"          Padding="10,6" Margin="16,0,0,0"/>
      <Button Name="btnOpenLogs" Content="Open Logs"       Padding="10,6" Margin="8,0,0,0"/>
    </StackPanel>

    <ListView Name="lv" Grid.Row="1" Margin="0,0,0,8" Background="#252526" Foreground="#e6e6e6" BorderBrush="#3c3c3c">
      <ListView.View>
        <GridView>
          <GridViewColumn Header="Task"     DisplayMemberBinding="{Binding TaskName}" Width="220"/>
          <GridViewColumn Header="State"    DisplayMemberBinding="{Binding State}" Width="100"/>
          <GridViewColumn Header="LastRun"  DisplayMemberBinding="{Binding LastRunTime}" Width="200"/>
          <GridViewColumn Header="Result"   DisplayMemberBinding="{Binding LastTaskResult}" Width="100"/>
          <GridViewColumn Header="NextRun"  DisplayMemberBinding="{Binding NextRunTime}" Width="200"/>
        </GridView>
      </ListView.View>
    </ListView>

    <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right">
      <Button Name="btnRunCleanup" Content="Run Cleanup"      Padding="12,6"/>
      <Button Name="btnRunVerify"  Content="Run VerifyLatest" Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnRunTrim"    Content="Run Trim"         Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnRunApply"   Content="Run Verify+Apply" Padding="12,6" Margin="8,0,0,0"/>
      
      <Button Name="btnOpenReleases" Content="Open Releases" Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnOpenCurrent"  Content="Open Current"  Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnRollback"     Content="Rollback"      Padding="12,6" Margin="8,0,0,0"/>
<Button Name="btnClose"      Content="Close"            Padding="12,6" Margin="8,0,0,0"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$w      = [Windows.Markup.XamlReader]::Load($reader)

$lv             = $w.FindName('lv')
$btnRefresh     = $w.FindName('btnRefresh')
$btnOpenLogs    = $w.FindName('btnOpenLogs')
$btnEnable      = $w.FindName('btnEnable')
$btnDisable     = $w.FindName('btnDisable')
$btnRunCleanup  = $w.FindName('btnRunCleanup')
$btnRunVerify   = $w.FindName('btnRunVerify')
$btnRunTrim     = $w.FindName('btnRunTrim')
$btnRunApply    = $w.FindName('btnRunApply')
$btnClose       = $w.FindName('btnClose')

$taskNames = 'Mason2-CleanupStages','Mason2-VerifyLatest','Mason2-TrimReleases','Mason2-VerifyApply'

function Refresh-AutoOps {
  $lv.Items.Clear()
  foreach($t in (Get-ScheduledTask -TaskName 'Mason2-*' | Where-Object { $taskNames -contains $_.TaskName })) {
    $i = $t | Get-ScheduledTaskInfo
    [void]$lv.Items.Add([pscustomobject]@{
      TaskName       = $t.TaskName
      State          = $t.State
      LastRunTime    = $i.LastRunTime
      LastTaskResult = $i.LastTaskResult
      NextRunTime    = $i.NextRunTime
    })
  }
}

$btnRefresh.Add_Click({ Refresh-AutoOps })
$btnOpenLogs.Add_Click({ Start-Process explorer.exe (Join-Path $script:Paths.Base 'reports') })
$btnEnable.Add_Click({
  Start-Process -WindowStyle Hidden "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', (Join-Path $script:Paths.Tools 'Setup_ScheduledTasks.ps1'), '-Enable') | Out-Null
  Start-Sleep 1; Refresh-AutoOps
})
$btnDisable.Add_Click({
  Start-Process -WindowStyle Hidden "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', (Join-Path $script:Paths.Tools 'Setup_ScheduledTasks.ps1'), '-Disable') | Out-Null
  Start-Sleep 1; Refresh-AutoOps
})
$btnRunCleanup.Add_Click({ Start-ScheduledTask -TaskName 'Mason2-CleanupStages'; Start-Sleep 1; Refresh-AutoOps })
$btnRunVerify.Add_Click( { Start-ScheduledTask -TaskName 'Mason2-VerifyLatest';  Start-Sleep 1; Refresh-AutoOps })
$btnRunTrim.Add_Click(   { Start-ScheduledTask -TaskName 'Mason2-TrimReleases';  Start-Sleep 1; Refresh-AutoOps })
$btnRunApply.Add_Click(  { Start-ScheduledTask -TaskName 'Mason2-VerifyApply';   Start-Sleep 1; Refresh-AutoOps })
$btnClose.Add_Click(     { $w.Close() })

Refresh-AutoOps
$null = $w.ShowDialog()


# --- extra Auto-Ops buttons ---
$btnOpenReleases = $w.FindName('btnOpenReleases')
$btnOpenCurrent  = $w.FindName('btnOpenCurrent')
$btnRollback     = $w.FindName('btnRollback')

if($btnOpenReleases){ $btnOpenReleases.Add_Click({ Start-Process explorer.exe (Join-Path $script:Paths.Releases '.') }) }
if($btnOpenCurrent ){ $btnOpenCurrent.Add_Click( { Start-Process explorer.exe (Join-Path $script:Paths.Current  '.') }) }

if($btnRollback){
  $btnRollback.Add_Click({
    try{
      Start-Process -WindowStyle Hidden "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
        -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f (Join-Path $PSScriptRoot 'Rollback_Current.ps1')) | Out-Null
      Start-Sleep 1
      [System.Windows.MessageBox]::Show("Rollback attempted. Check 'dist\\current' and backups.","Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Auto Ops") | Out-Null
    }catch{
      [System.Windows.MessageBox]::Show($_.Exception.Message,"Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Auto Ops") | Out-Null
    }
  })
}
# --- end extra Auto-Ops buttons ---


_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot 'Common.ps1')

Add-Type -AssemblyName PresentationCore,PresentationFramework

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Auto Ops" Width="800" Height="520" WindowStartupLocation="CenterScreen" Background="#1e1e1e" Foreground="#e6e6e6">
  <Grid Margin="12">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
      <Button Name="btnEnable"  Content="Enable Auto-Ops"  Padding="10,6"/>
      <Button Name="btnDisable" Content="Disable Auto-Ops" Padding="10,6" Margin="8,0,0,0"/>
      <Button Name="btnRefresh" Content="Refresh"          Padding="10,6" Margin="16,0,0,0"/>
      <Button Name="btnOpenLogs" Content="Open Logs"       Padding="10,6" Margin="8,0,0,0"/>
    </StackPanel>

    <ListView Name="lv" Grid.Row="1" Margin="0,0,0,8" Background="#252526" Foreground="#e6e6e6" BorderBrush="#3c3c3c">
      <ListView.View>
        <GridView>
          <GridViewColumn Header="Task"     DisplayMemberBinding="{Binding TaskName}" Width="220"/>
          <GridViewColumn Header="State"    DisplayMemberBinding="{Binding State}" Width="100"/>
          <GridViewColumn Header="LastRun"  DisplayMemberBinding="{Binding LastRunTime}" Width="200"/>
          <GridViewColumn Header="Result"   DisplayMemberBinding="{Binding LastTaskResult}" Width="100"/>
          <GridViewColumn Header="NextRun"  DisplayMemberBinding="{Binding NextRunTime}" Width="200"/>
        </GridView>
      </ListView.View>
    </ListView>

    <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right">
      <Button Name="btnRunCleanup" Content="Run Cleanup"      Padding="12,6"/>
      <Button Name="btnRunVerify"  Content="Run VerifyLatest" Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnRunTrim"    Content="Run Trim"         Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnRunApply"   Content="Run Verify+Apply" Padding="12,6" Margin="8,0,0,0"/>
      
      <Button Name="btnOpenReleases" Content="Open Releases" Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnOpenCurrent"  Content="Open Current"  Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnRollback"     Content="Rollback"      Padding="12,6" Margin="8,0,0,0"/>
<Button Name="btnClose"      Content="Close"            Padding="12,6" Margin="8,0,0,0"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$w      = [Windows.Markup.XamlReader]::Load($reader)

$lv             = $w.FindName('lv')
$btnRefresh     = $w.FindName('btnRefresh')
$btnOpenLogs    = $w.FindName('btnOpenLogs')
$btnEnable      = $w.FindName('btnEnable')
$btnDisable     = $w.FindName('btnDisable')
$btnRunCleanup  = $w.FindName('btnRunCleanup')
$btnRunVerify   = $w.FindName('btnRunVerify')
$btnRunTrim     = $w.FindName('btnRunTrim')
$btnRunApply    = $w.FindName('btnRunApply')
$btnClose       = $w.FindName('btnClose')

$taskNames = 'Mason2-CleanupStages','Mason2-VerifyLatest','Mason2-TrimReleases','Mason2-VerifyApply'

function Refresh-AutoOps {
  $lv.Items.Clear()
  foreach($t in (Get-ScheduledTask -TaskName 'Mason2-*' | Where-Object { $taskNames -contains $_.TaskName })) {
    $i = $t | Get-ScheduledTaskInfo
    [void]$lv.Items.Add([pscustomobject]@{
      TaskName       = $t.TaskName
      State          = $t.State
      LastRunTime    = $i.LastRunTime
      LastTaskResult = $i.LastTaskResult
      NextRunTime    = $i.NextRunTime
    })
  }
}

$btnRefresh.Add_Click({ Refresh-AutoOps })
$btnOpenLogs.Add_Click({ Start-Process explorer.exe (Join-Path $script:Paths.Base 'reports') })
$btnEnable.Add_Click({
  Start-Process -WindowStyle Hidden "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', (Join-Path $script:Paths.Tools 'Setup_ScheduledTasks.ps1'), '-Enable') | Out-Null
  Start-Sleep 1; Refresh-AutoOps
})
$btnDisable.Add_Click({
  Start-Process -WindowStyle Hidden "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', (Join-Path $script:Paths.Tools 'Setup_ScheduledTasks.ps1'), '-Disable') | Out-Null
  Start-Sleep 1; Refresh-AutoOps
})
$btnRunCleanup.Add_Click({ Start-ScheduledTask -TaskName 'Mason2-CleanupStages'; Start-Sleep 1; Refresh-AutoOps })
$btnRunVerify.Add_Click( { Start-ScheduledTask -TaskName 'Mason2-VerifyLatest';  Start-Sleep 1; Refresh-AutoOps })
$btnRunTrim.Add_Click(   { Start-ScheduledTask -TaskName 'Mason2-TrimReleases';  Start-Sleep 1; Refresh-AutoOps })
$btnRunApply.Add_Click(  { Start-ScheduledTask -TaskName 'Mason2-VerifyApply';   Start-Sleep 1; Refresh-AutoOps })
$btnClose.Add_Click(     { $w.Close() })

Refresh-AutoOps
$null = $w.ShowDialog()


# --- extra Auto-Ops buttons ---
$btnOpenReleases = $w.FindName('btnOpenReleases')
$btnOpenCurrent  = $w.FindName('btnOpenCurrent')
$btnRollback     = $w.FindName('btnRollback')

if($btnOpenReleases){ $btnOpenReleases.Add_Click({ Start-Process explorer.exe (Join-Path $script:Paths.Releases '.') }) }
if($btnOpenCurrent ){ $btnOpenCurrent.Add_Click( { Start-Process explorer.exe (Join-Path $script:Paths.Current  '.') }) }

if($btnRollback){
  $btnRollback.Add_Click({
    try{
      Start-Process -WindowStyle Hidden "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
        -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f (Join-Path $PSScriptRoot 'Rollback_Current.ps1')) | Out-Null
      Start-Sleep 1
      [System.Windows.MessageBox]::Show("Rollback attempted. Check 'dist\\current' and backups.","Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Auto Ops") | Out-Null
    }catch{
      [System.Windows.MessageBox]::Show($_.Exception.Message,"Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Auto Ops") | Out-Null
    }
  })
}
# --- end extra Auto-Ops buttons ---


_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot 'Common.ps1')

Add-Type -AssemblyName PresentationCore,PresentationFramework

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Auto Ops" Width="800" Height="520" WindowStartupLocation="CenterScreen" Background="#1e1e1e" Foreground="#e6e6e6">
  <Grid Margin="12">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
      <Button Name="btnEnable"  Content="Enable Auto-Ops"  Padding="10,6"/>
      <Button Name="btnDisable" Content="Disable Auto-Ops" Padding="10,6" Margin="8,0,0,0"/>
      <Button Name="btnRefresh" Content="Refresh"          Padding="10,6" Margin="16,0,0,0"/>
      <Button Name="btnOpenLogs" Content="Open Logs"       Padding="10,6" Margin="8,0,0,0"/>
    </StackPanel>

    <ListView Name="lv" Grid.Row="1" Margin="0,0,0,8" Background="#252526" Foreground="#e6e6e6" BorderBrush="#3c3c3c">
      <ListView.View>
        <GridView>
          <GridViewColumn Header="Task"     DisplayMemberBinding="{Binding TaskName}" Width="220"/>
          <GridViewColumn Header="State"    DisplayMemberBinding="{Binding State}" Width="100"/>
          <GridViewColumn Header="LastRun"  DisplayMemberBinding="{Binding LastRunTime}" Width="200"/>
          <GridViewColumn Header="Result"   DisplayMemberBinding="{Binding LastTaskResult}" Width="100"/>
          <GridViewColumn Header="NextRun"  DisplayMemberBinding="{Binding NextRunTime}" Width="200"/>
        </GridView>
      </ListView.View>
    </ListView>

    <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right">
      <Button Name="btnRunCleanup" Content="Run Cleanup"      Padding="12,6"/>
      <Button Name="btnRunVerify"  Content="Run VerifyLatest" Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnRunTrim"    Content="Run Trim"         Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnRunApply"   Content="Run Verify+Apply" Padding="12,6" Margin="8,0,0,0"/>
      
      <Button Name="btnOpenReleases" Content="Open Releases" Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnOpenCurrent"  Content="Open Current"  Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnRollback"     Content="Rollback"      Padding="12,6" Margin="8,0,0,0"/>
<Button Name="btnClose"      Content="Close"            Padding="12,6" Margin="8,0,0,0"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$w      = [Windows.Markup.XamlReader]::Load($reader)

$lv             = $w.FindName('lv')
$btnRefresh     = $w.FindName('btnRefresh')
$btnOpenLogs    = $w.FindName('btnOpenLogs')
$btnEnable      = $w.FindName('btnEnable')
$btnDisable     = $w.FindName('btnDisable')
$btnRunCleanup  = $w.FindName('btnRunCleanup')
$btnRunVerify   = $w.FindName('btnRunVerify')
$btnRunTrim     = $w.FindName('btnRunTrim')
$btnRunApply    = $w.FindName('btnRunApply')
$btnClose       = $w.FindName('btnClose')

$taskNames = 'Mason2-CleanupStages','Mason2-VerifyLatest','Mason2-TrimReleases','Mason2-VerifyApply'

function Refresh-AutoOps {
  $lv.Items.Clear()
  foreach($t in (Get-ScheduledTask -TaskName 'Mason2-*' | Where-Object { $taskNames -contains $_.TaskName })) {
    $i = $t | Get-ScheduledTaskInfo
    [void]$lv.Items.Add([pscustomobject]@{
      TaskName       = $t.TaskName
      State          = $t.State
      LastRunTime    = $i.LastRunTime
      LastTaskResult = $i.LastTaskResult
      NextRunTime    = $i.NextRunTime
    })
  }
}

$btnRefresh.Add_Click({ Refresh-AutoOps })
$btnOpenLogs.Add_Click({ Start-Process explorer.exe (Join-Path $script:Paths.Base 'reports') })
$btnEnable.Add_Click({
  Start-Process -WindowStyle Hidden "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', (Join-Path $script:Paths.Tools 'Setup_ScheduledTasks.ps1'), '-Enable') | Out-Null
  Start-Sleep 1; Refresh-AutoOps
})
$btnDisable.Add_Click({
  Start-Process -WindowStyle Hidden "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', (Join-Path $script:Paths.Tools 'Setup_ScheduledTasks.ps1'), '-Disable') | Out-Null
  Start-Sleep 1; Refresh-AutoOps
})
$btnRunCleanup.Add_Click({ Start-ScheduledTask -TaskName 'Mason2-CleanupStages'; Start-Sleep 1; Refresh-AutoOps })
$btnRunVerify.Add_Click( { Start-ScheduledTask -TaskName 'Mason2-VerifyLatest';  Start-Sleep 1; Refresh-AutoOps })
$btnRunTrim.Add_Click(   { Start-ScheduledTask -TaskName 'Mason2-TrimReleases';  Start-Sleep 1; Refresh-AutoOps })
$btnRunApply.Add_Click(  { Start-ScheduledTask -TaskName 'Mason2-VerifyApply';   Start-Sleep 1; Refresh-AutoOps })
$btnClose.Add_Click(     { $w.Close() })

Refresh-AutoOps
$null = $w.ShowDialog()


# --- extra Auto-Ops buttons ---
$btnOpenReleases = $w.FindName('btnOpenReleases')
$btnOpenCurrent  = $w.FindName('btnOpenCurrent')
$btnRollback     = $w.FindName('btnRollback')

if($btnOpenReleases){ $btnOpenReleases.Add_Click({ Start-Process explorer.exe (Join-Path $script:Paths.Releases '.') }) }
if($btnOpenCurrent ){ $btnOpenCurrent.Add_Click( { Start-Process explorer.exe (Join-Path $script:Paths.Current  '.') }) }

if($btnRollback){
  $btnRollback.Add_Click({
    try{
      Start-Process -WindowStyle Hidden "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
        -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f (Join-Path $PSScriptRoot 'Rollback_Current.ps1')) | Out-Null
      Start-Sleep 1
      [System.Windows.MessageBox]::Show("Rollback attempted. Check 'dist\\current' and backups.","Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Auto Ops") | Out-Null
    }catch{
      [System.Windows.MessageBox]::Show($_.Exception.Message,"Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Auto Ops") | Out-Null
    }
  })
}
# --- end extra Auto-Ops buttons ---


_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot 'Common.ps1')

Add-Type -AssemblyName PresentationCore,PresentationFramework

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Auto Ops" Width="800" Height="520" WindowStartupLocation="CenterScreen" Background="#1e1e1e" Foreground="#e6e6e6">
  <Grid Margin="12">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
      <Button Name="btnEnable"  Content="Enable Auto-Ops"  Padding="10,6"/>
      <Button Name="btnDisable" Content="Disable Auto-Ops" Padding="10,6" Margin="8,0,0,0"/>
      <Button Name="btnRefresh" Content="Refresh"          Padding="10,6" Margin="16,0,0,0"/>
      <Button Name="btnOpenLogs" Content="Open Logs"       Padding="10,6" Margin="8,0,0,0"/>
    </StackPanel>

    <ListView Name="lv" Grid.Row="1" Margin="0,0,0,8" Background="#252526" Foreground="#e6e6e6" BorderBrush="#3c3c3c">
      <ListView.View>
        <GridView>
          <GridViewColumn Header="Task"     DisplayMemberBinding="{Binding TaskName}" Width="220"/>
          <GridViewColumn Header="State"    DisplayMemberBinding="{Binding State}" Width="100"/>
          <GridViewColumn Header="LastRun"  DisplayMemberBinding="{Binding LastRunTime}" Width="200"/>
          <GridViewColumn Header="Result"   DisplayMemberBinding="{Binding LastTaskResult}" Width="100"/>
          <GridViewColumn Header="NextRun"  DisplayMemberBinding="{Binding NextRunTime}" Width="200"/>
        </GridView>
      </ListView.View>
    </ListView>

    <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right">
      <Button Name="btnRunCleanup" Content="Run Cleanup"      Padding="12,6"/>
      <Button Name="btnRunVerify"  Content="Run VerifyLatest" Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnRunTrim"    Content="Run Trim"         Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnRunApply"   Content="Run Verify+Apply" Padding="12,6" Margin="8,0,0,0"/>
      
      <Button Name="btnOpenReleases" Content="Open Releases" Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnOpenCurrent"  Content="Open Current"  Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnRollback"     Content="Rollback"      Padding="12,6" Margin="8,0,0,0"/>
<Button Name="btnClose"      Content="Close"            Padding="12,6" Margin="8,0,0,0"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$w      = [Windows.Markup.XamlReader]::Load($reader)

$lv             = $w.FindName('lv')
$btnRefresh     = $w.FindName('btnRefresh')
$btnOpenLogs    = $w.FindName('btnOpenLogs')
$btnEnable      = $w.FindName('btnEnable')
$btnDisable     = $w.FindName('btnDisable')
$btnRunCleanup  = $w.FindName('btnRunCleanup')
$btnRunVerify   = $w.FindName('btnRunVerify')
$btnRunTrim     = $w.FindName('btnRunTrim')
$btnRunApply    = $w.FindName('btnRunApply')
$btnClose       = $w.FindName('btnClose')

$taskNames = 'Mason2-CleanupStages','Mason2-VerifyLatest','Mason2-TrimReleases','Mason2-VerifyApply'

function Refresh-AutoOps {
  $lv.Items.Clear()
  foreach($t in (Get-ScheduledTask -TaskName 'Mason2-*' | Where-Object { $taskNames -contains $_.TaskName })) {
    $i = $t | Get-ScheduledTaskInfo
    [void]$lv.Items.Add([pscustomobject]@{
      TaskName       = $t.TaskName
      State          = $t.State
      LastRunTime    = $i.LastRunTime
      LastTaskResult = $i.LastTaskResult
      NextRunTime    = $i.NextRunTime
    })
  }
}

$btnRefresh.Add_Click({ Refresh-AutoOps })
$btnOpenLogs.Add_Click({ Start-Process explorer.exe (Join-Path $script:Paths.Base 'reports') })
$btnEnable.Add_Click({
  Start-Process -WindowStyle Hidden "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', (Join-Path $script:Paths.Tools 'Setup_ScheduledTasks.ps1'), '-Enable') | Out-Null
  Start-Sleep 1; Refresh-AutoOps
})
$btnDisable.Add_Click({
  Start-Process -WindowStyle Hidden "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', (Join-Path $script:Paths.Tools 'Setup_ScheduledTasks.ps1'), '-Disable') | Out-Null
  Start-Sleep 1; Refresh-AutoOps
})
$btnRunCleanup.Add_Click({ Start-ScheduledTask -TaskName 'Mason2-CleanupStages'; Start-Sleep 1; Refresh-AutoOps })
$btnRunVerify.Add_Click( { Start-ScheduledTask -TaskName 'Mason2-VerifyLatest';  Start-Sleep 1; Refresh-AutoOps })
$btnRunTrim.Add_Click(   { Start-ScheduledTask -TaskName 'Mason2-TrimReleases';  Start-Sleep 1; Refresh-AutoOps })
$btnRunApply.Add_Click(  { Start-ScheduledTask -TaskName 'Mason2-VerifyApply';   Start-Sleep 1; Refresh-AutoOps })
$btnClose.Add_Click(     { $w.Close() })

Refresh-AutoOps
$null = $w.ShowDialog()


# --- extra Auto-Ops buttons ---
$btnOpenReleases = $w.FindName('btnOpenReleases')
$btnOpenCurrent  = $w.FindName('btnOpenCurrent')
$btnRollback     = $w.FindName('btnRollback')

if($btnOpenReleases){ $btnOpenReleases.Add_Click({ Start-Process explorer.exe (Join-Path $script:Paths.Releases '.') }) }
if($btnOpenCurrent ){ $btnOpenCurrent.Add_Click( { Start-Process explorer.exe (Join-Path $script:Paths.Current  '.') }) }

if($btnRollback){
  $btnRollback.Add_Click({
    try{
      Start-Process -WindowStyle Hidden "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
        -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f (Join-Path $PSScriptRoot 'Rollback_Current.ps1')) | Out-Null
      Start-Sleep 1
      [System.Windows.MessageBox]::Show("Rollback attempted. Check 'dist\\current' and backups.","Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Auto Ops") | Out-Null
    }catch{
      [System.Windows.MessageBox]::Show($_.Exception.Message,"Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Auto Ops") | Out-Null
    }
  })
}
# --- end extra Auto-Ops buttons ---


_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot 'Common.ps1')

Add-Type -AssemblyName PresentationCore,PresentationFramework

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Auto Ops" Width="800" Height="520" WindowStartupLocation="CenterScreen" Background="#1e1e1e" Foreground="#e6e6e6">
  <Grid Margin="12">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
      <Button Name="btnEnable"  Content="Enable Auto-Ops"  Padding="10,6"/>
      <Button Name="btnDisable" Content="Disable Auto-Ops" Padding="10,6" Margin="8,0,0,0"/>
      <Button Name="btnRefresh" Content="Refresh"          Padding="10,6" Margin="16,0,0,0"/>
      <Button Name="btnOpenLogs" Content="Open Logs"       Padding="10,6" Margin="8,0,0,0"/>
    </StackPanel>

    <ListView Name="lv" Grid.Row="1" Margin="0,0,0,8" Background="#252526" Foreground="#e6e6e6" BorderBrush="#3c3c3c">
      <ListView.View>
        <GridView>
          <GridViewColumn Header="Task"     DisplayMemberBinding="{Binding TaskName}" Width="220"/>
          <GridViewColumn Header="State"    DisplayMemberBinding="{Binding State}" Width="100"/>
          <GridViewColumn Header="LastRun"  DisplayMemberBinding="{Binding LastRunTime}" Width="200"/>
          <GridViewColumn Header="Result"   DisplayMemberBinding="{Binding LastTaskResult}" Width="100"/>
          <GridViewColumn Header="NextRun"  DisplayMemberBinding="{Binding NextRunTime}" Width="200"/>
        </GridView>
      </ListView.View>
    </ListView>

    <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right">
      <Button Name="btnRunCleanup" Content="Run Cleanup"      Padding="12,6"/>
      <Button Name="btnRunVerify"  Content="Run VerifyLatest" Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnRunTrim"    Content="Run Trim"         Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnRunApply"   Content="Run Verify+Apply" Padding="12,6" Margin="8,0,0,0"/>
      
      <Button Name="btnOpenReleases" Content="Open Releases" Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnOpenCurrent"  Content="Open Current"  Padding="12,6" Margin="8,0,0,0"/>
      <Button Name="btnRollback"     Content="Rollback"      Padding="12,6" Margin="8,0,0,0"/>
<Button Name="btnClose"      Content="Close"            Padding="12,6" Margin="8,0,0,0"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$w      = [Windows.Markup.XamlReader]::Load($reader)

$lv             = $w.FindName('lv')
$btnRefresh     = $w.FindName('btnRefresh')
$btnOpenLogs    = $w.FindName('btnOpenLogs')
$btnEnable      = $w.FindName('btnEnable')
$btnDisable     = $w.FindName('btnDisable')
$btnRunCleanup  = $w.FindName('btnRunCleanup')
$btnRunVerify   = $w.FindName('btnRunVerify')
$btnRunTrim     = $w.FindName('btnRunTrim')
$btnRunApply    = $w.FindName('btnRunApply')
$btnClose       = $w.FindName('btnClose')

$taskNames = 'Mason2-CleanupStages','Mason2-VerifyLatest','Mason2-TrimReleases','Mason2-VerifyApply'

function Refresh-AutoOps {
  $lv.Items.Clear()
  foreach($t in (Get-ScheduledTask -TaskName 'Mason2-*' | Where-Object { $taskNames -contains $_.TaskName })) {
    $i = $t | Get-ScheduledTaskInfo
    [void]$lv.Items.Add([pscustomobject]@{
      TaskName       = $t.TaskName
      State          = $t.State
      LastRunTime    = $i.LastRunTime
      LastTaskResult = $i.LastTaskResult
      NextRunTime    = $i.NextRunTime
    })
  }
}

$btnRefresh.Add_Click({ Refresh-AutoOps })
$btnOpenLogs.Add_Click({ Start-Process explorer.exe (Join-Path $script:Paths.Base 'reports') })
$btnEnable.Add_Click({
  Start-Process -WindowStyle Hidden "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', (Join-Path $script:Paths.Tools 'Setup_ScheduledTasks.ps1'), '-Enable') | Out-Null
  Start-Sleep 1; Refresh-AutoOps
})
$btnDisable.Add_Click({
  Start-Process -WindowStyle Hidden "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', (Join-Path $script:Paths.Tools 'Setup_ScheduledTasks.ps1'), '-Disable') | Out-Null
  Start-Sleep 1; Refresh-AutoOps
})
$btnRunCleanup.Add_Click({ Start-ScheduledTask -TaskName 'Mason2-CleanupStages'; Start-Sleep 1; Refresh-AutoOps })
$btnRunVerify.Add_Click( { Start-ScheduledTask -TaskName 'Mason2-VerifyLatest';  Start-Sleep 1; Refresh-AutoOps })
$btnRunTrim.Add_Click(   { Start-ScheduledTask -TaskName 'Mason2-TrimReleases';  Start-Sleep 1; Refresh-AutoOps })
$btnRunApply.Add_Click(  { Start-ScheduledTask -TaskName 'Mason2-VerifyApply';   Start-Sleep 1; Refresh-AutoOps })
$btnClose.Add_Click(     { $w.Close() })

Refresh-AutoOps
$null = $w.ShowDialog()


# --- extra Auto-Ops buttons ---
$btnOpenReleases = $w.FindName('btnOpenReleases')
$btnOpenCurrent  = $w.FindName('btnOpenCurrent')
$btnRollback     = $w.FindName('btnRollback')

if($btnOpenReleases){ $btnOpenReleases.Add_Click({ Start-Process explorer.exe (Join-Path $script:Paths.Releases '.') }) }
if($btnOpenCurrent ){ $btnOpenCurrent.Add_Click( { Start-Process explorer.exe (Join-Path $script:Paths.Current  '.') }) }

if($btnRollback){
  $btnRollback.Add_Click({
    try{
      Start-Process -WindowStyle Hidden "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
        -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f (Join-Path $PSScriptRoot 'Rollback_Current.ps1')) | Out-Null
      Start-Sleep 1
      [System.Windows.MessageBox]::Show("Rollback attempted. Check 'dist\\current' and backups.","Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Auto Ops") | Out-Null
    }catch{
      [System.Windows.MessageBox]::Show($_.Exception.Message,"Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Auto Ops") | Out-Null
    }
  })
}
# --- end extra Auto-Ops buttons ---


