param(
  [int]$MaxMB    = 10,   # rotate when file > MaxMB
  [int]$Keep     = 5,    # keep N .N backups
  [string]$Glob  = "*.jsonl"
)
$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base=Split-Path -Parent $PSCommandPath }
$rep = Join-Path $Base 'reports'; if(-not(Test-Path $rep)){ return }
$limit = $MaxMB * 1MB

Get-ChildItem -LiteralPath $rep -Filter $Glob -File -ErrorAction SilentlyContinue | ForEach-Object {
  $f = $_.FullName
  try{
    if((Get-Item $f).Length -gt $limit){
      # shift old backups: .(Keep-1) -> .Keep, …, .1 -> .2
      for($i=$Keep-1; $i -ge 1; $i--){
        $src = "$f.$i"; $dst = "$f." + ($i+1)
        if(Test-Path $src){ Move-Item $src $dst -Force }
      }
      # current -> .1
      Move-Item $f "$f.1" -Force
      # recreate empty
      New-Item -ItemType File -Path $f -Force | Out-Null
    }
  }catch{}
}
