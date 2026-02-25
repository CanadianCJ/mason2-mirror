# Stamped: 2025-11-05T17:02:01
# Fix_TasksPanel_Injection.ps1
# Repairs the "Scheduled Tasks" panel injection by removing the broken block
# and re-inserting a correct version using single-quoted here-strings.
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
$dash = Join-Path $Base 'tools\Start_DashboardWindow.ps1'
if(!(Test-Path $dash)){ throw "Dashboard not found: $dash" }

$src = Get-Content -Raw -LiteralPath $dash
$bak = "$dash.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
Copy-Item -LiteralPath $dash -Destination $bak -Force

# Strip any prior (possibly broken) helper/panel blocks
$helperPattern = '(?s)function\s+Get-M2TasksSnapshot\s*\{.*?\}\s*'
$panelPattern  = '(?s)# ----- M2TasksPanelInjected \(read-only\) -----.*?# ----- /M2TasksPanelInjected -----'
$src = [regex]::Replace($src, $helperPattern, '')
$src = [regex]::Replace($src, $panelPattern,  '')

# Re-insert helper (single-quoted -> no variable expansion)
$helper = @'
function Get-M2TasksSnapshot {
  try {
    Get-ScheduledTask 'Mason2-*' | ForEach-Object {
      $i = $_ | Get-ScheduledTaskInfo
      [pscustomobject]@{
        TaskName       = $_.TaskName
        State          = ($_.State | Out-String).Trim()
        LastRunTime    = $i.LastRunTime
        LastTaskResult = $i.LastTaskResult
        NextRunTime    = $i.NextRunTime
      }
    } | Sort-Object TaskName
  } catch { @() }
}
'@

# Re-insert panel (single-quoted -> no variable expansion)
$panel = @'
# ----- M2TasksPanelInjected (read-only) -----
try{
  Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
  $createTasksPanel = {
    param($window)
    if(-not $window){ return }
    $root = $window.Content
    # Prefer Grid; fallback to named MainGrid if present
    $grid = if($root -is [System.Windows.Controls.Grid]){ $root } else { $window.FindName('MainGrid') }
    if(-not $grid){ return }

    # Only patch once
    if($window.Resources['M2TasksPatched']){ return }
    $window.Resources['M2TasksPatched'] = $true

    # Ensure a right column
    if($grid.ColumnDefinitions.Count -lt 2){
      $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width='*'}))
      $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width='380'}))
    }

    # Host area
    $host = New-Object System.Windows.Controls.Border -Property @{
      Name='TasksPanelHost'; Padding=6; Background=[Windows.Media.Brushes]::Transparent; Margin='8,0,0,0'
    }
    [System.Windows.Controls.Grid]::SetColumn($host,1)
    $grid.Children.Add($host) | Out-Null

    # UI: header, grid, refresh
    $stack = New-Object System.Windows.Controls.StackPanel -Property @{ Orientation='Vertical' }
    $label = New-Object System.Windows.Controls.TextBlock -Property @{ Text='Scheduled Tasks (read-only)'; FontSize=14; Margin='0,0,0,6' }
    $dg    = New-Object System.Windows.Controls.DataGrid
    $dg.IsReadOnly=$true; $dg.AutoGenerateColumns=$true; $dg.CanUserAddRows=$false; $dg.CanUserDeleteRows=$false; $dg.HeadersVisibility='Column'; $dg.Height=300
    $btn   = New-Object System.Windows.Controls.Button -Property @{ Content='Refresh'; Padding='10,4'; HorizontalAlignment='Right'; Margin='0,6,0,0' }

    $stack.Children.Add($label) | Out-Null
    $stack.Children.Add($dg)    | Out-Null
    $stack.Children.Add($btn)   | Out-Null
    $host.Child = $stack

    $fill = {
      $dg.ItemsSource = Get-M2TasksSnapshot | Select-Object TaskName,State,LastRunTime,LastTaskResult,NextRunTime
    }
    $btn.Add_Click({ & $fill })
    & $fill
  }

  if([System.Windows.Application]::Current){
    [System.Windows.Application]::Current.MainWindow.add_ContentRendered({ & $createTasksPanel ([System.Windows.Application]::Current.MainWindow) })
  }
}catch{}
# ----- /M2TasksPanelInjected -----
'@

# Append blocks at end
$src = $src.TrimEnd() + "`r`n`r`n" + $helper + "`r`n" + $panel + "`r`n"

