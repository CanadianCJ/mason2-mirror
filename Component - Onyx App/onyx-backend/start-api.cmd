@echo off
setlocal
set "HERE=%~dp0"
"%HERE%\.venv\Scripts\python.exe" -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
endlocal
