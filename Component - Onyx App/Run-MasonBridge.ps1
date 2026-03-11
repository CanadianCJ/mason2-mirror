param(
  [string]$AiUrl = "http://127.0.0.1:8123",
  [int]$Port = 8124,
  [string]$Log = "C:\Users\Chris\Desktop\Mason\MasonBridge.ps1.log"
)

function W($m){
  try{
    $t = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $d = Split-Path -Path $Log -EA SilentlyContinue
    if($d){ New-Item -ItemType Directory -Force -Path $d | Out-Null }
    "$t`t$m" | Out-File -FilePath $Log -Append -Encoding utf8
  }catch{}
}

Add-Type -AssemblyName System.Net.Http
$hc = [System.Net.Http.HttpClient]::new()
$listener = [System.Net.HttpListener]::new()
$prefix = "http://127.0.0.1:$Port/"
$listener.Prefixes.Add($prefix)

try{
  $listener.Start()
  W "Bridge listening on $prefix -> $AiUrl"

  while($true){
    $ctx = $listener.GetContext()
    $req = $ctx.Request
    $res = $ctx.Response
    try{
      $rawUrl = $req.RawUrl
      $method = $req.HttpMethod

      if ($method -eq 'GET' -and $rawUrl -eq '/health'){
        $bytes = [Text.Encoding]::UTF8.GetBytes('{"status":"ok"}')
        $res.ContentType = "application/json"
        $res.StatusCode = 200
        $res.OutputStream.Write($bytes,0,$bytes.Length)
        $res.Close()
        continue
      }

      # Proxy anything else to AI
      $target = ($AiUrl.TrimEnd('/')) + $rawUrl

      # Build outbound request
      $msg = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::new($method), $target)

      # Copy minimal headers (skip hop-by-hop)
      foreach($h in $req.Headers.AllKeys){
        if($h -in @('Host','Connection','Transfer-Encoding','Keep-Alive','Proxy-Authenticate','Proxy-Authorization','TE','Trailer','Upgrade')){ continue }
        try{ $msg.Headers.TryAddWithoutValidation($h, $req.Headers.GetValues($h)) | Out-Null }catch{}
      }

      # Body if present
      if($req.HasEntityBody){
        $ms = New-Object System.IO.MemoryStream
        $req.InputStream.CopyTo($ms)
        $ms.Position = 0
        $content = [System.Net.Http.ByteArrayContent]::new($ms.ToArray())
        if($req.ContentType){ $content.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse($req.ContentType) }
        $msg.Content = $content
      }

      $resp = $hc.SendAsync($msg).GetAwaiter().GetResult()
      $res.StatusCode = [int]$resp.StatusCode

      # Copy response headers
      foreach($h in $resp.Headers){
        $res.Headers[$h.Key] = [string]::Join(',', $h.Value)
      }
      if($resp.Content -and $resp.Content.Headers.ContentType){
        $res.ContentType = $resp.Content.Headers.ContentType.ToString()
      }

      $bytes = $resp.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
      $res.ContentLength64 = $bytes.Length
      $res.OutputStream.Write($bytes,0,$bytes.Length)
      $res.Close()
    }catch{
      W "ERROR handling $($req.HttpMethod) $($req.RawUrl): $($_.Exception.Message)"
      try{ $res.StatusCode = 502; $res.Close() }catch{}
    }
  }
}
catch{
  W "FATAL: $($_.Exception.Message)"
  throw
}
finally{
  try{ $listener.Stop(); $listener.Close() }catch{}
  try{ $hc.Dispose() }catch{}
}

