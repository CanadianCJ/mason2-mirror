# main.py  — Onyx Backend + Mason Control Plane (crawlers + patch apply)
from __future__ import annotations
import os, time, json, hashlib, threading, subprocess, pathlib
from typing import Dict, Any, List, Optional
from fastapi import FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# ------------------------ Basic API ------------------------
app = FastAPI(title="Onyx Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # tighten later
    allow_methods=["*"],
    allow_headers=["*"],
)

CLIENTS = [
    {"id": 1, "name": "Acme Corp", "status": "active"},
    {"id": 2, "name": "Globex LLC", "status": "prospect"},
]
PROJECTS = [
    {"id": 1, "client_id": 1, "name": "Website Revamp"},
    {"id": 2, "client_id": 1, "name": "Brand Refresh"},
]

@app.get("/")
def root():
    return {"service": "onyx-backend", "status": "ok"}

@app.get("/health")
def health():
    return {"ok": True}

@app.get("/clients")
def list_clients():
    return CLIENTS

@app.get("/projects")
def list_projects():
    return PROJECTS

class ReportRequest(BaseModel):
    period: str = "last_7_days"
    format: str = "text"

@app.post("/onyx/report")
def onyx_report(req: ReportRequest):
    text = (
        f"Onyx report ({req.period}): "
        f"{len(CLIENTS)} clients, {len(PROJECTS)} projects. All systems nominal."
    )
    return {"text": text}

# ------------------------ Mason Control: Auth ------------------------
MASON_API_KEY = os.environ.get("MASON_API_KEY", "dev-mason-key")  # change later
AUTO_APPLY = bool(int(os.environ.get("MASON_AUTO_APPLY", "0")))   # 0 or 1

def require_mason(x_mason_key: Optional[str] = Header(None)) -> None:
    if x_mason_key != MASON_API_KEY:
        raise HTTPException(status_code=401, detail="Unauthorized")

# ------------------------ Mason Control: Jobs ------------------------
JOBS: Dict[str, Dict[str, Any]] = {}

def new_job(kind: str, payload: Dict[str, Any]) -> str:
    jid = str(int(time.time() * 1000))
    JOBS[jid] = {
        "id": jid,
        "type": kind,
        "status": "queued",
        "payload": payload,
        "result": None,
        "started_at": None,
        "done_at": None,
        "errors": [],
    }
    return jid

@app.get("/mason/ping")
def mason_ping(x_mason_key: Optional[str] = Header(None)):
    require_mason(x_mason_key)
    return {"ok": True, "message": "mason: ready", "auto_apply": AUTO_APPLY}

@app.get("/mason/jobs")
def mason_jobs(x_mason_key: Optional[str] = Header(None)):
    require_mason(x_mason_key)
    return {"jobs": list(JOBS.values())}

# ------------------------ Crawlers ------------------------
ALLOWED_EXTS = {".ts", ".tsx", ".js", ".jsx", ".json", ".py", ".md", ".css", ".html"}

def sha1_bytes(b: bytes) -> str:
    import hashlib
    h = hashlib.sha1()
    h.update(b)
    return h.hexdigest()

def crawl_repo(root: str) -> Dict[str, Any]:
    out_files = []
    root_path = pathlib.Path(root).resolve()
    if not root_path.exists():
        return {"error": f"root not found: {root}"}

    for p in root_path.rglob("*"):
        if p.is_file() and p.suffix.lower() in ALLOWED_EXTS:
            try:
                data = p.read_bytes()
                text = None
                try:
                    text = data.decode("utf-8", errors="ignore")
                except Exception:
                    text = ""
                out_files.append({
                    "path": str(p.relative_to(root_path)).replace("\\","/"),
                    "size": p.stat().st_size,
                    "lines": text.count("\n")+1 if text else 0,
                    "sha1": sha1_bytes(data),
                    "snippet": text[:600]
                })
            except Exception as e:
                out_files.append({"path": str(p), "error": str(e)})

    return {
        "status": "done",
        "root": str(root_path),
        "count": len(out_files),
        "files": out_files,
        "errors": [],
    }

def crawl_urls(urls: List[str]) -> Dict[str, Any]:
    import requests
    from bs4 import BeautifulSoup
    results = []
    for url in urls:
        try:
            r = requests.get(url, timeout=15)
            soup = BeautifulSoup(r.text, "html.parser")
            text = soup.get_text("\n")
            results.append({
                "url": url,
                "status": r.status_code,
                "chars": len(text),
                "snippet": text[:800]
            })
        except Exception as e:
            results.append({"url": url, "error": str(e)})
    return {"status": "done", "items": results}

class CrawlStart(BaseModel):
    type: str = Field(description="'repo' or 'web'")
    root: Optional[str] = None      # for type=repo
    urls: Optional[List[str]] = None # for type=web

