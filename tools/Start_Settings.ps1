# Stamped: 2025-11-05T17:02:01
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot 'Common.ps1')

Add-Type -AssemblyName PresentationCore,PresentationFramework
$cfgPath = Join-Path $script:Paths.Base 'config\mason2.config.json'
New-Item -ItemType Directory -Force -Path (Split-Path $cfgPath) | Out-Null

function Load-Config {
  if(Test-Path $cfgPath){ Get-Content $cfgPath -Raw | ConvertFrom-Json } else { Read-Config }
}
function Save-Config([object]$obj){
  $obj | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 $cfgPath
}

[xml]$x = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Settings" Width="560" Height="480" WindowStartupLocation="CenterScreen">
  <Grid Margin="12">
    <Grid.RowDefinitions>
      <RowDefinition Height="*"/><RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <StackPanel>
      <TextBlock Text="Environment" FontWeight="Bold"/>
      <ComboBox Name="cbEnv" Margin="0,4,0,10">
        <ComboBoxItem Content="dev"/>
        <ComboBoxItem Content="strict"/>
      </ComboBox>

      <TextBlock Text="Verify Mode" FontWeight="Bold"/>
      <ComboBox Name="cbVerify" Margin="0,4,0,10">
        <ComboBoxItem Content="dev"/>
        <ComboBoxItem Content="strict"/>
      </ComboBox>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="CleanupDays" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtCleanupDays" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="KeepTopN" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtKeepN" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="CleanupEveryHours" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtCleanH" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="VerifyEveryHours" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtVerifyH" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="NightlyTrimAt (HH:mm)" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtTrimAt" Width="100"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="NightlyApplyAt (HH:mm)" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtApplyAt" Width="100"/>
      </StackPanel>

      <CheckBox Name="chkUseFolderTime" Content="UseFolderTime for cleanup" Margin="0,6,0,0"/>
    </StackPanel>

    <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Right">
      <Button Name="btnSave" Content="Save" Padding="12,6"/>
      <Button Name="btnClose" Content="Close" Padding="12,6" Margin="8,0,0,0"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $x
$w      = [Windows.Markup.XamlReader]::Load($reader)

$cbEnv = $w.FindName('cbEnv')
$cbVerify = $w.FindName('cbVerify')
$txtCleanupDays = $w.FindName('txtCleanupDays')
$txtKeepN = $w.FindName('txtKeepN')
$txtCleanH = $w.FindName('txtCleanH')
$txtVerifyH = $w.FindName('txtVerifyH')
$txtTrimAt = $w.FindName('txtTrimAt')
$txtApplyAt = $w.FindName('txtApplyAt')
$chkUseFolderTime = $w.FindName('chkUseFolderTime')
$btnSave = $w.FindName('btnSave')
$btnClose = $w.FindName('btnClose')

function Select-ByContent($combo,[string]$val){
  foreach($i in $combo.Items){ if($i.Content -eq $val){ $combo.SelectedItem = $i; break } }
}

$cfg = Load-Config
Select-ByContent $cbEnv    ([string]$cfg.Env)
Select-ByContent $cbVerify ([string]$cfg.VerifyMode)
$txtCleanupDays.Text = [string]$cfg.CleanupDays
$txtKeepN.Text       = [string]$cfg.KeepTopN
$txtCleanH.Text      = [string]$cfg.Auto.CleanupEveryHours
$txtVerifyH.Text     = [string]$cfg.Auto.VerifyEveryHours
$txtTrimAt.Text      = [string]$cfg.Auto.NightlyTrimAt
$txtApplyAt.Text     = [string]$cfg.Auto.NightlyApplyAt
$chkUseFolderTime.IsChecked = [bool]$cfg.UseFolderTime

$btnSave.Add_Click({
  try{
    if($txtTrimAt.Text -notmatch '^\d{2}:\d{2}$'){ throw "NightlyTrimAt must be HH:mm" }
    if($txtApplyAt.Text -notmatch '^\d{2}:\d{2}$'){ throw "NightlyApplyAt must be HH:mm" }
    $cfg.Env         = ($cbEnv.SelectedItem).Content
    $cfg.VerifyMode  = ($cbVerify.SelectedItem).Content
    $cfg.CleanupDays = [int]$txtCleanupDays.Text
    $cfg.KeepTopN    = [int]$txtKeepN.Text
    $cfg.UseFolderTime = [bool]$chkUseFolderTime.IsChecked
    $cfg.Auto.CleanupEveryHours = [int]$txtCleanH.Text
    $cfg.Auto.VerifyEveryHours  = [int]$txtVerifyH.Text
    $cfg.Auto.NightlyTrimAt     = $txtTrimAt.Text
    $cfg.Auto.NightlyApplyAt    = $txtApplyAt.Text
    Save-Config $cfg
    [System.Windows.MessageBox]::Show("Saved to `n$cfgPath","Mason2 Settings") | Out-Null
  }catch{
    [System.Windows.MessageBox]::Show($_.Exception.Message,"Mason2 Settings") | Out-Null
  }
})
$btnClose.Add_Click({ $w.Close() })

