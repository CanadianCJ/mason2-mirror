$ErrorActionPreference = "Stop"
$here = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent "$($MyInvocation.MyCommand.Path)" }
Set-Location $here

# Use the project-bundled Expo CLI, not any old global
$env:EXPO_USE_LOCAL_CLI = "1"

# Point the app at the local API (change later to your deployed URL)
if (-not $env:EXPO_PUBLIC_API_BASE) { $env:EXPO_PUBLIC_API_BASE = 'http://127.0.0.1:8000' }

if (!(Test-Path package.json)) { throw "package.json not found in $here" }

# Make sure deps are installed in the *mobile* folder
npm install
npx expo install expo-router react-native-safe-area-context react-native-screens expo-updates
npm i axios zustand

Write-Host "Mobile app starting (focus this window and press 'w' for web)" -ForegroundColor Green
npx expo start -c
