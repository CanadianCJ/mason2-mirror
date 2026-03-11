from datetime import datetime
from typing import Optional

from fastapi import FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
import os

import storage  # local JSON store

app = FastAPI(title="Onyx Backend", version="0.2.0")

# Dev CORS (tighten later)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*", "x-onyx-key"],
)

# Admin key for writes (POST/PUT/DELETE)
ONYX_API_KEY = os.environ.get("ONYX_API_KEY", "")

def require_key(x_onyx_key: Optional[str] = Header(default=None)):
    if not ONYX_API_KEY or x_onyx_key != ONYX_API_KEY:
        raise HTTPException(status_code=401, detail="Unauthorized")

# --- Models ---
class OnyxCommand(BaseModel):
    action: str
    payload: dict | None = None

class ReportRequest(BaseModel):
    period: str = "last_7_days"
    format: str = "json"

class ClientIn(BaseModel):
    name: str
    status: str = "active"

class ClientUpdate(BaseModel):
    name: Optional[str] = None
    status: Optional[str] = None

class ProjectIn(BaseModel):
    name: str
    client_id: int
    status: str = "active"

class ProjectUpdate(BaseModel):
    name: Optional[str] = None
    client_id: Optional[int] = None
    status: Optional[str] = None

# --- Seed updates (in-memory) ---
UPDATES = [
    {"title": "Welcome to Onyx", "body": "MVP is live.", "created_at": datetime.utcnow().isoformat() + "Z"}
]

# --- Health/Meta ---
@app.get("/health")
def health():
    return {"ok": True, "time": datetime.utcnow().isoformat() + "Z"}

@app.get("/version")
def version():
    return {"version": app.version}

# --- Updates (GET open, POST requires key) ---
@app.get("/onyx/updates")
def get_updates():
    return UPDATES

@app.post("/onyx/updates")
def add_update(item: dict, x_onyx_key: Optional[str] = Header(default=None)):
    require_key(x_onyx_key)
    item.setdefault("created_at", datetime.utcnow().isoformat() + "Z")
    UPDATES.insert(0, item)
    return {"ok": True}

# --- Execute echo (placeholder for Mason bridge) ---
@app.post("/onyx/execute")
def onyx_execute(cmd: OnyxCommand):
    return {"status": "ok", "action": cmd.action, "received": cmd.payload}

# --- Report demo ---
@app.post("/onyx/report")
def onyx_report(req: ReportRequest):
    from report_generator import generate_report
    return generate_report(period=req.period, fmt=req.format)

# --- Clients (GET open; writes need key) ---
@app.get("/clients")
def clients():
    return storage.read()["clients"]

@app.post("/clients")
def create_client(payload: ClientIn, x_onyx_key: Optional[str] = Header(default=None)):
    require_key(x_onyx_key)
    def mut(d):
        cid = d["next_client_id"]; d["next_client_id"] += 1
        d["clients"].append({"id": cid, "name": payload.name, "status": payload.status})
    d = storage.write(mut)
    return {"ok": True, "client_id": d["next_client_id"] - 1}

@app.put("/clients/{cid}")
def update_client(cid: int, payload: ClientUpdate, x_onyx_key: Optional[str] = Header(default=None)):
    require_key(x_onyx_key)
    not_found = object()
    def mut(d):
        for c in d["clients"]:
            if c["id"] == cid:
                if payload.name is not None: c["name"] = payload.name
                if payload.status is not None: c["status"] = payload.status
                return
        return not_found
    res = storage.write(mut)
    if res is not_found:
        raise HTTPException(status_code=404, detail="Client not found")
    return {"ok": True}

@app.delete("/clients/{cid}")
def delete_client(cid: int, x_onyx_key: Optional[str] = Header(default=None)):
    require_key(x_onyx_key)
    removed = {"ok": False}
    def mut(d):
        nonlocal removed
        before = len(d["clients"])
        d["clients"] = [c for c in d["clients"] if c["id"] != cid]
        removed = {"ok": len(d["clients"]) < before}
    storage.write(mut)
    if not removed["ok"]:
        raise HTTPException(status_code=404, detail="Client not found")
    return {"ok": True}

# --- Projects (GET open; writes need key) ---
@app.get("/projects")
def projects():
    return storage.read()["projects"]

@app.post("/projects")
def create_project(payload: ProjectIn, x_onyx_key: Optional[str] = Header(default=None)):
    require_key(x_onyx_key)
    def mut(d):
        pid = d["next_project_id"]; d["next_project_id"] += 1
        d["projects"].append({"id": pid, "name": payload.name, "client_id": payload.client_id, "status": payload.status})
    d = storage.write(mut)
    return {"ok": True, "project_id": d["next_project_id"] - 1}

@app.put("/projects/{pid}")
def update_project(pid: int, payload: ProjectUpdate, x_onyx_key: Optional[str] = Header(default=None)):
    require_key(x_onyx_key)
    not_found = object()
    def mut(d):
        for p in d["projects"]:
            if p["id"] == pid:
                if payload.name is not None: p["name"] = payload.name
                if payload.client_id is not None: p["client_id"] = payload.client_id
                if payload.status is not None: p["status"] = payload.status
                return
        return not_found
    res = storage.write(mut)
    if res is not_found:
        raise HTTPException(status_code=404, detail="Project not found")
    return {"ok": True}

@app.delete("/projects/{pid}")
def delete_project(pid: int, x_onyx_key: Optional[str] = Header(default=None)):
    require_key(x_onyx_key)
    removed = {"ok": False}
    def mut(d):
        nonlocal removed
        before = len(d["projects"])
        d["projects"] = [p for p in d["projects"] if p["id"] != pid]
        removed = {"ok": len(d["projects"]) < before}
    storage.write(mut)
    if not removed["ok"]:
        raise HTTPException(status_code=404, detail="Project not found")
    return {"ok": True}

# --- Legal (for app-store review) ---
@app.get("/legal/privacy", response_class=HTMLResponse)
def privacy():
    return "<h1>Onyx Privacy Policy</h1><p>We collect minimal operational data (release notes, basic usage). No personal data is sold or shared.</p>"

@app.get("/legal/terms", response_class=HTMLResponse)
def terms():
    return "<h1>Onyx Terms</h1><p>Onyx is provided as-is. Use at your discretion.</p>"
