param([int]$Port=7003,[string]$Root=$env:MASON2_BASE)
$ErrorActionPreference = "SilentlyContinue"

# Reserve URL (ok if already exists)
try { & netsh http add urlacl url=("http://+:{0}/" -f $Port) user="Everyone" | Out-Null } catch {}

$prefix = "http://+:{0}/" -f $Port
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
$listener.Start()

function Get-Mime([string]$ext){
  switch ($ext.ToLower()) {
    '.html' { 'text/html' }
    '.htm'  { 'text/html' }
    '.js'   { 'application/javascript' }
    '.css'  { 'text/css' }
    '.json' { 'application/json' }
    '.svg'  { 'image/svg+xml' }
    '.png'  { 'image/png' }
    '.jpg'  { 'image/jpeg' }
    '.jpeg' { 'image/jpeg' }
    default { 'application/octet-stream' }
  }
}

while ($true) {
  $ctx = $listener.GetContext()
  try {
    $path = $ctx.Request.Url.AbsolutePath
    $rel  = [Uri]::UnescapeDataString($path.TrimStart('/'))
    if ([string]::IsNullOrWhiteSpace($rel)) { $rel = 'index.html' }
    if ($rel.EndsWith('/')) { $rel += 'index.html' }

    # prevent path traversal
    $rel = $rel -replace '\\','/'
    if ($rel -match '^\.\.(/|$)') { $ctx.Response.StatusCode = 400; $ctx.Response.Close(); continue }

    $file = Join-Path $Root $rel
    if (-not (Test-Path $file)) {
      $ctx.Response.StatusCode = 404
      $bytes = [Text.Encoding]::UTF8.GetBytes("404 Not Found: /$rel")
      $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length)
      $ctx.Response.Close()
      continue
    }

    $bytes = [IO.File]::ReadAllBytes($file)
    $ctx.Response.StatusCode = 200
    $ctx.Response.ContentType = Get-Mime ([IO.Path]::GetExtension($file))
    $ctx.Response.ContentLength64 = $bytes.Length
    $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length)
    $ctx.Response.OutputStream.Close()
  } catch {
    try {
      $ctx.Response.StatusCode = 500
      $msg = "500 Server Error"
      $bytes = [Text.Encoding]::UTF8.GetBytes($msg)
      $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length)
      $ctx.Response.Close()
    } catch {}
  }
}