param([int]$MaxMB = 10, [int]$Keep = 5)

$Base = $env:MASON2_BASE
if ([string]::IsNullOrWhiteSpace($Base)) { $Base = Split-Path -Parent $PSCommandPath }

. (Join-Path $Base 'tools\common\Breadcrumb.ps1') 2>$null

$rep = Join-Path $Base 'reports'
New-Item -ItemType Directory -Force $rep | Out-Null
$f   = Join-Path $rep 'breadcrumbs.jsonl'
if (-not (Test-Path $f)) { return }

$sizeMB = [math]::Round((Get-Item -LiteralPath $f).Length / 1MB, 2)
if ($sizeMB -lt $MaxMB) { return }

$stamp = Get-Date -Format 'yyyyMMddHHmmss'
$tmp   = Join-Path $rep ("breadcrumbs_{0}.jsonl" -f $stamp)
$zip   = Join-Path $rep ("breadcrumbs_{0}.zip"    -f $stamp)

try {
  Copy-Item -LiteralPath $f -Destination $tmp -Force

  if (Get-Command Compress-Archive -ErrorAction SilentlyContinue) {
    Compress-Archive -LiteralPath $tmp -DestinationPath $zip -Force
  } else {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $z = [System.IO.Compression.ZipFile]::Open($zip, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
      $null = $z.CreateEntryFromFile($tmp, [IO.Path]::GetFileName($tmp), [System.IO.Compression.CompressionLevel]::Optimal)
    } finally {
      $z.Dispose()
    }
  }

  Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
  Clear-Content -LiteralPath $f

  Get-ChildItem -LiteralPath $rep -Filter 'breadcrumbs_*.zip' |
    Sort-Object LastWriteTime -Descending |
    Select-Object -Skip $Keep |
    Remove-Item -Force -ErrorAction SilentlyContinue

  try {
    if (Get-Command Write-Breadcrumb -ErrorAction SilentlyContinue) {
      Write-Breadcrumb -action 'breadcrumbs.rotate' -meta @{ size_mb = $sizeMB; zip = [IO.Path]::GetFileName($zip); keep = $Keep }
    }
  } catch {}
} catch {
  try {
    if (Test-Path $tmp) {
      Move-Item -LiteralPath $tmp -Destination ($zip + '.failedcopy.jsonl') -Force
    }
  } catch {}
}