Set-Content -LiteralPath $dash -Value $src -Encoding UTF8
Write-Host "Repaired Tasks panel injection. Backup: $bak"

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Fix_TasksPanel_Injection.ps1
# Repairs the "Scheduled Tasks" panel injection by removing the broken block
# and re-inserting a correct version using single-quoted here-strings.
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
$dash = Join-Path $Base 'tools\Start_DashboardWindow.ps1'
if(!(Test-Path $dash)){ throw "Dashboard not found: $dash" }

$src = Get-Content -Raw -LiteralPath $dash
$bak = "$dash.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
Copy-Item -LiteralPath $dash -Destination $bak -Force

# Strip any prior (possibly broken) helper/panel blocks
$helperPattern = '(?s)function\s+Get-M2TasksSnapshot\s*\{.*?\}\s*'
$panelPattern  = '(?s)# ----- M2TasksPanelInjected \(read-only\) -----.*?# ----- /M2TasksPanelInjected -----'
$src = [regex]::Replace($src, $helperPattern, '')
$src = [regex]::Replace($src, $panelPattern,  '')

# Re-insert helper (single-quoted -> no variable expansion)
$helper = @'
function Get-M2TasksSnapshot {
  try {
    Get-ScheduledTask 'Mason2-*' | ForEach-Object {
      $i = $_ | Get-ScheduledTaskInfo
      [pscustomobject]@{
        TaskName       = $_.TaskName
        State          = ($_.State | Out-String).Trim()
        LastRunTime    = $i.LastRunTime
        LastTaskResult = $i.LastTaskResult
        NextRunTime    = $i.NextRunTime
      }
    } | Sort-Object TaskName
  } catch { @() }
}
'@

# Re-insert panel (single-quoted -> no variable expansion)
$panel = @'
# ----- M2TasksPanelInjected (read-only) -----
try{
  Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
  $createTasksPanel = {
    param($window)
    if(-not $window){ return }
    $root = $window.Content
    # Prefer Grid; fallback to named MainGrid if present
    $grid = if($root -is [System.Windows.Controls.Grid]){ $root } else { $window.FindName('MainGrid') }
    if(-not $grid){ return }

    # Only patch once
    if($window.Resources['M2TasksPatched']){ return }
    $window.Resources['M2TasksPatched'] = $true

    # Ensure a right column
    if($grid.ColumnDefinitions.Count -lt 2){
      $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width='*'}))
      $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width='380'}))
    }

    # Host area
    $host = New-Object System.Windows.Controls.Border -Property @{
      Name='TasksPanelHost'; Padding=6; Background=[Windows.Media.Brushes]::Transparent; Margin='8,0,0,0'
    }
    [System.Windows.Controls.Grid]::SetColumn($host,1)
    $grid.Children.Add($host) | Out-Null

    # UI: header, grid, refresh
    $stack = New-Object System.Windows.Controls.StackPanel -Property @{ Orientation='Vertical' }
    $label = New-Object System.Windows.Controls.TextBlock -Property @{ Text='Scheduled Tasks (read-only)'; FontSize=14; Margin='0,0,0,6' }
    $dg    = New-Object System.Windows.Controls.DataGrid
    $dg.IsReadOnly=$true; $dg.AutoGenerateColumns=$true; $dg.CanUserAddRows=$false; $dg.CanUserDeleteRows=$false; $dg.HeadersVisibility='Column'; $dg.Height=300
    $btn   = New-Object System.Windows.Controls.Button -Property @{ Content='Refresh'; Padding='10,4'; HorizontalAlignment='Right'; Margin='0,6,0,0' }

    $stack.Children.Add($label) | Out-Null
    $stack.Children.Add($dg)    | Out-Null
    $stack.Children.Add($btn)   | Out-Null
    $host.Child = $stack

    $fill = {
      $dg.ItemsSource = Get-M2TasksSnapshot | Select-Object TaskName,State,LastRunTime,LastTaskResult,NextRunTime
    }
    $btn.Add_Click({ & $fill })
    & $fill
  }

  if([System.Windows.Application]::Current){
    [System.Windows.Application]::Current.MainWindow.add_ContentRendered({ & $createTasksPanel ([System.Windows.Application]::Current.MainWindow) })
  }
}catch{}
# ----- /M2TasksPanelInjected -----
'@

# Append blocks at end
$src = $src.TrimEnd() + "`r`n`r`n" + $helper + "`r`n" + $panel + "`r`n"

