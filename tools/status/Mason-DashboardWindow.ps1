# --- single-instance guard ---
Add-Type -AssemblyName System.Threading
$global:__masonMutex = [System.Threading.Mutex]::new($false,'Global\MasonDashboardMutex')
if(-not $global:__masonMutex.WaitOne(0)){
  # already running â€” bail without error
  return
}
$null = Register-EngineEvent PowerShell.Exiting -Action {
  try{ $global:__masonMutex.ReleaseMutex() }catch{}
  try{ $global:__masonMutex.Dispose() }catch{}
}
# --- end guard ---
Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase
# --- single-instance guard ---
\ = \False
\ = New-Object System.Threading.Mutex(\False,'Global\MasonDashboard',[ref]\)
if(-not \){ return }  # another dashboard is already running
$ErrorActionPreference = "Stop"

$base = $env:MASON2_BASE
$rep  = Join-Path $base "reports"
$ctl  = Join-Path $base "control"
New-Item -ItemType Directory -Force $rep,$ctl | Out-Null

function Read-Json([string]$path) {
  try { if (Test-Path $path) { Get-Content $path -Raw -EA Stop | ConvertFrom-Json } else { $null } }
  catch { $null }
}
function Is-Admin {
  $wi = [Security.Principal.WindowsIdentity]::GetCurrent()
  (New-Object Security.Principal.WindowsPrincipal $wi).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
function Require-Admin {
  if (-not (Is-Admin)) {
    [System.Windows.MessageBox]::Show("This action needs Administrator. The dashboard will relaunch elevated.","Mason",0,48) | Out-Null
    $me = $MyInvocation.MyCommand.Path
    Start-Process powershell -Verb RunAs -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-File","`"$me`"")
    $Window.Close() | Out-Null
    return $false
  }
  return $true
}

# Colors (dark)
$BG        = "#0E1117"
$CardBG    = "#151A23"
$CardBorder= "#2A2F3A"
$FG        = "#E7E9EA"
$Muted     = "#B7BDC6"
$Green     = "#1F8A3A"
$Amber     = "#A97319"
$Red       = "#B13131"
$Gray      = "#333843"

