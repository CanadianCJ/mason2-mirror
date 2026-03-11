$ErrorActionPreference='Stop'

# Backend (global Python), run inside the backend folder
Start-Process -FilePath powershell -WorkingDirectory (Join-Path $PSScriptRoot 'backend') -ArgumentList @(
  '-NoExit','-Command','py -3 -m uvicorn api:app --reload --host 127.0.0.1 --port 8000'
)

# Mobile (Expo), run inside the mobile folder
Start-Process -FilePath powershell -WorkingDirectory (Join-Path $PSScriptRoot 'mobile') -ArgumentList @(
  '-NoExit','-Command','=1; ="http://127.0.0.1:8000"; npx expo start -c'
)
