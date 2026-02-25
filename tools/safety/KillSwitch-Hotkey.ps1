Add-Type -Namespace Win -Name Hot -MemberDefinition @"
  [System.Runtime.InteropServices.DllImport("user32.dll")] public static extern bool RegisterHotKey(System.IntPtr hWnd,int id,uint fsModifiers,uint vk);
  [System.Runtime.InteropServices.DllImport("user32.dll")] public static extern bool UnregisterHotKey(System.IntPtr hWnd,int id);
"@
$ErrorActionPreference='Stop'
$base="$env:MASON2_BASE"; $ctrl=Join-Path $base 'control'; New-Item -ItemType Directory -Force $ctrl | Out-Null
Add-Type -AssemblyName System.Windows.Forms
$form = New-Object System.Windows.Forms.Form
$form.ShowInTaskbar=$false; $form.WindowState='Minimized'; $form.Opacity=0
$mod = 0x0002 + 0x0004 # CTRL+SHIFT
$vkK = 0x4B
[Win.Hot]::RegisterHotKey($form.Handle, 1, $mod, $vkK) | Out-Null

function Stop-Disable-Mason {
  $keep = @('Mason-KillSwitchHotkey','Mason-NormalizeTasks')
  Get-ScheduledTask -TaskName 'Mason-*' -ErrorAction SilentlyContinue |
    ? { $keep -notcontains $_.TaskName } |
    % {
      try{ Stop-ScheduledTask -TaskName $_.TaskName -ErrorAction SilentlyContinue }catch{}
      try{ Disable-ScheduledTask -TaskName $_.TaskName -ErrorAction SilentlyContinue }catch{}
    }
}

try{ $sp=New-Object -ComObject SAPI.SpVoice }catch{}

Register-ObjectEvent $form 'HandleCreated' -Action { } | Out-Null
$form.Add_MessageReceived({
  if ($_.Msg -eq 0x0312) { # WM_HOTKEY
    New-Item -ItemType File -Force (Join-Path $ctrl 'KILL.now') | Out-Null
    Stop-Disable-Mason
    if($sp){ $sp.Speak("Mason kill switch triggered. All tasks stopped.") | Out-Null }
  }
})

$form.Add_FormClosing({ [Win.Hot]::UnregisterHotKey($form.Handle,1) | Out-Null })
[void]$form.CreateControl()
[void]$form.Show()
[System.Windows.Forms.Application]::Run($form)