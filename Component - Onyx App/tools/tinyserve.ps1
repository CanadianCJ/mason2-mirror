param([int]$Port=5175,[string]$Root="")
$ErrorActionPreference="SilentlyContinue"
if(-not $Root -or -not (Test-Path $Root)){ $Root = Join-Path $env:USERPROFILE "Desktop\ONYX\onyx-web\dist" }

Add-Type -AssemblyName System.Net.HttpListener
$h = [System.Net.HttpListener]::new()
$h.Prefixes.Add("http://127.0.0.1:$Port/")
$h.Start()
try {
  while ($h.IsListening) {
    $ctx = $h.GetContext()
    $path = $ctx.Request.Url.AbsolutePath.TrimStart('/')
    if([string]::IsNullOrWhiteSpace($path)){ $path = "index.html" }
    $full = Join-Path $Root $path
    if(-not (Test-Path $full)){ $full = Join-Path $Root "index.html" }
    try{
      $bytes = [System.IO.File]::ReadAllBytes($full)
      $ctx.Response.StatusCode = 200
      $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length)
    } catch {
      $ctx.Response.StatusCode = 404
    } finally {
      $ctx.Response.OutputStream.Close()
    }
  }
} finally { $h.Stop() }