Set-Content -LiteralPath $dash -Value $src -Encoding UTF8
Write-Host "Repaired Tasks panel injection. Backup: $bak"

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Fix_TasksPanel_Injection.ps1
# Repairs the "Scheduled Tasks" panel injection by removing the broken block
# and re-inserting a correct version using single-quoted here-strings.
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
$dash = Join-Path $Base 'tools\Start_DashboardWindow.ps1'
if(!(Test-Path $dash)){ throw "Dashboard not found: $dash" }

$src = Get-Content -Raw -LiteralPath $dash
$bak = "$dash.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
Copy-Item -LiteralPath $dash -Destination $bak -Force

# Strip any prior (possibly broken) helper/panel blocks
$helperPattern = '(?s)function\s+Get-M2TasksSnapshot\s*\{.*?\}\s*'
$panelPattern  = '(?s)# ----- M2TasksPanelInjected \(read-only\) -----.*?# ----- /M2TasksPanelInjected -----'
$src = [regex]::Replace($src, $helperPattern, '')
$src = [regex]::Replace($src, $panelPattern,  '')

# Re-insert helper (single-quoted -> no variable expansion)
$helper = @'
function Get-M2TasksSnapshot {
  try {
    Get-ScheduledTask 'Mason2-*' | ForEach-Object {
      $i = $_ | Get-ScheduledTaskInfo
      [pscustomobject]@{
        TaskName       = $_.TaskName
        State          = ($_.State | Out-String).Trim()
        LastRunTime    = $i.LastRunTime
        LastTaskResult = $i.LastTaskResult
        NextRunTime    = $i.NextRunTime
      }
    } | Sort-Object TaskName
  } catch { @() }
}
'@

# Re-insert panel (single-quoted -> no variable expansion)
$panel = @'
# ----- M2TasksPanelInjected (read-only) -----
try{
  Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
  $createTasksPanel = {
    param($window)
    if(-not $window){ return }
    $root = $window.Content
    # Prefer Grid; fallback to named MainGrid if present
    $grid = if($root -is [System.Windows.Controls.Grid]){ $root } else { $window.FindName('MainGrid') }
    if(-not $grid){ return }

    # Only patch once
    if($window.Resources['M2TasksPatched']){ return }
    $window.Resources['M2TasksPatched'] = $true

    # Ensure a right column
    if($grid.ColumnDefinitions.Count -lt 2){
      $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width='*'}))
      $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width='380'}))
    }

    # Host area
    $host = New-Object System.Windows.Controls.Border -Property @{
      Name='TasksPanelHost'; Padding=6; Background=[Windows.Media.Brushes]::Transparent; Margin='8,0,0,0'
    }
    [System.Windows.Controls.Grid]::SetColumn($host,1)
    $grid.Children.Add($host) | Out-Null

    # UI: header, grid, refresh
    $stack = New-Object System.Windows.Controls.StackPanel -Property @{ Orientation='Vertical' }
    $label = New-Object System.Windows.Controls.TextBlock -Property @{ Text='Scheduled Tasks (read-only)'; FontSize=14; Margin='0,0,0,6' }
    $dg    = New-Object System.Windows.Controls.DataGrid
    $dg.IsReadOnly=$true; $dg.AutoGenerateColumns=$true; $dg.CanUserAddRows=$false; $dg.CanUserDeleteRows=$false; $dg.HeadersVisibility='Column'; $dg.Height=300
    $btn   = New-Object System.Windows.Controls.Button -Property @{ Content='Refresh'; Padding='10,4'; HorizontalAlignment='Right'; Margin='0,6,0,0' }

    $stack.Children.Add($label) | Out-Null
    $stack.Children.Add($dg)    | Out-Null
    $stack.Children.Add($btn)   | Out-Null
    $host.Child = $stack

    $fill = {
      $dg.ItemsSource = Get-M2TasksSnapshot | Select-Object TaskName,State,LastRunTime,LastTaskResult,NextRunTime
    }
    $btn.Add_Click({ & $fill })
    & $fill
  }

  if([System.Windows.Application]::Current){
    [System.Windows.Application]::Current.MainWindow.add_ContentRendered({ & $createTasksPanel ([System.Windows.Application]::Current.MainWindow) })
  }
}catch{}
# ----- /M2TasksPanelInjected -----
'@

# Append blocks at end
$src = $src.TrimEnd() + "`r`n`r`n" + $helper + "`r`n" + $panel + "`r`n"

