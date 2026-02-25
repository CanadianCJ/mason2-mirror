param(
    [string]$Url = "http://127.0.0.1:8484/api/status",
    [string]$LogPath = "C:\Users\Chris\Desktop\Mason2\logs\athena_status.log"
)

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

try {
    $resp = Invoke-RestMethod -Uri $Url -Method Get -TimeoutSec 5

    $obj = [PSCustomObject]@{
        timestamp = $timestamp
        ok        = $resp.ok
        phase1    = $resp.phase1
        onyx      = $resp.onyx
        llm       = $resp.llm
    }

    $json = $obj | ConvertTo-Json -Depth 5 -Compress
    Add-Content -Path $LogPath -Value $json
}
catch {
    $msg = "[{0}][ERROR][Athena_Status_Snapshot] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $_
    Add-Content -Path $LogPath -Value $msg
}
