param(
  [Parameter(Mandatory=$true)][string]$Path,
  [int]$MaxLines=50000,
  [int]$KeepTail=40000
)
$ErrorActionPreference='SilentlyContinue'
function Write-Utf8NoBom([string]$p,[string]$t){ $enc = New-Object System.Text.UTF8Encoding($false); [IO.File]::WriteAllText($p,$t,$enc) }
if(-not (Test-Path $Path)){ return }
$lines = Get-Content -LiteralPath $Path
if(-not $lines){ return }
if($lines.Count -gt $MaxLines){
  $tail = ($lines | Select-Object -Last $KeepTail) -join "`n"
  Write-Utf8NoBom $Path $tail
  Write-Output "[LogRotate] Truncated $Path to last $KeepTail lines."
}
