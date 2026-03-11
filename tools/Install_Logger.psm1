# Mason2-Version: 1.3.1
function Get-InstallLogPath {
  $Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
  $dir  = Join-Path $Base "logs\install"
  New-Item $dir -ItemType Directory -ea SilentlyContinue | Out-Null
  return (Join-Path $dir ("install_" + (Get-Date -Format 'yyyyMMdd') + ".log"))
}
function Write-InstallLog {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Message,
    [ValidateSet('INFO','WARN','ERROR')][string]$Level='INFO',
    [Hashtable]$Props
  )
  $evt = [ordered]@{
    ts = (Get-Date).ToString('o'); level=$Level; msg=$Message; user=$env:USERNAME; pid=$PID
  }
  if($Props){ foreach($k in $Props.Keys){ $evt["prop_$k"] = ($Props[$k] -as [string]) } }
  $line = ($evt | ConvertTo-Json -Compress)
  $path = Get-InstallLogPath
  Add-Content -LiteralPath $path -Value $line -Encoding UTF8
  return $path
}
Export-ModuleMember -Function Get-InstallLogPath,Write-InstallLog