$null = $w.ShowDialog()

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
$cfgPath = Join-Path $script:Paths.Base 'config\mason2.config.json'
New-Item -ItemType Directory -Force -Path (Split-Path $cfgPath) | Out-Null

function Load-Config {
  if(Test-Path $cfgPath){ Get-Content $cfgPath -Raw | ConvertFrom-Json } else { Read-Config }
}
function Save-Config([object]$obj){
  $obj | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 $cfgPath
}

[xml]$x = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Settings" Width="560" Height="480" WindowStartupLocation="CenterScreen">
  <Grid Margin="12">
    <Grid.RowDefinitions>
      <RowDefinition Height="*"/><RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <StackPanel>
      <TextBlock Text="Environment" FontWeight="Bold"/>
      <ComboBox Name="cbEnv" Margin="0,4,0,10">
        <ComboBoxItem Content="dev"/>
        <ComboBoxItem Content="strict"/>
      </ComboBox>

      <TextBlock Text="Verify Mode" FontWeight="Bold"/>
      <ComboBox Name="cbVerify" Margin="0,4,0,10">
        <ComboBoxItem Content="dev"/>
        <ComboBoxItem Content="strict"/>
      </ComboBox>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="CleanupDays" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtCleanupDays" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="KeepTopN" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtKeepN" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="CleanupEveryHours" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtCleanH" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="VerifyEveryHours" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtVerifyH" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="NightlyTrimAt (HH:mm)" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtTrimAt" Width="100"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="NightlyApplyAt (HH:mm)" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtApplyAt" Width="100"/>
      </StackPanel>

      <CheckBox Name="chkUseFolderTime" Content="UseFolderTime for cleanup" Margin="0,6,0,0"/>
    </StackPanel>

    <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Right">
      <Button Name="btnSave" Content="Save" Padding="12,6"/>
      <Button Name="btnClose" Content="Close" Padding="12,6" Margin="8,0,0,0"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $x
$w      = [Windows.Markup.XamlReader]::Load($reader)

$cbEnv = $w.FindName('cbEnv')
$cbVerify = $w.FindName('cbVerify')
$txtCleanupDays = $w.FindName('txtCleanupDays')
$txtKeepN = $w.FindName('txtKeepN')
$txtCleanH = $w.FindName('txtCleanH')
$txtVerifyH = $w.FindName('txtVerifyH')
$txtTrimAt = $w.FindName('txtTrimAt')
$txtApplyAt = $w.FindName('txtApplyAt')
$chkUseFolderTime = $w.FindName('chkUseFolderTime')
$btnSave = $w.FindName('btnSave')
$btnClose = $w.FindName('btnClose')

function Select-ByContent($combo,[string]$val){
  foreach($i in $combo.Items){ if($i.Content -eq $val){ $combo.SelectedItem = $i; break } }
}

$cfg = Load-Config
Select-ByContent $cbEnv    ([string]$cfg.Env)
Select-ByContent $cbVerify ([string]$cfg.VerifyMode)
$txtCleanupDays.Text = [string]$cfg.CleanupDays
$txtKeepN.Text       = [string]$cfg.KeepTopN
$txtCleanH.Text      = [string]$cfg.Auto.CleanupEveryHours
$txtVerifyH.Text     = [string]$cfg.Auto.VerifyEveryHours
$txtTrimAt.Text      = [string]$cfg.Auto.NightlyTrimAt
$txtApplyAt.Text     = [string]$cfg.Auto.NightlyApplyAt
$chkUseFolderTime.IsChecked = [bool]$cfg.UseFolderTime

$btnSave.Add_Click({
  try{
    if($txtTrimAt.Text -notmatch '^\d{2}:\d{2}$'){ throw "NightlyTrimAt must be HH:mm" }
    if($txtApplyAt.Text -notmatch '^\d{2}:\d{2}$'){ throw "NightlyApplyAt must be HH:mm" }
    $cfg.Env         = ($cbEnv.SelectedItem).Content
    $cfg.VerifyMode  = ($cbVerify.SelectedItem).Content
    $cfg.CleanupDays = [int]$txtCleanupDays.Text
    $cfg.KeepTopN    = [int]$txtKeepN.Text
    $cfg.UseFolderTime = [bool]$chkUseFolderTime.IsChecked
    $cfg.Auto.CleanupEveryHours = [int]$txtCleanH.Text
    $cfg.Auto.VerifyEveryHours  = [int]$txtVerifyH.Text
    $cfg.Auto.NightlyTrimAt     = $txtTrimAt.Text
    $cfg.Auto.NightlyApplyAt    = $txtApplyAt.Text
    Save-Config $cfg
    [System.Windows.MessageBox]::Show("Saved to `n$cfgPath","Mason2 Settings") | Out-Null
  }catch{
    [System.Windows.MessageBox]::Show($_.Exception.Message,"Mason2 Settings") | Out-Null
  }
})
$btnClose.Add_Click({ $w.Close() })

