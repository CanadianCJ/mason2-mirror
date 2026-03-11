param(
    [int]$Port = 5353
)

$projectPath = "C:\Users\Chris\Desktop\Onyx\onyx_business_manager"
$flutterBat  = "C:\src\flutter\bin\flutter.bat"

$ErrorActionPreference = "Stop"

Write-Host "=== Onyx Web Runner ==="
Write-Host "Project: $projectPath"
Write-Host "Port:    $Port"
Write-Host ""

Set-Location $projectPath

# Make sure packages are in sync (cheap if already done)
& $flutterBat pub get

# Run Flutter web server
& $flutterBat run -d web-server --web-port $Port