[xml]$x = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Mason Dashboard" Width="900" Height="620"
        WindowStartupLocation="CenterScreen" Background="$BG" Foreground="$FG" FontFamily="Segoe UI">
  <Grid Margin="16">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <!-- Header -->
    <Border Grid.Row="0" Background="$CardBG" CornerRadius="12" Padding="14" BorderBrush="$CardBorder" BorderThickness="1">
      <Border.Effect><DropShadowEffect BlurRadius="12" ShadowDepth="0" Opacity="0.35"/></Border.Effect>
      <DockPanel LastChildFill="False">
        <TextBlock Text="Mason" FontSize="24" FontWeight="SemiBold" Margin="0,0,12,0" VerticalAlignment="Center"/>
        <Border x:Name="StatusPill" CornerRadius="10" Padding="10,4" Background="$Gray" VerticalAlignment="Center">
          <TextBlock x:Name="StatusText" Text="Status: -" FontSize="12"/>
        </Border>
        <TextBlock Text=" " Width="8"/>
        <TextBlock x:Name="TsText"  Text="ts: -"  FontSize="12" Foreground="$Muted" VerticalAlignment="Center"/>
        <TextBlock Text=" " Width="8"/>
        <TextBlock x:Name="HudText" Text="hud: -" FontSize="12" Foreground="$Muted" VerticalAlignment="Center"/>
      </DockPanel>
    </Border>

    <!-- Stats row -->
    <Border Grid.Row="1" Background="$CardBG" CornerRadius="12" Padding="10" Margin="0,12,0,0" BorderBrush="$CardBorder" BorderThickness="1">
      <Border.Effect><DropShadowEffect BlurRadius="12" ShadowDepth="0" Opacity="0.35"/></Border.Effect>
      <WrapPanel ItemHeight="28" ItemWidth="180">
        <Border CornerRadius="10" Padding="10,6" Margin="0,0,8,8" Background="#1E2430" BorderBrush="$CardBorder" BorderThickness="1"><TextBlock x:Name="CpuChipText"   Text="CPU: -"  /></Border>
        <Border CornerRadius="10" Padding="10,6" Margin="0,0,8,8" Background="#1E2430" BorderBrush="$CardBorder" BorderThickness="1"><TextBlock x:Name="MemChipText"   Text="RAM: -"  /></Border>
        <Border CornerRadius="10" Padding="10,6" Margin="0,0,8,8" Background="#1E2430" BorderBrush="$CardBorder" BorderThickness="1"><TextBlock x:Name="DiskChipText"  Text="C: - free" /></Border>
        <Border CornerRadius="10" Padding="10,6" Margin="0,0,8,8" Background="#1E2430" BorderBrush="$CardBorder" BorderThickness="1"><TextBlock x:Name="TasksChipText" Text="Tasks: -/-" /></Border>
      </WrapPanel>
    </Border>

    <!-- Actions -->
    <Border Grid.Row="2" Background="$CardBG" CornerRadius="12" Padding="10" Margin="0,12,0,12" BorderBrush="$CardBorder" BorderThickness="1">
      <Border.Effect><DropShadowEffect BlurRadius="12" ShadowDepth="0" Opacity="0.35"/></Border.Effect>
      <WrapPanel ItemHeight="32" ItemWidth="220">
        <Button x:Name="RefreshBtn"      Content="Refresh Now"                       Margin="0,0,8,8" Padding="14,6"/>
        <Button x:Name="OpenLogsBtn"     Content="Open Logs Folder"                  Margin="0,0,8,8" Padding="14,6"/>
        <Button x:Name="ToggleFreezeBtn" Content="Toggle Freeze (admin)"             Margin="0,0,8,8" Padding="14,6"/>
        <Button x:Name="KillAllBtn"      Content="Soft Kill-All Mason Tasks (admin)" Margin="0,0,8,8" Padding="14,6"/>
      </WrapPanel>
    </Border>

    <!-- Main split -->
    <Grid Grid.Row="3">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="2*"/>
        <ColumnDefinition Width="3*"/>
      </Grid.ColumnDefinitions>

      <!-- Status card -->
      <Border Grid.Column="0" Background="$CardBG" CornerRadius="12" Padding="10" Margin="0,0,12,0" BorderBrush="$CardBorder" BorderThickness="1">
        <Border.Effect><DropShadowEffect BlurRadius="12" ShadowDepth="0" Opacity="0.35"/></Border.Effect>
        <StackPanel>
          <TextBlock Text="Status" FontWeight="SemiBold" Opacity="0.85" Margin="2,0,0,8"/>
          <TextBlock x:Name="ColorText" Text="color: -" Margin="0,0,0,6"/>
          <ItemsControl x:Name="ReasonsList">
            <ItemsControl.ItemTemplate>
              <DataTemplate>
                <StackPanel Orientation="Horizontal">
                  <TextBlock Text="-  "/>
                  <TextBlock Text="{Binding Path=., Mode=OneWay}" TextWrapping="Wrap"/>
                </StackPanel>
              </DataTemplate>
            </ItemsControl.ItemTemplate>
          </ItemsControl>
        </StackPanel>
      </Border>

      <!-- Alerts tail -->
      <Border Grid.Column="1" Background="$CardBG" CornerRadius="12" Padding="10" BorderBrush="$CardBorder" BorderThickness="1">
        <Border.Effect><DropShadowEffect BlurRadius="12" ShadowDepth="0" Opacity="0.35"/></Border.Effect>
        <DockPanel>
          <TextBlock Text="Recent Alerts (tail)" FontWeight="SemiBold" Opacity="0.85" Margin="2,0,0,8" DockPanel.Dock="Top"/>
          <ScrollViewer VerticalScrollBarVisibility="Auto">
            <TextBox x:Name="AlertsTail" IsReadOnly="True" TextWrapping="Wrap" AcceptsReturn="True"
                     Background="#0D0F14" BorderBrush="$CardBorder" FontFamily="Consolas" FontSize="12"/>
          </ScrollViewer>
        </DockPanel>
      </Border>
    </Grid>

    <!-- Footer -->
    <DockPanel Grid.Row="4" Margin="0,12,0,0">
      <TextBlock Text="Base:" Opacity="0.7"/>
      <TextBlock x:Name="BasePathText" Margin="6,0,0,0"/>
      <TextBlock Text="  |  " Margin="8,0"/>
      <TextBlock Text="Tip: admin actions will auto-prompt for elevation." Opacity="0.7"/>
    </DockPanel>
  </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $x)
$Window = [Windows.Markup.XamlReader]::Load($reader)

# Handles
$StatusPill   = $Window.FindName("StatusPill")
$StatusText   = $Window.FindName("StatusText")
$TsText       = $Window.FindName("TsText")
$HudText      = $Window.FindName("HudText")
$ColorText    = $Window.FindName("ColorText")
$ReasonsList  = $Window.FindName("ReasonsList")
$AlertsTail   = $Window.FindName("AlertsTail")
$RefreshBtn   = $Window.FindName("RefreshBtn")
$OpenLogsBtn  = $Window.FindName("OpenLogsBtn")
$ToggleFreezeBtn = $Window.FindName("ToggleFreezeBtn")
$KillAllBtn   = $Window.FindName("KillAllBtn")
$BasePathText = $Window.FindName("BasePathText")
$BasePathText.Text = $base

$CpuChipText   = $Window.FindName("CpuChipText")
$MemChipText   = $Window.FindName("MemChipText")
$DiskChipText  = $Window.FindName("DiskChipText")
$TasksChipText = $Window.FindName("TasksChipText")