$null = $w.ShowDialog()

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
$cfgPath = Join-Path $script:Paths.Base 'config\mason2.config.json'
New-Item -ItemType Directory -Force -Path (Split-Path $cfgPath) | Out-Null

function Load-Config {
  if(Test-Path $cfgPath){ Get-Content $cfgPath -Raw | ConvertFrom-Json } else { Read-Config }
}
function Save-Config([object]$obj){
  $obj | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 $cfgPath
}

[xml]$x = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Settings" Width="560" Height="480" WindowStartupLocation="CenterScreen">
  <Grid Margin="12">
    <Grid.RowDefinitions>
      <RowDefinition Height="*"/><RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <StackPanel>
      <TextBlock Text="Environment" FontWeight="Bold"/>
      <ComboBox Name="cbEnv" Margin="0,4,0,10">
        <ComboBoxItem Content="dev"/>
        <ComboBoxItem Content="strict"/>
      </ComboBox>

      <TextBlock Text="Verify Mode" FontWeight="Bold"/>
      <ComboBox Name="cbVerify" Margin="0,4,0,10">
        <ComboBoxItem Content="dev"/>
        <ComboBoxItem Content="strict"/>
      </ComboBox>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="CleanupDays" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtCleanupDays" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="KeepTopN" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtKeepN" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="CleanupEveryHours" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtCleanH" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="VerifyEveryHours" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtVerifyH" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="NightlyTrimAt (HH:mm)" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtTrimAt" Width="100"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="NightlyApplyAt (HH:mm)" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtApplyAt" Width="100"/>
      </StackPanel>

      <CheckBox Name="chkUseFolderTime" Content="UseFolderTime for cleanup" Margin="0,6,0,0"/>
    </StackPanel>

    <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Right">
      <Button Name="btnSave" Content="Save" Padding="12,6"/>
      <Button Name="btnClose" Content="Close" Padding="12,6" Margin="8,0,0,0"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $x
$w      = [Windows.Markup.XamlReader]::Load($reader)

$cbEnv = $w.FindName('cbEnv')
$cbVerify = $w.FindName('cbVerify')
$txtCleanupDays = $w.FindName('txtCleanupDays')
$txtKeepN = $w.FindName('txtKeepN')
$txtCleanH = $w.FindName('txtCleanH')
$txtVerifyH = $w.FindName('txtVerifyH')
$txtTrimAt = $w.FindName('txtTrimAt')
$txtApplyAt = $w.FindName('txtApplyAt')
$chkUseFolderTime = $w.FindName('chkUseFolderTime')
$btnSave = $w.FindName('btnSave')
$btnClose = $w.FindName('btnClose')

function Select-ByContent($combo,[string]$val){
  foreach($i in $combo.Items){ if($i.Content -eq $val){ $combo.SelectedItem = $i; break } }
}

$cfg = Load-Config
Select-ByContent $cbEnv    ([string]$cfg.Env)
Select-ByContent $cbVerify ([string]$cfg.VerifyMode)
$txtCleanupDays.Text = [string]$cfg.CleanupDays
$txtKeepN.Text       = [string]$cfg.KeepTopN
$txtCleanH.Text      = [string]$cfg.Auto.CleanupEveryHours
$txtVerifyH.Text     = [string]$cfg.Auto.VerifyEveryHours
$txtTrimAt.Text      = [string]$cfg.Auto.NightlyTrimAt
$txtApplyAt.Text     = [string]$cfg.Auto.NightlyApplyAt
$chkUseFolderTime.IsChecked = [bool]$cfg.UseFolderTime

$btnSave.Add_Click({
  try{
    if($txtTrimAt.Text -notmatch '^\d{2}:\d{2}$'){ throw "NightlyTrimAt must be HH:mm" }
    if($txtApplyAt.Text -notmatch '^\d{2}:\d{2}$'){ throw "NightlyApplyAt must be HH:mm" }
    $cfg.Env         = ($cbEnv.SelectedItem).Content
    $cfg.VerifyMode  = ($cbVerify.SelectedItem).Content
    $cfg.CleanupDays = [int]$txtCleanupDays.Text
    $cfg.KeepTopN    = [int]$txtKeepN.Text
    $cfg.UseFolderTime = [bool]$chkUseFolderTime.IsChecked
    $cfg.Auto.CleanupEveryHours = [int]$txtCleanH.Text
    $cfg.Auto.VerifyEveryHours  = [int]$txtVerifyH.Text
    $cfg.Auto.NightlyTrimAt     = $txtTrimAt.Text
    $cfg.Auto.NightlyApplyAt    = $txtApplyAt.Text
    Save-Config $cfg
    [System.Windows.MessageBox]::Show("Saved to `n$cfgPath","Mason2 Settings") | Out-Null
  }catch{
    [System.Windows.MessageBox]::Show($_.Exception.Message,"Mason2 Settings") | Out-Null
  }
})
$btnClose.Add_Click({ $w.Close() })

$null = $w.ShowDialog()

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot 'Common.ps1')

