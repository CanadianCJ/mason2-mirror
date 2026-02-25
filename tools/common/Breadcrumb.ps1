function Write-Breadcrumb {
  param([string]$action,[hashtable]$meta)
  try{
    $Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base=Split-Path -Parent $PSCommandPath }
    $rep = Join-Path $Base 'reports'; New-Item -ItemType Directory -Force $rep | Out-Null
    $p   = Join-Path $rep 'breadcrumbs.jsonl'
    $o   = @{ ts=(Get-Date).ToString('s'); kind='crumb'; action=$action; meta=$meta; v=1 }
    ($o | ConvertTo-Json -Compress) | Add-Content -LiteralPath $p -Encoding UTF8
  }catch{}
}
