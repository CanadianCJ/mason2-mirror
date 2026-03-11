$ErrorActionPreference = "Stop"
$Base    = "$env:USERPROFILE\Desktop\ONYX"
$ManDir  = Join-Path $Base 'manifests'
$Ignore  = '(?i)[\\/](node_modules|dist|build|\.venv|\.git|\.next|out|coverage)([\\/]|$)'
New-Item -ItemType Directory -Path $ManDir -EA SilentlyContinue | Out-Null

# tree.txt
Get-ChildItem -Path $Base -Recurse -Directory -EA SilentlyContinue |
  Where-Object { $_.FullName -notmatch $Ignore } |
  ForEach-Object { $_.FullName.Substring($Base.Length+1) } |
  Set-Content (Join-Path $Base 'tree.txt') -Encoding UTF8

# manifest.json
$files = Get-ChildItem -Path $Base -Recurse -File -EA SilentlyContinue |
  Where-Object { $_.FullName -notmatch $Ignore }
$manifest = $files | ForEach-Object {
  [pscustomobject]@{
    path   = $_.FullName.Substring($Base.Length+1)
    bytes  = $_.Length
    sha256 = (Get-FileHash -Algorithm SHA256 -Path $_.FullName).Hash
    mtime  = $_.LastWriteTimeUtc.ToString('s')
  }
}
$cur   = Join-Path $Base 'manifest.json'
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$copy  = Join-Path $ManDir ("manifest_{0}.json" -f $stamp)
$manifest | ConvertTo-Json -Depth 4 | Tee-Object -FilePath $cur | Set-Content -Path $copy -Encoding UTF8

# prune old (keep last 30)
$snaps = Get-ChildItem "$ManDir\manifest_*.json" | Sort-Object Name
if($snaps.Count -gt 30){ $snaps | Select-Object -First ($snaps.Count - 30) | Remove-Item -Force }
$snaps = Get-ChildItem "$ManDir\manifest_*.json" | Sort-Object Name

# diff vs previous
if($snaps.Count -ge 2){
  $m1 = $snaps | Select-Object -Last 2 | Select-Object -First 1 -ExpandProperty FullName
  $m2 = $snaps | Select-Object -Last 1  -ExpandProperty FullName

  function Read-Manifest($path){
    $j = Get-Content $path -Raw | ConvertFrom-Json
    if($j -isnot [System.Collections.IEnumerable]){ $j = ,$j }
    $j | Where-Object { $_ -ne $null -and $_.PSObject.Properties['path'] -and $_.path }
  }
  $a = Read-Manifest $m1; $b = Read-Manifest $m2
  $A = @{}; foreach($f in $a){ $A[$f.path] = $f }
  $B = @{}; foreach($f in $b){ $B[$f.path] = $f }

  $added   = $B.Keys | Where-Object { -not $A.ContainsKey($_) }
  $removed = $A.Keys | Where-Object { -not $B.ContainsKey($_) }
  $changed = $B.Keys | Where-Object { $A.ContainsKey($_) -and $A[$_].sha256 -ne $B[$_].sha256 }

  $summary = [pscustomobject]@{ stamp=$stamp; added=$added.Count; removed=$removed.Count; changed=$changed.Count }
  $summary | ConvertTo-Json -Compress | Set-Content (Join-Path $ManDir 'last_summary.json') -Encoding UTF8

  $diffFile = Join-Path $ManDir ("diff_{0}.txt" -f $stamp)
  $out = @()
  $out += "Snapshot: $stamp"
  $out += "Added:   $($added.Count)"
  $out += "Removed: $($removed.Count)"
  $out += "Changed: $($changed.Count)"
  $out += ""
  if($added)   { $out += "== Added (max 50) ==";   $out += ($added   | Select-Object -First 50); $out += "" }
  if($removed) { $out += "== Removed (max 50) =="; $out += ($removed | Select-Object -First 50); $out += "" }
  if($changed) { $out += "== Changed (max 50) =="; $out += ($changed | Select-Object -First 50); $out += "" }
  Set-Content $diffFile $out -Encoding UTF8

  Write-Host ("Snapshot {0}: +{1}  -{2}  Δ{3}  → {4}" -f $stamp,$added.Count,$removed.Count,$changed.Count,$diffFile)
} else {
  Write-Host "Snapshot $stamp created (first snapshot, nothing to diff yet)."
}