function Set-Pill([string]$color) {
  $map = @{ GREEN="#1F8A3A"; AMBER="#A97319"; RED="#B13131"; GRAY="#333843" }
  $hex = $map[$color.ToUpper()]; if (-not $hex) { $hex = $map.GRAY }
  $StatusPill.Background = [Windows.Media.BrushConverter]::new().ConvertFromString($hex)
  $StatusText.Text = "Status: " + $color
}

function Get-QuickStats {
  # CPU
  $cpuAvg = (Get-CimInstance Win32_Processor -EA SilentlyContinue | Measure-Object -Property LoadPercentage -Average).Average
  if ($null -eq $cpuAvg) { $cpuAvg = 0 }
  $cpu = [int]$cpuAvg

  # RAM
  $os = Get-CimInstance Win32_OperatingSystem -EA SilentlyContinue
  if ($os) {
    $tot = [double]$os.TotalVisibleMemorySize * 1024
    $fre = [double]$os.FreePhysicalMemory      * 1024
    $ram = if ($tot -gt 0) { [int]([math]::Round((($tot - $fre)/$tot)*100)) } else { 0 }
  } else { $ram = 0 }

  # Disk C:
  try {
    $d = Get-PSDrive -Name C -EA Stop
    $diskFreePct = if ($d.Maximum -gt 0) { [int]([math]::Round(($d.Free/$d.Maximum)*100)) } else { 0 }
  } catch { $diskFreePct = 0 }

  # Task health
  $tasks = Get-ScheduledTask -TaskName "Mason-*" -EA SilentlyContinue
  $running = ($tasks | Where-Object { $_.State -eq "Running" }).Count
  $total   = $tasks.Count

  [pscustomobject]@{
    CPU   = $cpu
    RAM   = $ram
    DiskC = $diskFreePct
    Tasks = "$running/$total"
  }
}

function Refresh-All {
  $dash = Read-Json (Join-Path $rep "dashboard.json")
  $hud  = Read-Json (Join-Path $rep "hud.json")
  $stat = Read-Json (Join-Path $rep "status.json")

  if ($dash) { $TsText.Text = ("ts: {0}" -f $dash.ts) } else { $TsText.Text = "ts: -" }
  if ($hud)  { $HudText.Text = ("hud: uptime_s={0}, alive={1}" -f $hud.uptime_s, $hud.alive) } else { $HudText.Text = "hud: -" }

  $color = "GRAY"
  if ($stat -and $stat.color) { $color = $stat.color }
  Set-Pill $color
  $ColorText.Text = ("color: {0}" -f $color)

  $ReasonsList.ItemsSource = $null
  if ($stat -and $stat.reasons) { $ReasonsList.ItemsSource = $stat.reasons }

  $alerts = Join-Path $rep "alerts.jsonl"
  if (Test-Path $alerts) {
    $lines = Get-Content $alerts -Tail 50 -EA SilentlyContinue
    $AlertsTail.Text = ($lines -join [Environment]::NewLine)
  } else {
    $AlertsTail.Text = ""
  }

  $qs = Get-QuickStats
  $CpuChipText.Text   = "CPU: {0}%" -f $qs.CPU
  $MemChipText.Text   = "RAM: {0}%" -f $qs.RAM
  $DiskChipText.Text  = "C: {0}% free" -f $qs.DiskC
  $TasksChipText.Text = "Tasks: {0}" -f $qs.Tasks
}

# Buttons
$RefreshBtn.Add_Click({ Refresh-All })
$OpenLogsBtn.Add_Click({ if (Test-Path $rep) { Start-Process explorer.exe $rep } })
$ToggleFreezeBtn.Add_Click({
  if (-not (Require-Admin)) { return }
  $flag = Join-Path $ctl "FREEZE.on"
  if (Test-Path $flag) { Remove-Item $flag -Force } else { New-Item -ItemType File -Force $flag | Out-Null }
  [System.Windows.MessageBox]::Show(("Freeze flag is now: {0}" -f (Test-Path $flag)),"Mason") | Out-Null
})
$KillAllBtn.Add_Click({
  if (-not (Require-Admin)) { return }
  $keep = @("Mason-DashboardUI","Mason-KillSwitchHotkey","Mason-NormalizeTasks")
  $tasks = Get-ScheduledTask -TaskName "Mason-*" -EA SilentlyContinue
  foreach ($t in $tasks) {
    if ($keep -contains $t.TaskName) { continue }
    try { Stop-ScheduledTask -TaskName $t.TaskName -EA SilentlyContinue } catch {}
    try { Disable-ScheduledTask -TaskName $t.TaskName -EA SilentlyContinue } catch {}
  }
  New-Item -ItemType File -Force (Join-Path $ctl "KILL.now") | Out-Null
  [System.Windows.MessageBox]::Show("Kill issued. Mason tasks stopped/disabled (except keep-list).","Mason") | Out-Null
  Refresh-All
})

# Auto-refresh
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(3)
$timer.Add_Tick({ Refresh-All })
$timer.Start()

Refresh-All
$Window.ShowDialog() | Out-Null