Add-Type -AssemblyName PresentationCore,PresentationFramework
$cfgPath = Join-Path $script:Paths.Base 'config\mason2.config.json'
New-Item -ItemType Directory -Force -Path (Split-Path $cfgPath) | Out-Null

function Load-Config {
  if(Test-Path $cfgPath){ Get-Content $cfgPath -Raw | ConvertFrom-Json } else { Read-Config }
}
function Save-Config([object]$obj){
  $obj | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 $cfgPath
}

[xml]$x = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Settings" Width="560" Height="480" WindowStartupLocation="CenterScreen">
  <Grid Margin="12">
    <Grid.RowDefinitions>
      <RowDefinition Height="*"/><RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <StackPanel>
      <TextBlock Text="Environment" FontWeight="Bold"/>
      <ComboBox Name="cbEnv" Margin="0,4,0,10">
        <ComboBoxItem Content="dev"/>
        <ComboBoxItem Content="strict"/>
      </ComboBox>

      <TextBlock Text="Verify Mode" FontWeight="Bold"/>
      <ComboBox Name="cbVerify" Margin="0,4,0,10">
        <ComboBoxItem Content="dev"/>
        <ComboBoxItem Content="strict"/>
      </ComboBox>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="CleanupDays" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtCleanupDays" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="KeepTopN" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtKeepN" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="CleanupEveryHours" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtCleanH" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="VerifyEveryHours" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtVerifyH" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="NightlyTrimAt (HH:mm)" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtTrimAt" Width="100"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="NightlyApplyAt (HH:mm)" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtApplyAt" Width="100"/>
      </StackPanel>

      <CheckBox Name="chkUseFolderTime" Content="UseFolderTime for cleanup" Margin="0,6,0,0"/>
    </StackPanel>

    <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Right">
      <Button Name="btnSave" Content="Save" Padding="12,6"/>
      <Button Name="btnClose" Content="Close" Padding="12,6" Margin="8,0,0,0"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $x
$w      = [Windows.Markup.XamlReader]::Load($reader)

$cbEnv = $w.FindName('cbEnv')
$cbVerify = $w.FindName('cbVerify')
$txtCleanupDays = $w.FindName('txtCleanupDays')
$txtKeepN = $w.FindName('txtKeepN')
$txtCleanH = $w.FindName('txtCleanH')
$txtVerifyH = $w.FindName('txtVerifyH')
$txtTrimAt = $w.FindName('txtTrimAt')
$txtApplyAt = $w.FindName('txtApplyAt')
$chkUseFolderTime = $w.FindName('chkUseFolderTime')
$btnSave = $w.FindName('btnSave')
$btnClose = $w.FindName('btnClose')

function Select-ByContent($combo,[string]$val){
  foreach($i in $combo.Items){ if($i.Content -eq $val){ $combo.SelectedItem = $i; break } }
}

$cfg = Load-Config
Select-ByContent $cbEnv    ([string]$cfg.Env)
Select-ByContent $cbVerify ([string]$cfg.VerifyMode)
$txtCleanupDays.Text = [string]$cfg.CleanupDays
$txtKeepN.Text       = [string]$cfg.KeepTopN
$txtCleanH.Text      = [string]$cfg.Auto.CleanupEveryHours
$txtVerifyH.Text     = [string]$cfg.Auto.VerifyEveryHours
$txtTrimAt.Text      = [string]$cfg.Auto.NightlyTrimAt
$txtApplyAt.Text     = [string]$cfg.Auto.NightlyApplyAt
$chkUseFolderTime.IsChecked = [bool]$cfg.UseFolderTime

$btnSave.Add_Click({
  try{
    if($txtTrimAt.Text -notmatch '^\d{2}:\d{2}$'){ throw "NightlyTrimAt must be HH:mm" }
    if($txtApplyAt.Text -notmatch '^\d{2}:\d{2}$'){ throw "NightlyApplyAt must be HH:mm" }
    $cfg.Env         = ($cbEnv.SelectedItem).Content
    $cfg.VerifyMode  = ($cbVerify.SelectedItem).Content
    $cfg.CleanupDays = [int]$txtCleanupDays.Text
    $cfg.KeepTopN    = [int]$txtKeepN.Text
    $cfg.UseFolderTime = [bool]$chkUseFolderTime.IsChecked
    $cfg.Auto.CleanupEveryHours = [int]$txtCleanH.Text
    $cfg.Auto.VerifyEveryHours  = [int]$txtVerifyH.Text
    $cfg.Auto.NightlyTrimAt     = $txtTrimAt.Text
    $cfg.Auto.NightlyApplyAt    = $txtApplyAt.Text
    Save-Config $cfg
    [System.Windows.MessageBox]::Show("Saved to `n$cfgPath","Mason2 Settings") | Out-Null
  }catch{
    [System.Windows.MessageBox]::Show($_.Exception.Message,"Mason2 Settings") | Out-Null
  }
})
$btnClose.Add_Click({ $w.Close() })

