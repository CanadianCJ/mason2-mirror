Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Net.psm1") -Force
$Base = "$env:USERPROFILE\Desktop\Mason2"
$result = @{ http=$null; health=$null; sockets=$null; tasks=$null; ready=$null }

# http.sys
$result.http = (sc.exe query http) -join "`n"

# healthz + metrics with retry
$h = '' ; $m = ''
try { $h = (Invoke-MasonHttp -Uri 'http://127.0.0.1:7001/healthz' -TimeoutSec 3 -Retries 2).Content.Trim() } catch {}
try { $m = (Invoke-MasonHttp -Uri 'http://127.0.0.1:7001/metrics.json' -TimeoutSec 3 -Retries 2).Content } catch {}
$metrics = if ([string]::IsNullOrEmpty($m)) { 'fail' } else { 'ok' }
$result.health = @{ healthz=$h; metrics=$metrics }

# sockets
$result.sockets = (Get-NetTCPConnection -State Listen -LocalPort 7001) | Select-Object LocalAddress,LocalPort,State

# tasks
$result.tasks = @(schtasks /Query /TN "Mason2-FileServer-7001" /FO LIST 2>$null)

# readiness
$readyExit = 0
try { & (Join-Path $Base 'tools\Mason_Readiness_7001.ps1'); $readyExit = $LASTEXITCODE } catch { $readyExit = 1 }
$result.ready = @{ exit=$readyExit }

# write
$path = Join-Path $Base 'reports\smoketest_boot.json'
$result | ConvertTo-Json -Depth 6 | Set-Content $path
Out-MasonJsonl -Kind 'smoke' -Event 'boot' -Level 'INFO' -Data $result
Write-Host "Smoke test written to $path"_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseImport-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Net.psm1") -Force
$Base = "$env:USERPROFILE\Desktop\Mason2"
$result = @{ http=$null; health=$null; sockets=$null; tasks=$null; ready=$null }

# http.sys
$result.http = (sc.exe query http) -join "`n"

# healthz + metrics with retry
$h = '' ; $m = ''
try { $h = (Invoke-MasonHttp -Uri 'http://127.0.0.1:7001/healthz' -TimeoutSec 3 -Retries 2).Content.Trim() } catch {}
try { $m = (Invoke-MasonHttp -Uri 'http://127.0.0.1:7001/metrics.json' -TimeoutSec 3 -Retries 2).Content } catch {}
$metrics = if ([string]::IsNullOrEmpty($m)) { 'fail' } else { 'ok' }
$result.health = @{ healthz=$h; metrics=$metrics }

# sockets
$result.sockets = (Get-NetTCPConnection -State Listen -LocalPort 7001) | Select-Object LocalAddress,LocalPort,State

# tasks
$result.tasks = @(schtasks /Query /TN "Mason2-FileServer-7001" /FO LIST 2>$null)

# readiness
$readyExit = 0
try { & (Join-Path $Base 'tools\Mason_Readiness_7001.ps1'); $readyExit = $LASTEXITCODE } catch { $readyExit = 1 }
$result.ready = @{ exit=$readyExit }

# write
$path = Join-Path $Base 'reports\smoketest_boot.json'
$result | ConvertTo-Json -Depth 6 | Set-Content $path
Out-MasonJsonl -Kind 'smoke' -Event 'boot' -Level 'INFO' -Data $result
Write-Host "Smoke test written to $path"_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseImport-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Net.psm1") -Force
$Base = "$env:USERPROFILE\Desktop\Mason2"
$result = @{ http=$null; health=$null; sockets=$null; tasks=$null; ready=$null }

# http.sys
$result.http = (sc.exe query http) -join "`n"

# healthz + metrics with retry
$h = '' ; $m = ''
try { $h = (Invoke-MasonHttp -Uri 'http://127.0.0.1:7001/healthz' -TimeoutSec 3 -Retries 2).Content.Trim() } catch {}
try { $m = (Invoke-MasonHttp -Uri 'http://127.0.0.1:7001/metrics.json' -TimeoutSec 3 -Retries 2).Content } catch {}
$metrics = if ([string]::IsNullOrEmpty($m)) { 'fail' } else { 'ok' }
$result.health = @{ healthz=$h; metrics=$metrics }

# sockets
$result.sockets = (Get-NetTCPConnection -State Listen -LocalPort 7001) | Select-Object LocalAddress,LocalPort,State

# tasks
$result.tasks = @(schtasks /Query /TN "Mason2-FileServer-7001" /FO LIST 2>$null)

