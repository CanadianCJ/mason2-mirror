$base="$env:MASON2_BASE"; $q=Join-Path $base 'queue\retry'
Get-ChildItem $q -File -Filter *.json -ErrorAction SilentlyContinue | Select -First 20 | %{
  Remove-Item $_.FullName -Force
}