$null = $w.ShowDialog()

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
$cfgPath = Join-Path $script:Paths.Base 'config\mason2.config.json'
New-Item -ItemType Directory -Force -Path (Split-Path $cfgPath) | Out-Null

function Load-Config {
  if(Test-Path $cfgPath){ Get-Content $cfgPath -Raw | ConvertFrom-Json } else { Read-Config }
}
function Save-Config([object]$obj){
  $obj | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 $cfgPath
}

[xml]$x = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Settings" Width="560" Height="480" WindowStartupLocation="CenterScreen">
  <Grid Margin="12">
    <Grid.RowDefinitions>
      <RowDefinition Height="*"/><RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <StackPanel>
      <TextBlock Text="Environment" FontWeight="Bold"/>
      <ComboBox Name="cbEnv" Margin="0,4,0,10">
        <ComboBoxItem Content="dev"/>
        <ComboBoxItem Content="strict"/>
      </ComboBox>

      <TextBlock Text="Verify Mode" FontWeight="Bold"/>
      <ComboBox Name="cbVerify" Margin="0,4,0,10">
        <ComboBoxItem Content="dev"/>
        <ComboBoxItem Content="strict"/>
      </ComboBox>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="CleanupDays" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtCleanupDays" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="KeepTopN" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtKeepN" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="CleanupEveryHours" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtCleanH" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="VerifyEveryHours" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtVerifyH" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="NightlyTrimAt (HH:mm)" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtTrimAt" Width="100"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="NightlyApplyAt (HH:mm)" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtApplyAt" Width="100"/>
      </StackPanel>

      <CheckBox Name="chkUseFolderTime" Content="UseFolderTime for cleanup" Margin="0,6,0,0"/>
    </StackPanel>

    <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Right">
      <Button Name="btnSave" Content="Save" Padding="12,6"/>
      <Button Name="btnClose" Content="Close" Padding="12,6" Margin="8,0,0,0"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $x
$w      = [Windows.Markup.XamlReader]::Load($reader)

$cbEnv = $w.FindName('cbEnv')
$cbVerify = $w.FindName('cbVerify')
$txtCleanupDays = $w.FindName('txtCleanupDays')
$txtKeepN = $w.FindName('txtKeepN')
$txtCleanH = $w.FindName('txtCleanH')
$txtVerifyH = $w.FindName('txtVerifyH')
$txtTrimAt = $w.FindName('txtTrimAt')
$txtApplyAt = $w.FindName('txtApplyAt')
$chkUseFolderTime = $w.FindName('chkUseFolderTime')
$btnSave = $w.FindName('btnSave')
$btnClose = $w.FindName('btnClose')

function Select-ByContent($combo,[string]$val){
  foreach($i in $combo.Items){ if($i.Content -eq $val){ $combo.SelectedItem = $i; break } }
}

$cfg = Load-Config
Select-ByContent $cbEnv    ([string]$cfg.Env)
Select-ByContent $cbVerify ([string]$cfg.VerifyMode)
$txtCleanupDays.Text = [string]$cfg.CleanupDays
$txtKeepN.Text       = [string]$cfg.KeepTopN
$txtCleanH.Text      = [string]$cfg.Auto.CleanupEveryHours
$txtVerifyH.Text     = [string]$cfg.Auto.VerifyEveryHours
$txtTrimAt.Text      = [string]$cfg.Auto.NightlyTrimAt
$txtApplyAt.Text     = [string]$cfg.Auto.NightlyApplyAt
$chkUseFolderTime.IsChecked = [bool]$cfg.UseFolderTime

$btnSave.Add_Click({
  try{
    if($txtTrimAt.Text -notmatch '^\d{2}:\d{2}$'){ throw "NightlyTrimAt must be HH:mm" }
    if($txtApplyAt.Text -notmatch '^\d{2}:\d{2}$'){ throw "NightlyApplyAt must be HH:mm" }
    $cfg.Env         = ($cbEnv.SelectedItem).Content
    $cfg.VerifyMode  = ($cbVerify.SelectedItem).Content
    $cfg.CleanupDays = [int]$txtCleanupDays.Text
    $cfg.KeepTopN    = [int]$txtKeepN.Text
    $cfg.UseFolderTime = [bool]$chkUseFolderTime.IsChecked
    $cfg.Auto.CleanupEveryHours = [int]$txtCleanH.Text
    $cfg.Auto.VerifyEveryHours  = [int]$txtVerifyH.Text
    $cfg.Auto.NightlyTrimAt     = $txtTrimAt.Text
    $cfg.Auto.NightlyApplyAt    = $txtApplyAt.Text
    Save-Config $cfg
    [System.Windows.MessageBox]::Show("Saved to `n$cfgPath","Mason2 Settings") | Out-Null
  }catch{
    [System.Windows.MessageBox]::Show($_.Exception.Message,"Mason2 Settings") | Out-Null
  }
})
$btnClose.Add_Click({ $w.Close() })

$null = $w.ShowDialog()

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot 'Common.ps1')

