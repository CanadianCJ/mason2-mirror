param([int]$TimeoutSec=3)

$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base=Split-Path -Parent $PSCommandPath }
. (Join-Path $Base 'tools\common\Alert.ps1') 2>$null

$okIcmp = $false; $okDns = $false; $okHttp = $false

# ICMP to 1.1.1.1 (quick)
try{ $okIcmp = Test-Connection -ComputerName 1.1.1.1 -Count 1 -Quiet -TimeoutSeconds $TimeoutSec }catch{}

# DNS resolve (fallback to .NET if Resolve-DnsName missing)
try{
  if(Get-Command Resolve-DnsName -ErrorAction SilentlyContinue){
    $okDns = @(Resolve-DnsName 'www.microsoft.com' -ErrorAction Stop | Where-Object Type -in A,AAAA).Count -gt 0
  }else{
    [void][System.Net.Dns]::GetHostEntry('www.microsoft.com'); $okDns=$true
  }
}catch{}

# HTTP (tiny probe)
try{
  $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec $TimeoutSec 'http://www.msftconnecttest.com/connecttest.txt'
  $okHttp = ($r.StatusCode -as [int]) -eq 200
}catch{}

if(-not ($okIcmp -or $okDns -or $okHttp)){
  $obj = @{
    ts=(Get-Date).ToString('s'); kind='alert'; subtype='net_down'
    icmp=$okIcmp; dns=$okDns; http=$okHttp
    message='Network check failed: ICMP/DNS/HTTP all false'
  }
  Write-Alert -obj $obj -DedupMinutes 15 -DedupKey 'net_down'
}
