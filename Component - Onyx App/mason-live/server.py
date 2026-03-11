import os, subprocess, json
from pathlib import Path
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import FileResponse, HTMLResponse, JSONResponse
import httpx

BASE   = Path(r"C:\Users\Chris\Desktop\ONYX")
TOKEN  = "3186ef511b8d441ebbb2c20eab31ec52"
START  = str(BASE / "start-all.ps1")
STOP   = str(BASE / "stop-all.ps1")

SIDE_ORIGIN = "http://127.0.0.1:7000"

app = FastAPI()

def check_auth(req: Request):
    if req.headers.get("x-auth") != TOKEN:
        raise HTTPException(status_code=401, detail="unauthorized")

@app.get("/")
def root():
    return FileResponse(str(Path(__file__).with_name("index.html")), media_type="text/html")

@app.get("/api/status")
def status(req: Request):
    check_auth(req)
    side = "down"; props = None
    try:
        with httpx.Client(timeout=2.0) as c:
            h = c.get(f"{SIDE_ORIGIN}/health").json()
        side = "ok"
    except Exception:
        pass
    try:
        with httpx.Client(timeout=2.0) as c:
            p = c.get(f"{SIDE_ORIGIN}/proposals").json()
        props = len(p) if isinstance(p, list) else None
    except Exception:
        pass
    return {"sidecar": side, "proposals": props}

@app.post("/api/actions/start")
def action_start(req: Request):
    check_auth(req)
    if not Path(START).exists():
        raise HTTPException(404, detail="start-all.ps1 not found")
    subprocess.Popen(["powershell.exe","-NoProfile","-ExecutionPolicy","Bypass","-File", START], creationflags=0x00000008)
    return {"ok": True}

@app.post("/api/actions/stop")
def action_stop(req: Request):
    check_auth(req)
    if not Path(STOP).exists():
        raise HTTPException(404, detail="stop-all.ps1 not found")
    subprocess.Popen(["powershell.exe","-NoProfile","-ExecutionPolicy","Bypass","-File", STOP], creationflags=0x00000008)
    return {"ok": True}

@app.post("/api/actions/scan")
def action_scan(req: Request):
    check_auth(req)
    roots = [
        str(BASE / "onyx-backend"),
        str(BASE / "onyx-web"),
        str(BASE / "mason-sidecar")
    ]
    try:
        with httpx.Client(timeout=10.0) as c:
            r = c.post(f"{SIDE_ORIGIN}/scan", json={"roots": roots})
        return {"ok": True, "roots": roots}
    except Exception as e:
        raise HTTPException(500, detail=str(e))
