function Convert-LastTaskResult {
  param([int]$Code)

  $map = @{
    0       = 'SUCCESS'
    267008  = 'SCHED_S_TASK_READY (Ready)'
    267009  = 'SCHED_S_TASK_RUNNING (Running)'
    267010  = 'SCHED_S_TASK_QUEUED/NOT_SCHEDULED'
    267011  = 'SCHED_S_TASK_HAS_NOT_RUN'
    267012  = 'SCHED_S_TASK_TERMINATED/NO_MORE_RUNS'
    267014  = 'SCHED_S_TASK_TERMINATED'
    267015  = 'SCHED_S_TASK_NO_VALID_TRIGGERS'
  }

  $hex = ('0x{0:X8}' -f ($Code -band 0xFFFFFFFF))
  $txt = $map[$Code]
  if (-not $txt -and $Code -ge 2147483648) { $txt = 'WIN32/HRESULT (non-zero)' }

  [pscustomobject]@{
    code = $Code
    hex  = $hex
    text = $txt
  }
}

function Get-MasonTaskStatus {
  param(
    [string[]]$Name = @('Mason-*')
  )

  # Expand patterns like Mason-* to actual task names
  $names = @()
  foreach ($n in $Name) {
    if ($n -like 'Mason-*') {
      $ts = Get-ScheduledTask -TaskName $n -ErrorAction SilentlyContinue
      if ($ts) { $names += ($ts | Select -Expand TaskName) }
    } else {
      $names += $n
    }
  }
  $names = $names | Sort-Object -Unique

  foreach ($n in $names) {
    try {
      $t   = Get-ScheduledTask -TaskName $n -ErrorAction Stop
      $i   = Get-ScheduledTaskInfo -TaskName $n -ErrorAction Stop
      $act = $t.Actions[0]
      $res = Convert-LastTaskResult -Code $i.LastTaskResult

      # PS 5.1-safe date strings (no ternary)
      $lastStr = $null
      $nextStr = $null
      try { if ($i.LastRunTime) { $lastStr = $i.LastRunTime.ToString('s') } } catch {}
      try { if ($i.NextRunTime) { $nextStr = $i.NextRunTime.ToString('s') } } catch {}

      [pscustomobject]@{
        Task           = $n
        State          = $t.State
        Last           = $lastStr
        Next           = $nextStr
        LastResult     = $res.text
        LastResultCode = $res.code
        LastResultHex  = $res.hex
        Exec           = $act.Execute
        Args           = $act.Arguments
      }
    } catch {
      [pscustomobject]@{
        Task           = $n
        State          = '(missing)'
        Last           = $null
        Next           = $null
        LastResult     = '(n/a)'
        LastResultCode = $null
        LastResultHex  = $null
        Exec           = $null
        Args           = $null
      }
    }
  }
}