Set-Content -LiteralPath $dash -Value $src -Encoding UTF8
Write-Host "Repaired Tasks panel injection. Backup: $bak"

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Fix_TasksPanel_Injection.ps1
# Repairs the "Scheduled Tasks" panel injection by removing the broken block
# and re-inserting a correct version using single-quoted here-strings.
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
$dash = Join-Path $Base 'tools\Start_DashboardWindow.ps1'
if(!(Test-Path $dash)){ throw "Dashboard not found: $dash" }

$src = Get-Content -Raw -LiteralPath $dash
$bak = "$dash.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
Copy-Item -LiteralPath $dash -Destination $bak -Force

# Strip any prior (possibly broken) helper/panel blocks
$helperPattern = '(?s)function\s+Get-M2TasksSnapshot\s*\{.*?\}\s*'
$panelPattern  = '(?s)# ----- M2TasksPanelInjected \(read-only\) -----.*?# ----- /M2TasksPanelInjected -----'
$src = [regex]::Replace($src, $helperPattern, '')
$src = [regex]::Replace($src, $panelPattern,  '')

# Re-insert helper (single-quoted -> no variable expansion)
$helper = @'
function Get-M2TasksSnapshot {
  try {
    Get-ScheduledTask 'Mason2-*' | ForEach-Object {
      $i = $_ | Get-ScheduledTaskInfo
      [pscustomobject]@{
        TaskName       = $_.TaskName
        State          = ($_.State | Out-String).Trim()
        LastRunTime    = $i.LastRunTime
        LastTaskResult = $i.LastTaskResult
        NextRunTime    = $i.NextRunTime
      }
    } | Sort-Object TaskName
  } catch { @() }
}
'@

# Re-insert panel (single-quoted -> no variable expansion)
$panel = @'
# ----- M2TasksPanelInjected (read-only) -----
try{
  Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
  $createTasksPanel = {
    param($window)
    if(-not $window){ return }
    $root = $window.Content
    # Prefer Grid; fallback to named MainGrid if present
    $grid = if($root -is [System.Windows.Controls.Grid]){ $root } else { $window.FindName('MainGrid') }
    if(-not $grid){ return }

    # Only patch once
    if($window.Resources['M2TasksPatched']){ return }
    $window.Resources['M2TasksPatched'] = $true

    # Ensure a right column
    if($grid.ColumnDefinitions.Count -lt 2){
      $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width='*'}))
      $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width='380'}))
    }

    # Host area
    $host = New-Object System.Windows.Controls.Border -Property @{
      Name='TasksPanelHost'; Padding=6; Background=[Windows.Media.Brushes]::Transparent; Margin='8,0,0,0'
    }
    [System.Windows.Controls.Grid]::SetColumn($host,1)
    $grid.Children.Add($host) | Out-Null

    # UI: header, grid, refresh
    $stack = New-Object System.Windows.Controls.StackPanel -Property @{ Orientation='Vertical' }
    $label = New-Object System.Windows.Controls.TextBlock -Property @{ Text='Scheduled Tasks (read-only)'; FontSize=14; Margin='0,0,0,6' }
    $dg    = New-Object System.Windows.Controls.DataGrid
    $dg.IsReadOnly=$true; $dg.AutoGenerateColumns=$true; $dg.CanUserAddRows=$false; $dg.CanUserDeleteRows=$false; $dg.HeadersVisibility='Column'; $dg.Height=300
    $btn   = New-Object System.Windows.Controls.Button -Property @{ Content='Refresh'; Padding='10,4'; HorizontalAlignment='Right'; Margin='0,6,0,0' }

    $stack.Children.Add($label) | Out-Null
    $stack.Children.Add($dg)    | Out-Null
    $stack.Children.Add($btn)   | Out-Null
    $host.Child = $stack

    $fill = {
      $dg.ItemsSource = Get-M2TasksSnapshot | Select-Object TaskName,State,LastRunTime,LastTaskResult,NextRunTime
    }
    $btn.Add_Click({ & $fill })
    & $fill
  }

  if([System.Windows.Application]::Current){
    [System.Windows.Application]::Current.MainWindow.add_ContentRendered({ & $createTasksPanel ([System.Windows.Application]::Current.MainWindow) })
  }
}catch{}
# ----- /M2TasksPanelInjected -----
'@

# Append blocks at end
$src = $src.TrimEnd() + "`r`n`r`n" + $helper + "`r`n" + $panel + "`r`n"