# readiness
$readyExit = 0
try { & (Join-Path $Base 'tools\Mason_Readiness_7001.ps1'); $readyExit = $LASTEXITCODE } catch { $readyExit = 1 }
$result.ready = @{ exit=$readyExit }

# write
$path = Join-Path $Base 'reports\smoketest_boot.json'
$result | ConvertTo-Json -Depth 6 | Set-Content $path
Out-MasonJsonl -Kind 'smoke' -Event 'boot' -Level 'INFO' -Data $result
Write-Host "Smoke test written to $path"_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseImport-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Net.psm1") -Force
$Base = "$env:USERPROFILE\Desktop\Mason2"
$result = @{ http=$null; health=$null; sockets=$null; tasks=$null; ready=$null }

# http.sys
$result.http = (sc.exe query http) -join "`n"

# healthz + metrics with retry
$h = '' ; $m = ''
try { $h = (Invoke-MasonHttp -Uri 'http://127.0.0.1:7001/healthz' -TimeoutSec 3 -Retries 2).Content.Trim() } catch {}
try { $m = (Invoke-MasonHttp -Uri 'http://127.0.0.1:7001/metrics.json' -TimeoutSec 3 -Retries 2).Content } catch {}
$metrics = if ([string]::IsNullOrEmpty($m)) { 'fail' } else { 'ok' }
$result.health = @{ healthz=$h; metrics=$metrics }

# sockets
$result.sockets = (Get-NetTCPConnection -State Listen -LocalPort 7001) | Select-Object LocalAddress,LocalPort,State

# tasks
$result.tasks = @(schtasks /Query /TN "Mason2-FileServer-7001" /FO LIST 2>$null)

# readiness
$readyExit = 0
try { & (Join-Path $Base 'tools\Mason_Readiness_7001.ps1'); $readyExit = $LASTEXITCODE } catch { $readyExit = 1 }
$result.ready = @{ exit=$readyExit }

# write
$path = Join-Path $Base 'reports\smoketest_boot.json'
$result | ConvertTo-Json -Depth 6 | Set-Content $path
Out-MasonJsonl -Kind 'smoke' -Event 'boot' -Level 'INFO' -Data $result
Write-Host "Smoke test written to $path"_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseImport-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Net.psm1") -Force
$Base = "$env:USERPROFILE\Desktop\Mason2"
$result = @{ http=$null; health=$null; sockets=$null; tasks=$null; ready=$null }

# http.sys
$result.http = (sc.exe query http) -join "`n"

# healthz + metrics with retry
$h = '' ; $m = ''
try { $h = (Invoke-MasonHttp -Uri 'http://127.0.0.1:7001/healthz' -TimeoutSec 3 -Retries 2).Content.Trim() } catch {}
try { $m = (Invoke-MasonHttp -Uri 'http://127.0.0.1:7001/metrics.json' -TimeoutSec 3 -Retries 2).Content } catch {}
$metrics = if ([string]::IsNullOrEmpty($m)) { 'fail' } else { 'ok' }
$result.health = @{ healthz=$h; metrics=$metrics }

# sockets
$result.sockets = (Get-NetTCPConnection -State Listen -LocalPort 7001) | Select-Object LocalAddress,LocalPort,State

# tasks
$result.tasks = @(schtasks /Query /TN "Mason2-FileServer-7001" /FO LIST 2>$null)

# readiness
$readyExit = 0
try { & (Join-Path $Base 'tools\Mason_Readiness_7001.ps1'); $readyExit = $LASTEXITCODE } catch { $readyExit = 1 }
$result.ready = @{ exit=$readyExit }

# write
$path = Join-Path $Base 'reports\smoketest_boot.json'
$result | ConvertTo-Json -Depth 6 | Set-Content $path
Out-MasonJsonl -Kind 'smoke' -Event 'boot' -Level 'INFO' -Data $result
Write-Host "Smoke test written to $path"_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseImport-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Net.psm1") -Force
$Base = "$env:USERPROFILE\Desktop\Mason2"
$result = @{ http=$null; health=$null; sockets=$null; tasks=$null; ready=$null }

# http.sys
$result.http = (sc.exe query http) -join "`n"

