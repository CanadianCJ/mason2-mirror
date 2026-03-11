import json, os, threading

DATA_PATH = os.path.join(os.path.dirname(__file__), "data.json")
_LOCK = threading.Lock()
DEFAULT = {"clients": [], "projects": [], "next_client_id": 1, "next_project_id": 1}

def _ensure_file():
    if not os.path.exists(DATA_PATH):
        with open(DATA_PATH, "w", encoding="utf-8") as f:
            json.dump(DEFAULT, f, indent=2)

def _load():
    _ensure_file()
    try:
        with open(DATA_PATH, "r", encoding="utf-8") as f:
            d = json.load(f)
    except Exception:
        d = DEFAULT.copy()
    for k, v in DEFAULT.items():
        if k not in d: d[k] = v
    return d

def read():
    with _LOCK:
        return _load()

def write(mutator):
    with _LOCK:
        d = _load()
        mutator(d)
        with open(DATA_PATH, "w", encoding="utf-8") as f:
            json.dump(d, f, indent=2)
        return d
