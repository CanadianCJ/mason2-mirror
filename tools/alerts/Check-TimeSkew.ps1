param([int]$MaxOffsetMs=2000)  # alert if |offset| >= this

$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base=Split-Path -Parent $PSCommandPath }
. (Join-Path $Base 'tools\common\Alert.ps1') 2>$null

function Get-OffsetMs {
  try{
    $out = w32tm /stripchart /computer:time.windows.com /dataonly /samples:1 2>$null
    # Look for seconds like "0.0123456s" or milliseconds like "12ms"
    $sec = ($out | Select-String -Pattern '(-?\d+(\.\d+)?)s' -AllMatches).Matches.Value | Select-Object -First 1
    if($sec){ return [int]([double]($sec -replace 's','')*1000) }
    $ms = ($out | Select-String -Pattern '(-?\d+)ms' -AllMatches).Matches.Value | Select-Object -First 1
    if($ms){ return [int]($ms -replace 'ms','') }
  }catch{}
  return $null
}

$off = Get-OffsetMs
if($off -ne $null -and [math]::Abs($off) -ge $MaxOffsetMs){
  $obj = @{
    ts=(Get-Date).ToString('s'); kind='alert'; subtype='time_skew'
    offset_ms=$off; threshold_ms=$MaxOffsetMs
    message=("Clock offset {0} ms >= {1} ms" -f $off,$MaxOffsetMs)
  }
  Write-Alert -obj $obj -DedupMinutes 30 -DedupKey 'time_skew'
}
