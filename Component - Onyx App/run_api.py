import sys, pathlib, importlib.util, uvicorn

ROOT   = pathlib.Path(__file__).parent
TARGET = ROOT / "mason_local_api.py"
MARKER = pathlib.Path(r"C:\ProgramData\Mason\MasonAI.which.txt")

if not TARGET.exists():
    raise SystemExit(f"[RUNNER] Not found: {TARGET}")

spec = importlib.util.spec_from_file_location("mason_local_loaded", TARGET)
mod  = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = mod
spec.loader.exec_module(mod)

if not hasattr(mod, "app"):
    raise SystemExit(f"[RUNNER] '{TARGET}' has no `app`")

try:
    MARKER.parent.mkdir(parents=True, exist_ok=True)
    MARKER.write_text(f"Loaded: {TARGET}\nModule: {mod.__name__}\n", encoding="utf-8")
except Exception:
    pass

print(f"[RUNNER] Loaded: {TARGET}")
print(f"[RUNNER] Using app from module: {mod.__name__}")

uvicorn.run(mod.app, host="127.0.0.1", port=8123, log_level="info", access_log=True)