Add-Type -AssemblyName PresentationCore,PresentationFramework
$cfgPath = Join-Path $script:Paths.Base 'config\mason2.config.json'
New-Item -ItemType Directory -Force -Path (Split-Path $cfgPath) | Out-Null

function Load-Config {
  if(Test-Path $cfgPath){ Get-Content $cfgPath -Raw | ConvertFrom-Json } else { Read-Config }
}
function Save-Config([object]$obj){
  $obj | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 $cfgPath
}

[xml]$x = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Settings" Width="560" Height="480" WindowStartupLocation="CenterScreen">
  <Grid Margin="12">
    <Grid.RowDefinitions>
      <RowDefinition Height="*"/><RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <StackPanel>
      <TextBlock Text="Environment" FontWeight="Bold"/>
      <ComboBox Name="cbEnv" Margin="0,4,0,10">
        <ComboBoxItem Content="dev"/>
        <ComboBoxItem Content="strict"/>
      </ComboBox>

      <TextBlock Text="Verify Mode" FontWeight="Bold"/>
      <ComboBox Name="cbVerify" Margin="0,4,0,10">
        <ComboBoxItem Content="dev"/>
        <ComboBoxItem Content="strict"/>
      </ComboBox>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="CleanupDays" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtCleanupDays" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="KeepTopN" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtKeepN" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="CleanupEveryHours" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtCleanH" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="VerifyEveryHours" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtVerifyH" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="NightlyTrimAt (HH:mm)" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtTrimAt" Width="100"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="NightlyApplyAt (HH:mm)" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtApplyAt" Width="100"/>
      </StackPanel>

      <CheckBox Name="chkUseFolderTime" Content="UseFolderTime for cleanup" Margin="0,6,0,0"/>
    </StackPanel>

    <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Right">
      <Button Name="btnSave" Content="Save" Padding="12,6"/>
      <Button Name="btnClose" Content="Close" Padding="12,6" Margin="8,0,0,0"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $x
$w      = [Windows.Markup.XamlReader]::Load($reader)

$cbEnv = $w.FindName('cbEnv')
$cbVerify = $w.FindName('cbVerify')
$txtCleanupDays = $w.FindName('txtCleanupDays')
$txtKeepN = $w.FindName('txtKeepN')
$txtCleanH = $w.FindName('txtCleanH')
$txtVerifyH = $w.FindName('txtVerifyH')
$txtTrimAt = $w.FindName('txtTrimAt')
$txtApplyAt = $w.FindName('txtApplyAt')
$chkUseFolderTime = $w.FindName('chkUseFolderTime')
$btnSave = $w.FindName('btnSave')
$btnClose = $w.FindName('btnClose')

function Select-ByContent($combo,[string]$val){
  foreach($i in $combo.Items){ if($i.Content -eq $val){ $combo.SelectedItem = $i; break } }
}

$cfg = Load-Config
Select-ByContent $cbEnv    ([string]$cfg.Env)
Select-ByContent $cbVerify ([string]$cfg.VerifyMode)
$txtCleanupDays.Text = [string]$cfg.CleanupDays
$txtKeepN.Text       = [string]$cfg.KeepTopN
$txtCleanH.Text      = [string]$cfg.Auto.CleanupEveryHours
$txtVerifyH.Text     = [string]$cfg.Auto.VerifyEveryHours
$txtTrimAt.Text      = [string]$cfg.Auto.NightlyTrimAt
$txtApplyAt.Text     = [string]$cfg.Auto.NightlyApplyAt
$chkUseFolderTime.IsChecked = [bool]$cfg.UseFolderTime

$btnSave.Add_Click({
  try{
    if($txtTrimAt.Text -notmatch '^\d{2}:\d{2}$'){ throw "NightlyTrimAt must be HH:mm" }
    if($txtApplyAt.Text -notmatch '^\d{2}:\d{2}$'){ throw "NightlyApplyAt must be HH:mm" }
    $cfg.Env         = ($cbEnv.SelectedItem).Content
    $cfg.VerifyMode  = ($cbVerify.SelectedItem).Content
    $cfg.CleanupDays = [int]$txtCleanupDays.Text
    $cfg.KeepTopN    = [int]$txtKeepN.Text
    $cfg.UseFolderTime = [bool]$chkUseFolderTime.IsChecked
    $cfg.Auto.CleanupEveryHours = [int]$txtCleanH.Text
    $cfg.Auto.VerifyEveryHours  = [int]$txtVerifyH.Text
    $cfg.Auto.NightlyTrimAt     = $txtTrimAt.Text
    $cfg.Auto.NightlyApplyAt    = $txtApplyAt.Text
    Save-Config $cfg
    [System.Windows.MessageBox]::Show("Saved to `n$cfgPath","Mason2 Settings") | Out-Null
  }catch{
    [System.Windows.MessageBox]::Show($_.Exception.Message,"Mason2 Settings") | Out-Null
  }
})
$btnClose.Add_Click({ $w.Close() })

$null = $w.ShowDialog()

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
$cfgPath = Join-Path $script:Paths.Base 'config\mason2.config.json'
New-Item -ItemType Directory -Force -Path (Split-Path $cfgPath) | Out-Null

