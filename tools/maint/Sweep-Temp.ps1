param([int]$Days=3,[int]$MaxMB=512)
$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base=Split-Path -Parent $PSCommandPath }
$targets = @(
  $env:TEMP,
  (Join-Path $Base 'temp'),
  (Join-Path $Base 'cache')
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique

$cut = (Get-Date).AddDays(-$Days)
foreach($t in $targets){
  try{
    # delete files older than $Days
    Get-ChildItem -LiteralPath $t -Recurse -Force -ErrorAction SilentlyContinue |
      Where-Object { -not $_.PSIsContainer -and $_.LastWriteTime -lt $cut } |
      Remove-Item -Force -ErrorAction SilentlyContinue

    # soft cap folder size
    $limit = $MaxMB * 1MB
    $files = Get-ChildItem -LiteralPath $t -Recurse -Force -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime
    $size  = ($files | Measure-Object Length -Sum).Sum
    foreach($f in $files){
      if($size -le $limit){ break }
      try{ $len=$f.Length; Remove-Item -LiteralPath $f.FullName -Force -ErrorAction SilentlyContinue; $size-=$len }catch{}
    }
  }catch{}
}
