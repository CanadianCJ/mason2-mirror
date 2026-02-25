param([int]$WindowLines=2000,[int]$MinSamples=50,[double]$ThresholdPct=5.0)
$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base=Split-Path -Parent $PSCommandPath }
. (Join-Path $Base 'tools\common\Alert.ps1') 2>$null

$rep = Join-Path $Base 'reports'; New-Item -ItemType Directory -Force $rep | Out-Null
$http = Join-Path $rep 'http7001.jsonl'
if(-not (Test-Path $http)){ return }

$lines = Get-Content -LiteralPath $http -Tail $WindowLines -ErrorAction SilentlyContinue
$tot=0; $err=0
foreach($line in $lines){
  $o=$null; try{ $o=$line | ConvertFrom-Json }catch{}
  if($o -and $o.kind -eq 'http7001' -and $o.status -ne $null){
    $tot++
    if( ($o.status -as [int]) -ge 500 ){ $err++ }
  }
}
if($tot -ge $MinSamples){
  $pct = if($tot -gt 0){ [math]::Round(($err/$tot)*100,2) } else { 0 }
  if($pct -ge $ThresholdPct){
    $obj = @{
      ts=(Get-Date).ToString('s'); kind='alert'; subtype='error_rate'
      message=("5xx rate {0}% (err={1}, total={2}) >= {3}%" -f $pct,$err,$tot,$ThresholdPct)
      err=$err; total=$tot; pct=$pct; threshold_pct=$ThresholdPct
    }
    Write-Alert -obj $obj -DedupMinutes 10 -DedupKey 'error_rate'
  }
}