Set-Content -LiteralPath $dash -Value $src -Encoding UTF8
Write-Host "Repaired Tasks panel injection. Backup: $bak"

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Fix_TasksPanel_Injection.ps1
# Repairs the "Scheduled Tasks" panel injection by removing the broken block
# and re-inserting a correct version using single-quoted here-strings.
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
$dash = Join-Path $Base 'tools\Start_DashboardWindow.ps1'
if(!(Test-Path $dash)){ throw "Dashboard not found: $dash" }

$src = Get-Content -Raw -LiteralPath $dash
$bak = "$dash.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
Copy-Item -LiteralPath $dash -Destination $bak -Force

# Strip any prior (possibly broken) helper/panel blocks
$helperPattern = '(?s)function\s+Get-M2TasksSnapshot\s*\{.*?\}\s*'
$panelPattern  = '(?s)# ----- M2TasksPanelInjected \(read-only\) -----.*?# ----- /M2TasksPanelInjected -----'
$src = [regex]::Replace($src, $helperPattern, '')
$src = [regex]::Replace($src, $panelPattern,  '')

# Re-insert helper (single-quoted -> no variable expansion)
$helper = @'
function Get-M2TasksSnapshot {
  try {
    Get-ScheduledTask 'Mason2-*' | ForEach-Object {
      $i = $_ | Get-ScheduledTaskInfo
      [pscustomobject]@{
        TaskName       = $_.TaskName
        State          = ($_.State | Out-String).Trim()
        LastRunTime    = $i.LastRunTime
        LastTaskResult = $i.LastTaskResult
        NextRunTime    = $i.NextRunTime
      }
    } | Sort-Object TaskName
  } catch { @() }
}
'@

# Re-insert panel (single-quoted -> no variable expansion)
$panel = @'
# ----- M2TasksPanelInjected (read-only) -----
try{
  Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
  $createTasksPanel = {
    param($window)
    if(-not $window){ return }
    $root = $window.Content
    # Prefer Grid; fallback to named MainGrid if present
    $grid = if($root -is [System.Windows.Controls.Grid]){ $root } else { $window.FindName('MainGrid') }
    if(-not $grid){ return }

    # Only patch once
    if($window.Resources['M2TasksPatched']){ return }
    $window.Resources['M2TasksPatched'] = $true

    # Ensure a right column
    if($grid.ColumnDefinitions.Count -lt 2){
      $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width='*'}))
      $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width='380'}))
    }

    # Host area
    $host = New-Object System.Windows.Controls.Border -Property @{
      Name='TasksPanelHost'; Padding=6; Background=[Windows.Media.Brushes]::Transparent; Margin='8,0,0,0'
    }
    [System.Windows.Controls.Grid]::SetColumn($host,1)
    $grid.Children.Add($host) | Out-Null

    # UI: header, grid, refresh
    $stack = New-Object System.Windows.Controls.StackPanel -Property @{ Orientation='Vertical' }
    $label = New-Object System.Windows.Controls.TextBlock -Property @{ Text='Scheduled Tasks (read-only)'; FontSize=14; Margin='0,0,0,6' }
    $dg    = New-Object System.Windows.Controls.DataGrid
    $dg.IsReadOnly=$true; $dg.AutoGenerateColumns=$true; $dg.CanUserAddRows=$false; $dg.CanUserDeleteRows=$false; $dg.HeadersVisibility='Column'; $dg.Height=300
    $btn   = New-Object System.Windows.Controls.Button -Property @{ Content='Refresh'; Padding='10,4'; HorizontalAlignment='Right'; Margin='0,6,0,0' }

    $stack.Children.Add($label) | Out-Null
    $stack.Children.Add($dg)    | Out-Null
    $stack.Children.Add($btn)   | Out-Null
    $host.Child = $stack

    $fill = {
      $dg.ItemsSource = Get-M2TasksSnapshot | Select-Object TaskName,State,LastRunTime,LastTaskResult,NextRunTime
    }
    $btn.Add_Click({ & $fill })
    & $fill
  }

  if([System.Windows.Application]::Current){
    [System.Windows.Application]::Current.MainWindow.add_ContentRendered({ & $createTasksPanel ([System.Windows.Application]::Current.MainWindow) })
  }
}catch{}
# ----- /M2TasksPanelInjected -----
'@

# Append blocks at end
$src = $src.TrimEnd() + "`r`n`r`n" + $helper + "`r`n" + $panel + "`r`n"