function Load-Config {
  if(Test-Path $cfgPath){ Get-Content $cfgPath -Raw | ConvertFrom-Json } else { Read-Config }
}
function Save-Config([object]$obj){
  $obj | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 $cfgPath
}

[xml]$x = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Settings" Width="560" Height="480" WindowStartupLocation="CenterScreen">
  <Grid Margin="12">
    <Grid.RowDefinitions>
      <RowDefinition Height="*"/><RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <StackPanel>
      <TextBlock Text="Environment" FontWeight="Bold"/>
      <ComboBox Name="cbEnv" Margin="0,4,0,10">
        <ComboBoxItem Content="dev"/>
        <ComboBoxItem Content="strict"/>
      </ComboBox>

      <TextBlock Text="Verify Mode" FontWeight="Bold"/>
      <ComboBox Name="cbVerify" Margin="0,4,0,10">
        <ComboBoxItem Content="dev"/>
        <ComboBoxItem Content="strict"/>
      </ComboBox>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="CleanupDays" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtCleanupDays" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="KeepTopN" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtKeepN" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="CleanupEveryHours" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtCleanH" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="VerifyEveryHours" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtVerifyH" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="NightlyTrimAt (HH:mm)" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtTrimAt" Width="100"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="NightlyApplyAt (HH:mm)" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtApplyAt" Width="100"/>
      </StackPanel>

      <CheckBox Name="chkUseFolderTime" Content="UseFolderTime for cleanup" Margin="0,6,0,0"/>
    </StackPanel>

    <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Right">
      <Button Name="btnSave" Content="Save" Padding="12,6"/>
      <Button Name="btnClose" Content="Close" Padding="12,6" Margin="8,0,0,0"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $x
$w      = [Windows.Markup.XamlReader]::Load($reader)

$cbEnv = $w.FindName('cbEnv')
$cbVerify = $w.FindName('cbVerify')
$txtCleanupDays = $w.FindName('txtCleanupDays')
$txtKeepN = $w.FindName('txtKeepN')
$txtCleanH = $w.FindName('txtCleanH')
$txtVerifyH = $w.FindName('txtVerifyH')
$txtTrimAt = $w.FindName('txtTrimAt')
$txtApplyAt = $w.FindName('txtApplyAt')
$chkUseFolderTime = $w.FindName('chkUseFolderTime')
$btnSave = $w.FindName('btnSave')
$btnClose = $w.FindName('btnClose')

function Select-ByContent($combo,[string]$val){
  foreach($i in $combo.Items){ if($i.Content -eq $val){ $combo.SelectedItem = $i; break } }
}

$cfg = Load-Config
Select-ByContent $cbEnv    ([string]$cfg.Env)
Select-ByContent $cbVerify ([string]$cfg.VerifyMode)
$txtCleanupDays.Text = [string]$cfg.CleanupDays
$txtKeepN.Text       = [string]$cfg.KeepTopN
$txtCleanH.Text      = [string]$cfg.Auto.CleanupEveryHours
$txtVerifyH.Text     = [string]$cfg.Auto.VerifyEveryHours
$txtTrimAt.Text      = [string]$cfg.Auto.NightlyTrimAt
$txtApplyAt.Text     = [string]$cfg.Auto.NightlyApplyAt
$chkUseFolderTime.IsChecked = [bool]$cfg.UseFolderTime

$btnSave.Add_Click({
  try{
    if($txtTrimAt.Text -notmatch '^\d{2}:\d{2}$'){ throw "NightlyTrimAt must be HH:mm" }
    if($txtApplyAt.Text -notmatch '^\d{2}:\d{2}$'){ throw "NightlyApplyAt must be HH:mm" }
    $cfg.Env         = ($cbEnv.SelectedItem).Content
    $cfg.VerifyMode  = ($cbVerify.SelectedItem).Content
    $cfg.CleanupDays = [int]$txtCleanupDays.Text
    $cfg.KeepTopN    = [int]$txtKeepN.Text
    $cfg.UseFolderTime = [bool]$chkUseFolderTime.IsChecked
    $cfg.Auto.CleanupEveryHours = [int]$txtCleanH.Text
    $cfg.Auto.VerifyEveryHours  = [int]$txtVerifyH.Text
    $cfg.Auto.NightlyTrimAt     = $txtTrimAt.Text
    $cfg.Auto.NightlyApplyAt    = $txtApplyAt.Text
    Save-Config $cfg
    [System.Windows.MessageBox]::Show("Saved to `n$cfgPath","Mason2 Settings") | Out-Null
  }catch{
    [System.Windows.MessageBox]::Show($_.Exception.Message,"Mason2 Settings") | Out-Null
  }
})
$btnClose.Add_Click({ $w.Close() })

$null = $w.ShowDialog()

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot 'Common.ps1')

Add-Type -AssemblyName PresentationCore,PresentationFramework
$cfgPath = Join-Path $script:Paths.Base 'config\mason2.config.json'
New-Item -ItemType Directory -Force -Path (Split-Path $cfgPath) | Out-Null