# healthz + metrics with retry
$h = '' ; $m = ''
try { $h = (Invoke-MasonHttp -Uri 'http://127.0.0.1:7001/healthz' -TimeoutSec 3 -Retries 2).Content.Trim() } catch {}
try { $m = (Invoke-MasonHttp -Uri 'http://127.0.0.1:7001/metrics.json' -TimeoutSec 3 -Retries 2).Content } catch {}
$metrics = if ([string]::IsNullOrEmpty($m)) { 'fail' } else { 'ok' }
$result.health = @{ healthz=$h; metrics=$metrics }

# sockets
$result.sockets = (Get-NetTCPConnection -State Listen -LocalPort 7001) | Select-Object LocalAddress,LocalPort,State

# tasks
$result.tasks = @(schtasks /Query /TN "Mason2-FileServer-7001" /FO LIST 2>$null)

# readiness
$readyExit = 0
try { & (Join-Path $Base 'tools\Mason_Readiness_7001.ps1'); $readyExit = $LASTEXITCODE } catch { $readyExit = 1 }
$result.ready = @{ exit=$readyExit }

# write
$path = Join-Path $Base 'reports\smoketest_boot.json'
$result | ConvertTo-Json -Depth 6 | Set-Content $path
Out-MasonJsonl -Kind 'smoke' -Event 'boot' -Level 'INFO' -Data $result
Write-Host "Smoke test written to $path"_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseImport-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Net.psm1") -Force
$Base = "$env:USERPROFILE\Desktop\Mason2"
$result = @{ http=$null; health=$null; sockets=$null; tasks=$null; ready=$null }

# http.sys
$result.http = (sc.exe query http) -join "`n"

# healthz + metrics with retry
$h = '' ; $m = ''
try { $h = (Invoke-MasonHttp -Uri 'http://127.0.0.1:7001/healthz' -TimeoutSec 3 -Retries 2).Content.Trim() } catch {}
try { $m = (Invoke-MasonHttp -Uri 'http://127.0.0.1:7001/metrics.json' -TimeoutSec 3 -Retries 2).Content } catch {}
$metrics = if ([string]::IsNullOrEmpty($m)) { 'fail' } else { 'ok' }
$result.health = @{ healthz=$h; metrics=$metrics }

# sockets
$result.sockets = (Get-NetTCPConnection -State Listen -LocalPort 7001) | Select-Object LocalAddress,LocalPort,State

# tasks
$result.tasks = @(schtasks /Query /TN "Mason2-FileServer-7001" /FO LIST 2>$null)

# readiness
$readyExit = 0
try { & (Join-Path $Base 'tools\Mason_Readiness_7001.ps1'); $readyExit = $LASTEXITCODE } catch { $readyExit = 1 }
$result.ready = @{ exit=$readyExit }

# write
$path = Join-Path $Base 'reports\smoketest_boot.json'
$result | ConvertTo-Json -Depth 6 | Set-Content $path
Out-MasonJsonl -Kind 'smoke' -Event 'boot' -Level 'INFO' -Data $result
Write-Host "Smoke test written to $path"_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Net.psm1") -Force
$Base = "$env:USERPROFILE\Desktop\Mason2"
$result = @{ http=$null; health=$null; sockets=$null; tasks=$null; ready=$null }

# http.sys
$result.http = (sc.exe query http) -join "`n"

# healthz + metrics with retry
$h = '' ; $m = ''
try { $h = (Invoke-MasonHttp -Uri 'http://127.0.0.1:7001/healthz' -TimeoutSec 3 -Retries 2).Content.Trim() } catch {}
try { $m = (Invoke-MasonHttp -Uri 'http://127.0.0.1:7001/metrics.json' -TimeoutSec 3 -Retries 2).Content } catch {}
$metrics = if ([string]::IsNullOrEmpty($m)) { 'fail' } else { 'ok' }
$result.health = @{ healthz=$h; metrics=$metrics }

# sockets
$result.sockets = (Get-NetTCPConnection -State Listen -LocalPort 7001) | Select-Object LocalAddress,LocalPort,State

# tasks
$result.tasks = @(schtasks /Query /TN "Mason2-FileServer-7001" /FO LIST 2>$null)

# readiness
$readyExit = 0
try { & (Join-Path $Base 'tools\Mason_Readiness_7001.ps1'); $readyExit = $LASTEXITCODE } catch { $readyExit = 1 }
$result.ready = @{ exit=$readyExit }

# write
$path = Join-Path $Base 'reports\smoketest_boot.json'
$result | ConvertTo-Json -Depth 6 | Set-Content $path
Out-MasonJsonl -Kind 'smoke' -Event 'boot' -Level 'INFO' -Data $result
Write-Host "Smoke test written to $path"