Set-Content -LiteralPath $dash -Value $src -Encoding UTF8
Write-Host "Repaired Tasks panel injection. Backup: $bak"

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Fix_TasksPanel_Injection.ps1
# Repairs the "Scheduled Tasks" panel injection by removing the broken block
# and re-inserting a correct version using single-quoted here-strings.
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
$dash = Join-Path $Base 'tools\Start_DashboardWindow.ps1'
if(!(Test-Path $dash)){ throw "Dashboard not found: $dash" }

$src = Get-Content -Raw -LiteralPath $dash
$bak = "$dash.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
Copy-Item -LiteralPath $dash -Destination $bak -Force

# Strip any prior (possibly broken) helper/panel blocks
$helperPattern = '(?s)function\s+Get-M2TasksSnapshot\s*\{.*?\}\s*'
$panelPattern  = '(?s)# ----- M2TasksPanelInjected \(read-only\) -----.*?# ----- /M2TasksPanelInjected -----'
$src = [regex]::Replace($src, $helperPattern, '')
$src = [regex]::Replace($src, $panelPattern,  '')

# Re-insert helper (single-quoted -> no variable expansion)
$helper = @'
function Get-M2TasksSnapshot {
  try {
    Get-ScheduledTask 'Mason2-*' | ForEach-Object {
      $i = $_ | Get-ScheduledTaskInfo
      [pscustomobject]@{
        TaskName       = $_.TaskName
        State          = ($_.State | Out-String).Trim()
        LastRunTime    = $i.LastRunTime
        LastTaskResult = $i.LastTaskResult
        NextRunTime    = $i.NextRunTime
      }
    } | Sort-Object TaskName
  } catch { @() }
}
'@

# Re-insert panel (single-quoted -> no variable expansion)
$panel = @'
# ----- M2TasksPanelInjected (read-only) -----
try{
  Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
  $createTasksPanel = {
    param($window)
    if(-not $window){ return }
    $root = $window.Content
    # Prefer Grid; fallback to named MainGrid if present
    $grid = if($root -is [System.Windows.Controls.Grid]){ $root } else { $window.FindName('MainGrid') }
    if(-not $grid){ return }

    # Only patch once
    if($window.Resources['M2TasksPatched']){ return }
    $window.Resources['M2TasksPatched'] = $true

    # Ensure a right column
    if($grid.ColumnDefinitions.Count -lt 2){
      $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width='*'}))
      $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width='380'}))
    }

    # Host area
    $host = New-Object System.Windows.Controls.Border -Property @{
      Name='TasksPanelHost'; Padding=6; Background=[Windows.Media.Brushes]::Transparent; Margin='8,0,0,0'
    }
    [System.Windows.Controls.Grid]::SetColumn($host,1)
    $grid.Children.Add($host) | Out-Null

    # UI: header, grid, refresh
    $stack = New-Object System.Windows.Controls.StackPanel -Property @{ Orientation='Vertical' }
    $label = New-Object System.Windows.Controls.TextBlock -Property @{ Text='Scheduled Tasks (read-only)'; FontSize=14; Margin='0,0,0,6' }
    $dg    = New-Object System.Windows.Controls.DataGrid
    $dg.IsReadOnly=$true; $dg.AutoGenerateColumns=$true; $dg.CanUserAddRows=$false; $dg.CanUserDeleteRows=$false; $dg.HeadersVisibility='Column'; $dg.Height=300
    $btn   = New-Object System.Windows.Controls.Button -Property @{ Content='Refresh'; Padding='10,4'; HorizontalAlignment='Right'; Margin='0,6,0,0' }

    $stack.Children.Add($label) | Out-Null
    $stack.Children.Add($dg)    | Out-Null
    $stack.Children.Add($btn)   | Out-Null
    $host.Child = $stack

    $fill = {
      $dg.ItemsSource = Get-M2TasksSnapshot | Select-Object TaskName,State,LastRunTime,LastTaskResult,NextRunTime
    }
    $btn.Add_Click({ & $fill })
    & $fill
  }

  if([System.Windows.Application]::Current){
    [System.Windows.Application]::Current.MainWindow.add_ContentRendered({ & $createTasksPanel ([System.Windows.Application]::Current.MainWindow) })
  }
}catch{}
# ----- /M2TasksPanelInjected -----
'@

# Append blocks at end
$src = $src.TrimEnd() + "`r`n`r`n" + $helper + "`r`n" + $panel + "`r`n"