@app.post("/mason/crawl/start")
def mason_crawl_start(body: CrawlStart, x_mason_key: Optional[str] = Header(None)):
    require_mason(x_mason_key)
    jid = new_job("crawl", body.model_dump())
    JOBS[jid]["status"] = "running"
    JOBS[jid]["started_at"] = time.time()

    def _work():
        try:
            if body.type == "repo" and body.root:
                JOBS[jid]["result"] = crawl_repo(body.root)
            elif body.type == "web" and body.urls:
                JOBS[jid]["result"] = crawl_urls(body.urls)
            else:
                JOBS[jid]["errors"].append("invalid crawl parameters")
                JOBS[jid]["result"] = {"status":"error"}
        except Exception as e:
            JOBS[jid]["errors"].append(str(e))
            JOBS[jid]["result"] = {"status":"error"}
        finally:
            JOBS[jid]["status"] = "done"
            JOBS[jid]["done_at"] = time.time()

    threading.Thread(target=_work, daemon=True).start()
    return {"ok": True, "job_id": jid}

# ------------------------ Patch Apply ------------------------
# Where the Onyx web app is. Mason can pass a custom base if needed.
DEFAULT_ONYX_WEB = os.environ.get(
    "ONYX_WEB_DIR",
    str(pathlib.Path.home() / "Desktop" / "ONYX" / "onyx-web")
)

class FileChange(BaseModel):
    path: str   # relative to base_dir
    content: str

class PatchApplyRequest(BaseModel):
    app: str = "onyx-web"
    base_dir: Optional[str] = None
    changes: List[FileChange]
    rebuild: bool = False  # if True, run `npm run build` after apply
    message: Optional[str] = "mason patch"

def safe_join(base: pathlib.Path, relative: str) -> pathlib.Path:
    # prevent path traversal
    p = (base / relative).resolve()
    if not str(p).startswith(str(base.resolve())):
        raise ValueError("illegal path traversal")
    return p

def run_cmd(cmd: List[str], cwd: Optional[str] = None) -> Dict[str, Any]:
    try:
        proc = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
        return {
            "returncode": proc.returncode,
            "stdout": proc.stdout[-4000:],
            "stderr": proc.stderr[-4000:]
        }
    except Exception as e:
        return {"error": str(e)}

@app.post("/mason/patch/apply")
def mason_patch_apply(req: PatchApplyRequest, x_mason_key: Optional[str] = Header(None)):
    require_mason(x_mason_key)

    base = pathlib.Path(req.base_dir or DEFAULT_ONYX_WEB)
    if req.app != "onyx-web":
        raise HTTPException(400, "only onyx-web supported in this starter")
    if not base.exists():
        raise HTTPException(400, f"base_dir not found: {base}")

    written: List[str] = []
    try:
        for ch in req.changes:
            target = safe_join(base, ch.path)
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(ch.content, encoding="utf-8")
            written.append(str(target.relative_to(base)))
    except Exception as e:
        raise HTTPException(400, f"write failed: {e}")

    build_result = None
    if req.rebuild:
        # Windows: npm is npm.cmd
        npm = "npm.cmd" if os.name == "nt" else "npm"
        build_result = run_cmd([npm, "run", "build"], cwd=str(base))

    return {
        "ok": True,
        "base_dir": str(base),
        "written": written,
        "rebuilt": req.rebuild,
        "build_result": build_result,
        "note": "Files updated. If running `vite` dev server, it hot-reloads. If using preview, rebuild is needed."
    }

# ------------------------ Versions/Info ------------------------
@app.get("/mason/info")
def mason_info(x_mason_key: Optional[str] = Header(None)):
    require_mason(x_mason_key)
    return {
        "auto_apply": AUTO_APPLY,
        "onyx_web_dir": DEFAULT_ONYX_WEB,
        "endpoints": [
            "GET  /mason/ping",
            "GET  /mason/jobs",
            "POST /mason/crawl/start",
            "POST /mason/patch/apply",
        ],
    }
# ------------------------------
# Mason Agent API (simple & gated)
# ------------------------------
import os, time
from typing import Optional
from pydantic import BaseModel

AGENT_TOKEN = os.environ.get("ONYX_AGENT_TOKEN", "dev-token-change-me")
AGENT_SCRIPTS: list[dict] = []  # in-memory for now

class AgentScriptIn(BaseModel):
    token: str
    code: str
    id: Optional[str] = None

@app.get("/agent/scripts")
def agent_scripts():
    # No token required for read; the web app pulls these to run locally
    return {"scripts": [{"id": s["id"], "code": s["code"]} for s in AGENT_SCRIPTS]}

@app.post("/agent/script")
def agent_push_script(body: AgentScriptIn):
    if body.token != AGENT_TOKEN:
        return {"ok": False, "error": "unauthorized"}
    s_id = body.id or f"s-{int(time.time()*1000)}"
    AGENT_SCRIPTS.append({"id": s_id, "code": body.code, "ts": time.time()})
    return {"ok": True, "id": s_id, "count": len(AGENT_SCRIPTS)}

@app.delete("/agent/scripts")
def agent_clear_scripts(token: str):
    if token != AGENT_TOKEN:
        return {"ok": False, "error": "unauthorized"}
    AGENT_SCRIPTS.clear()
    return {"ok": True, "count": 0}
