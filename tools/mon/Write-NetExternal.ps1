param(
  [string]$TargetHost = "www.google.com",
  [int]   $TimeoutMs  = 3000
)

# Prefer env base; fallback to script folder
$Base = $env:MASON2_BASE
if ([string]::IsNullOrWhiteSpace($Base)) { $Base = Split-Path -Parent $PSCommandPath }
$rep  = Join-Path $Base 'reports'
New-Item -ItemType Directory -Force $rep | Out-Null
$out  = Join-Path $rep 'net_external.jsonl'

# Force TLS 1.2 on PS 5.1
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

$dnsOk = $false
$httpsOk = $false
$latMs = -1

# DNS resolve
try {
  $null = [System.Net.Dns]::GetHostAddresses($TargetHost)
  $dnsOk = $true
} catch {
  $dnsOk = $false
}

# Quick TCP 443 check
try {
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  $tcp = New-Object System.Net.Sockets.TcpClient
  $iar = $tcp.BeginConnect($TargetHost, 443, $null, $null)
  if ($iar.AsyncWaitHandle.WaitOne($TimeoutMs)) {
    $tcp.EndConnect($iar)
    $tcp.Close()
  }
  $sw.Stop()
  if ($sw.ElapsedMilliseconds -gt 0) { $latMs = [int]$sw.ElapsedMilliseconds }
} catch { }

# HTTPS HEAD
try {
  $uri = "https://$TargetHost/"
  $req = [System.Net.HttpWebRequest]::Create($uri)
  $req.Method = "HEAD"
  $req.Timeout = $TimeoutMs
  $req.AllowAutoRedirect = $true
  $req.UserAgent = "MasonNetProbe/1.0"
  $res = $req.GetResponse()
  $httpsOk = $true
  $res.Close()
} catch {
  $httpsOk = $false
}

$rec = @{
  ts    = (Get-Date).ToString('s')
  host  = $TargetHost
  dns   = $dnsOk
  https = $httpsOk
  ms    = $latMs
}
($rec | ConvertTo-Json -Compress) | Add-Content -LiteralPath $out -Encoding utf8
