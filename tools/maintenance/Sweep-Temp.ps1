param([int]$TtlDays=7)
$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base=Split-Path -Parent $PSCommandPath }
$cut = (Get-Date).AddDays(-$TtlDays)
$targets = @(
  (Join-Path $env:TEMP '*'),
  (Join-Path $Base 'logs\*'),
  (Join-Path $Base 'reports\*.tmp')
)
foreach($g in $targets){
  try{
    Get-ChildItem $g -Recurse -ErrorAction SilentlyContinue |
      Where-Object { -not $_.PSIsContainer -and $_.LastWriteTime -lt $cut } |
      ForEach-Object {
        try{ Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }catch{}
      }
  }catch{}
}
