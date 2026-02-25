$tasks = @('Mason-7001','Mason-NodeAgent','Mason-Mon-Net','Mason-Mon-Time','Mason-Mon-CPU','Mason-Mon-MEM','Mason-DiskHealth','Mason-DailySnapshot')
foreach($name in $tasks){
  try { Unregister-ScheduledTask -TaskName $name -Confirm:$false -ErrorAction Stop; Write-Host "Removed task $name" } catch {}
}
# URLACLs (admin recommended)
foreach($u in @('http://localhost:7001/','http://127.0.0.1:7001/','http://[::1]:7001/')){
  try { netsh http delete urlacl url=$u *> $null; Write-Host "Deleted URLACL $u" } catch {}
}
Write-Host "Uninstall complete (logs/reports kept)."