function Load-Config {
  if(Test-Path $cfgPath){ Get-Content $cfgPath -Raw | ConvertFrom-Json } else { Read-Config }
}
function Save-Config([object]$obj){
  $obj | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 $cfgPath
}

[xml]$x = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Mason2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Settings" Width="560" Height="480" WindowStartupLocation="CenterScreen">
  <Grid Margin="12">
    <Grid.RowDefinitions>
      <RowDefinition Height="*"/><RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <StackPanel>
      <TextBlock Text="Environment" FontWeight="Bold"/>
      <ComboBox Name="cbEnv" Margin="0,4,0,10">
        <ComboBoxItem Content="dev"/>
        <ComboBoxItem Content="strict"/>
      </ComboBox>

      <TextBlock Text="Verify Mode" FontWeight="Bold"/>
      <ComboBox Name="cbVerify" Margin="0,4,0,10">
        <ComboBoxItem Content="dev"/>
        <ComboBoxItem Content="strict"/>
      </ComboBox>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="CleanupDays" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtCleanupDays" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="KeepTopN" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtKeepN" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="CleanupEveryHours" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtCleanH" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="VerifyEveryHours" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtVerifyH" Width="80"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="NightlyTrimAt (HH:mm)" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtTrimAt" Width="100"/>
      </StackPanel>

      <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
        <TextBlock Text="NightlyApplyAt (HH:mm)" Width="140" VerticalAlignment="Center"/>
        <TextBox Name="txtApplyAt" Width="100"/>
      </StackPanel>

      <CheckBox Name="chkUseFolderTime" Content="UseFolderTime for cleanup" Margin="0,6,0,0"/>
    </StackPanel>

    <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Right">
      <Button Name="btnSave" Content="Save" Padding="12,6"/>
      <Button Name="btnClose" Content="Close" Padding="12,6" Margin="8,0,0,0"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $x
$w      = [Windows.Markup.XamlReader]::Load($reader)

$cbEnv = $w.FindName('cbEnv')
$cbVerify = $w.FindName('cbVerify')
$txtCleanupDays = $w.FindName('txtCleanupDays')
$txtKeepN = $w.FindName('txtKeepN')
$txtCleanH = $w.FindName('txtCleanH')
$txtVerifyH = $w.FindName('txtVerifyH')
$txtTrimAt = $w.FindName('txtTrimAt')
$txtApplyAt = $w.FindName('txtApplyAt')
$chkUseFolderTime = $w.FindName('chkUseFolderTime')
$btnSave = $w.FindName('btnSave')
$btnClose = $w.FindName('btnClose')

function Select-ByContent($combo,[string]$val){
  foreach($i in $combo.Items){ if($i.Content -eq $val){ $combo.SelectedItem = $i; break } }
}

$cfg = Load-Config
Select-ByContent $cbEnv    ([string]$cfg.Env)
Select-ByContent $cbVerify ([string]$cfg.VerifyMode)
$txtCleanupDays.Text = [string]$cfg.CleanupDays
$txtKeepN.Text       = [string]$cfg.KeepTopN
$txtCleanH.Text      = [string]$cfg.Auto.CleanupEveryHours
$txtVerifyH.Text     = [string]$cfg.Auto.VerifyEveryHours
$txtTrimAt.Text      = [string]$cfg.Auto.NightlyTrimAt
$txtApplyAt.Text     = [string]$cfg.Auto.NightlyApplyAt
$chkUseFolderTime.IsChecked = [bool]$cfg.UseFolderTime

$btnSave.Add_Click({
  try{
    if($txtTrimAt.Text -notmatch '^\d{2}:\d{2}$'){ throw "NightlyTrimAt must be HH:mm" }
    if($txtApplyAt.Text -notmatch '^\d{2}:\d{2}$'){ throw "NightlyApplyAt must be HH:mm" }
    $cfg.Env         = ($cbEnv.SelectedItem).Content
    $cfg.VerifyMode  = ($cbVerify.SelectedItem).Content
    $cfg.CleanupDays = [int]$txtCleanupDays.Text
    $cfg.KeepTopN    = [int]$txtKeepN.Text
    $cfg.UseFolderTime = [bool]$chkUseFolderTime.IsChecked
    $cfg.Auto.CleanupEveryHours = [int]$txtCleanH.Text
    $cfg.Auto.VerifyEveryHours  = [int]$txtVerifyH.Text
    $cfg.Auto.NightlyTrimAt     = $txtTrimAt.Text
    $cfg.Auto.NightlyApplyAt    = $txtApplyAt.Text
    Save-Config $cfg
    [System.Windows.MessageBox]::Show("Saved to `n$cfgPath","Mason2 Settings") | Out-Null
  }catch{
    [System.Windows.MessageBox]::Show($_.Exception.Message,"Mason2 Settings") | Out-Null
  }
})
$btnClose.Add_Click({ $w.Close() })

$null = $w.ShowDialog()