Set-Content -LiteralPath $dash -Value $src -Encoding UTF8
Write-Host "Repaired Tasks panel injection. Backup: $bak"

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Fix_TasksPanel_Injection.ps1
# Repairs the "Scheduled Tasks" panel injection by removing the broken block
# and re-inserting a correct version using single-quoted here-strings.
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
$dash = Join-Path $Base 'tools\Start_DashboardWindow.ps1'
if(!(Test-Path $dash)){ throw "Dashboard not found: $dash" }

$src = Get-Content -Raw -LiteralPath $dash
$bak = "$dash.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
Copy-Item -LiteralPath $dash -Destination $bak -Force

# Strip any prior (possibly broken) helper/panel blocks
$helperPattern = '(?s)function\s+Get-M2TasksSnapshot\s*\{.*?\}\s*'
$panelPattern  = '(?s)# ----- M2TasksPanelInjected \(read-only\) -----.*?# ----- /M2TasksPanelInjected -----'
$src = [regex]::Replace($src, $helperPattern, '')
$src = [regex]::Replace($src, $panelPattern,  '')

# Re-insert helper (single-quoted -> no variable expansion)
$helper = @'
function Get-M2TasksSnapshot {
  try {
    Get-ScheduledTask 'Mason2-*' | ForEach-Object {
      $i = $_ | Get-ScheduledTaskInfo
      [pscustomobject]@{
        TaskName       = $_.TaskName
        State          = ($_.State | Out-String).Trim()
        LastRunTime    = $i.LastRunTime
        LastTaskResult = $i.LastTaskResult
        NextRunTime    = $i.NextRunTime
      }
    } | Sort-Object TaskName
  } catch { @() }
}
'@

# Re-insert panel (single-quoted -> no variable expansion)
$panel = @'
# ----- M2TasksPanelInjected (read-only) -----
try{
  Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
  $createTasksPanel = {
    param($window)
    if(-not $window){ return }
    $root = $window.Content
    # Prefer Grid; fallback to named MainGrid if present
    $grid = if($root -is [System.Windows.Controls.Grid]){ $root } else { $window.FindName('MainGrid') }
    if(-not $grid){ return }

    # Only patch once
    if($window.Resources['M2TasksPatched']){ return }
    $window.Resources['M2TasksPatched'] = $true

    # Ensure a right column
    if($grid.ColumnDefinitions.Count -lt 2){
      $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width='*'}))
      $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width='380'}))
    }

    # Host area
    $host = New-Object System.Windows.Controls.Border -Property @{
      Name='TasksPanelHost'; Padding=6; Background=[Windows.Media.Brushes]::Transparent; Margin='8,0,0,0'
    }
    [System.Windows.Controls.Grid]::SetColumn($host,1)
    $grid.Children.Add($host) | Out-Null

    # UI: header, grid, refresh
    $stack = New-Object System.Windows.Controls.StackPanel -Property @{ Orientation='Vertical' }
    $label = New-Object System.Windows.Controls.TextBlock -Property @{ Text='Scheduled Tasks (read-only)'; FontSize=14; Margin='0,0,0,6' }
    $dg    = New-Object System.Windows.Controls.DataGrid
    $dg.IsReadOnly=$true; $dg.AutoGenerateColumns=$true; $dg.CanUserAddRows=$false; $dg.CanUserDeleteRows=$false; $dg.HeadersVisibility='Column'; $dg.Height=300
    $btn   = New-Object System.Windows.Controls.Button -Property @{ Content='Refresh'; Padding='10,4'; HorizontalAlignment='Right'; Margin='0,6,0,0' }

    $stack.Children.Add($label) | Out-Null
    $stack.Children.Add($dg)    | Out-Null
    $stack.Children.Add($btn)   | Out-Null
    $host.Child = $stack

    $fill = {
      $dg.ItemsSource = Get-M2TasksSnapshot | Select-Object TaskName,State,LastRunTime,LastTaskResult,NextRunTime
    }
    $btn.Add_Click({ & $fill })
    & $fill
  }

  if([System.Windows.Application]::Current){
    [System.Windows.Application]::Current.MainWindow.add_ContentRendered({ & $createTasksPanel ([System.Windows.Application]::Current.MainWindow) })
  }
}catch{}
# ----- /M2TasksPanelInjected -----
'@

# Append blocks at end
$src = $src.TrimEnd() + "`r`n`r`n" + $helper + "`r`n" + $panel + "`r`n"

