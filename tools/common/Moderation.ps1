param()

function Test-PII {
  param([string]$text)
  if(-not $text){ return $false }
  $re = @{
    email = '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
    phone = '(?<!\d)(\+?\d[\d\-\s\(\)]{6,}\d)(?!\d)'
    ipv4  = '(?<!\d)(?:\d{1,3}\.){3}\d{1,3}(?!\d)'
  }
  return ($text -match $re.email -or $text -match $re.phone -or $text -match $re.ipv4)
}

function Moderate-Text {
  param([string]$Text, [string]$Source='unknown')
  if(-not $Text){ return }
  try{
    $Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base=Split-Path -Parent $PSCommandPath }
    . (Join-Path $Base 'tools\common\Alert.ps1') 2>$null

    $isPII = Test-PII $Text
    if($isPII){
      Write-Alert -obj @{ ts=(Get-Date).ToString('s'); kind='alert'; subtype='sensitive_data'; source=$Source; message='PII-like content detected' } -DedupMinutes 10 -DedupKey ("pii|{0}" -f $Source)
    }
  }catch{}
}
