$state = Join-Path $env:MASON2_BASE 'state\stuck.json'
$now=[datetime]::UtcNow
$tbl=@{}
if(Test-Path $state){ try{ $tbl = Get-Content $state -Raw | ConvertFrom-Json }catch{} }
Get-ScheduledTask -TaskName 'Mason-*' -ErrorAction SilentlyContinue | %{
  $n=$_.TaskName; $info=Get-ScheduledTaskInfo -TaskName $n
  if($_.State -eq 'Running'){
    if(-not $tbl.$n){ $tbl.$n = $now.ToString('s') }
    else{
      $start=[datetime]$tbl.$n
      if(($now - $start).TotalMinutes -ge 10){
        $a=@{ts=(Get-Date).ToString('s'); kind='alert'; subtype='stuck_job'; task=$n}
        Add-Content (Join-Path $env:MASON2_BASE 'reports\alerts.jsonl') ($a|ConvertTo-Json -Compress)
      }
    }
  } else { if($tbl.$n){ $tbl.PSObject.Properties.Remove($n) | Out-Null } }
}
$tbl | ConvertTo-Json | Out-File $state -Encoding utf8