Set-Content -LiteralPath $dash -Value $src -Encoding UTF8
Write-Host "Repaired Tasks panel injection. Backup: $bak"

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Fix_TasksPanel_Injection.ps1
# Repairs the "Scheduled Tasks" panel injection by removing the broken block
# and re-inserting a correct version using single-quoted here-strings.
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
$dash = Join-Path $Base 'tools\Start_DashboardWindow.ps1'
if(!(Test-Path $dash)){ throw "Dashboard not found: $dash" }

$src = Get-Content -Raw -LiteralPath $dash
$bak = "$dash.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
Copy-Item -LiteralPath $dash -Destination $bak -Force

# Strip any prior (possibly broken) helper/panel blocks
$helperPattern = '(?s)function\s+Get-M2TasksSnapshot\s*\{.*?\}\s*'
$panelPattern  = '(?s)# ----- M2TasksPanelInjected \(read-only\) -----.*?# ----- /M2TasksPanelInjected -----'
$src = [regex]::Replace($src, $helperPattern, '')
$src = [regex]::Replace($src, $panelPattern,  '')

# Re-insert helper (single-quoted -> no variable expansion)
$helper = @'
function Get-M2TasksSnapshot {
  try {
    Get-ScheduledTask 'Mason2-*' | ForEach-Object {
      $i = $_ | Get-ScheduledTaskInfo
      [pscustomobject]@{
        TaskName       = $_.TaskName
        State          = ($_.State | Out-String).Trim()
        LastRunTime    = $i.LastRunTime
        LastTaskResult = $i.LastTaskResult
        NextRunTime    = $i.NextRunTime
      }
    } | Sort-Object TaskName
  } catch { @() }
}
'@

# Re-insert panel (single-quoted -> no variable expansion)
$panel = @'
# ----- M2TasksPanelInjected (read-only) -----
try{
  Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
  $createTasksPanel = {
    param($window)
    if(-not $window){ return }
    $root = $window.Content
    # Prefer Grid; fallback to named MainGrid if present
    $grid = if($root -is [System.Windows.Controls.Grid]){ $root } else { $window.FindName('MainGrid') }
    if(-not $grid){ return }

    # Only patch once
    if($window.Resources['M2TasksPatched']){ return }
    $window.Resources['M2TasksPatched'] = $true

    # Ensure a right column
    if($grid.ColumnDefinitions.Count -lt 2){
      $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width='*'}))
      $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width='380'}))
    }

    # Host area
    $host = New-Object System.Windows.Controls.Border -Property @{
      Name='TasksPanelHost'; Padding=6; Background=[Windows.Media.Brushes]::Transparent; Margin='8,0,0,0'
    }
    [System.Windows.Controls.Grid]::SetColumn($host,1)
    $grid.Children.Add($host) | Out-Null

    # UI: header, grid, refresh
    $stack = New-Object System.Windows.Controls.StackPanel -Property @{ Orientation='Vertical' }
    $label = New-Object System.Windows.Controls.TextBlock -Property @{ Text='Scheduled Tasks (read-only)'; FontSize=14; Margin='0,0,0,6' }
    $dg    = New-Object System.Windows.Controls.DataGrid
    $dg.IsReadOnly=$true; $dg.AutoGenerateColumns=$true; $dg.CanUserAddRows=$false; $dg.CanUserDeleteRows=$false; $dg.HeadersVisibility='Column'; $dg.Height=300
    $btn   = New-Object System.Windows.Controls.Button -Property @{ Content='Refresh'; Padding='10,4'; HorizontalAlignment='Right'; Margin='0,6,0,0' }

    $stack.Children.Add($label) | Out-Null
    $stack.Children.Add($dg)    | Out-Null
    $stack.Children.Add($btn)   | Out-Null
    $host.Child = $stack

    $fill = {
      $dg.ItemsSource = Get-M2TasksSnapshot | Select-Object TaskName,State,LastRunTime,LastTaskResult,NextRunTime
    }
    $btn.Add_Click({ & $fill })
    & $fill
  }

  if([System.Windows.Application]::Current){
    [System.Windows.Application]::Current.MainWindow.add_ContentRendered({ & $createTasksPanel ([System.Windows.Application]::Current.MainWindow) })
  }
}catch{}
# ----- /M2TasksPanelInjected -----
'@

# Append blocks at end
$src = $src.TrimEnd() + "`r`n`r`n" + $helper + "`r`n" + $panel + "`r`n"

Set-Content -LiteralPath $dash -Value $src -Encoding UTF8
Write-Host "Repaired Tasks panel injection. Backup: $bak"

