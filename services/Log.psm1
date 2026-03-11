# Mason2-Version: 1.0.1
param()

function New-CorrId { [guid]::NewGuid().ToString("N") }

function Redact-PII {
  param([string]$s)
  if ([string]::IsNullOrEmpty($s)) { return $s }
  # email
  $s = $s -replace '([A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,})','[redacted-email]'
  # phone-ish
  $s = $s -replace '(\+?\d[\d\-\s]{7,}\d)','[redacted-phone]'
  # credit-card-ish
  $s = $s -replace '\b(\d{4}[-\s]?){3}\d{4}\b','[redacted-card]'
  return $s
}

function Write-JsonLog {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][string]$Component,
    [ValidateSet('TRACE','DEBUG','INFO','WARN','ERROR')][string]$Level='INFO',
    [Parameter(Mandatory=$true)][string]$Message,
    [Hashtable]$Props
  )

  $Base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
  $dir  = Join-Path $Base ("logs\" + $Component)
  ni $dir -ItemType Directory -ea SilentlyContinue | Out-Null
  $file = Join-Path $dir ((Get-Date -Format 'yyyy-MM-dd') + '.jsonl')

  # rotate >5MB
  if((Test-Path $file) -and ((Get-Item $file).Length -gt 5MB)){
    $idx = (Get-ChildItem $dir -Filter ((Split-Path $file -Leaf) + '.*') -ea SilentlyContinue | Measure-Object).Count + 1
    Move-Item $file "$file.$idx" -Force
  }

  $evt = [ordered]@{
    ts        = (Get-Date).ToString('o')
    level     = $Level
    component = $Component
    msg       = (Redact-PII $Message)
    corr      = (New-CorrId)
    pid       = $PID
    user      = $env:USERNAME
  }
  if($Props){
    foreach($k in $Props.Keys){
      $evt["prop_$k"] = Redact-PII ($Props[$k] -as [string])
    }
  }
  ($evt | ConvertTo-Json -Compress) | Add-Content -LiteralPath $file -Encoding UTF8
}

Export-ModuleMember -Function Write-JsonLog,New-CorrId,Redact-PII
