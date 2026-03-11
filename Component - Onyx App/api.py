from fastapi import FastAPI, Request
from pydantic import BaseModel, Field
from typing import List, Optional
import sys, site, time, uuid, inspect, pathlib

app = FastAPI(title="Mason Local API", version="1.1")

# ----- Health / Echo / Diag -----
@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/echo")
async def echo(request: Request):
    body_bytes = await request.body()
    return {
        "method": request.method,
        "headers": dict(request.headers),
        "length": len(body_bytes),
        "body": body_bytes.decode("utf-8", errors="ignore"),
    }

@app.get("/diag")
def diag():
    me = inspect.getsourcefile(sys.modules[__name__]) or __file__
    return {
        "exe": sys.executable,
        "version": sys.version,
        "cwd": str(pathlib.Path.cwd()),
        "module_file": str(pathlib.Path(me).resolve()),
        "prefix": sys.prefix,
        "implementation": sys.implementation.name,
        "platlib": site.getsitepackages()[-1] if site.getsitepackages() else "",
        "routes": [r.path for r in app.router.routes],
    }

# ----- Minimal OpenAI-style API -----
class ChatMessage(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    model: str = Field(..., description="Model name (e.g., mason-local)")
    messages: List[ChatMessage]
    temperature: Optional[float] = 0.2
    max_tokens: Optional[int] = 256

@app.get("/v1/models")
def list_models():
    return {"object": "list", "data": [{"id": "mason-local", "object": "model"}]}

@app.post("/v1/chat/completions")
def chat_completions(req: ChatRequest):
    last_user = next((m.content for m in reversed(req.messages) if m.role == "user"), "")
    reply = f"Echo: {last_user}" if last_user else "Hello from mason-local."
    return {
        "id": f"chatcmpl-{uuid.uuid4().hex}",
        "object": "chat.completion",
        "created": int(time.time()),
        "model": req.model,
        "choices": [{
            "index": 0,
            "message": {"role": "assistant", "content": reply},
            "finish_reason": "stop",
        }],
        "usage": {"prompt_tokens": 0, "completion_tokens": len(reply.split()), "total_tokens": 0},
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("api:app", host="127.0.0.1", port=8123, reload=False)