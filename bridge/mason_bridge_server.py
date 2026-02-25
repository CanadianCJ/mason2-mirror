import os
import json
import logging
from pathlib import Path

from flask import Flask, request, jsonify
from openai import OpenAI

DEFAULT_MODEL = "gpt-5.1"
MODEL_NAME = os.getenv("MASON_MODEL", DEFAULT_MODEL)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s - %(message)s",
)
logger = logging.getLogger("mason_bridge")

app = Flask(__name__)


def _repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def _load_api_key_from_secrets(repo_root: Path) -> str | None:
    """
    Reads config/secrets_mason.json (LOCAL ONLY; must never be committed).
    Accepts:
      { "openai_api_key": "..." } or { "openai": { "api_key": "..." } }
    """
    p = repo_root / "config" / "secrets_mason.json"
    if not p.exists():
        return None
    try:
        data = json.loads(p.read_text(encoding="utf-8"))
        if isinstance(data, dict):
            v = data.get("openai_api_key")
            if isinstance(v, str) and v.strip():
                return v.strip()
            o = data.get("openai")
            if isinstance(o, dict):
                v2 = o.get("api_key")
                if isinstance(v2, str) and v2.strip():
                    return v2.strip()
    except Exception:
        logger.exception("Failed to parse config/secrets_mason.json")
    return None


def get_api_key() -> tuple[str | None, str | None]:
    # Priority: env first (good for runtime), then secrets file (good for local automation)
    k = os.getenv("OPENAI_API_KEY")
    if k and k.strip():
        return k.strip(), "env:OPENAI_API_KEY"
    k2 = _load_api_key_from_secrets(_repo_root())
    if k2:
        return k2, "file:config/secrets_mason.json"
    return None, None


def get_client() -> OpenAI | None:
    key, _ = get_api_key()
    if not key:
        return None
    return OpenAI(api_key=key)


@app.route("/health", methods=["GET"])
def health():
    key, src = get_api_key()
    return jsonify({
        "status": "ok",
        "model": MODEL_NAME,
        "api_key_configured": bool(key),
        "api_key_source": src
    })


@app.route("/api/chat", methods=["POST"])
def api_chat():
    try:
        data = request.get_json(force=True, silent=False)
    except Exception as e:
        logger.exception("Invalid JSON in request")
        return jsonify({"error": f"Invalid JSON body: {e}"}), 400

    if not isinstance(data, dict):
        return jsonify({"error": "JSON body must be an object"}), 400

    user_message = data.get("message")
    history = data.get("history", [])
    system_prompt = data.get("system_prompt") or (
        "You are Mason, a local operator AI running on Chris's PC. "
        "You must be careful, stable, and safe. "
        "You never execute system changes directly; you propose safe steps."
    )

    if not user_message and not history:
        return jsonify({"error": "Provide at least 'message' or non-empty 'history'."}), 400

    messages = [{"role": "system", "content": system_prompt}]

    if isinstance(history, list):
        for m in history:
            if isinstance(m, dict):
                role = m.get("role")
                content = m.get("content")
                if role in ("user", "assistant") and isinstance(content, str) and content.strip():
                    messages.append({"role": role, "content": content})

    if isinstance(user_message, str) and user_message.strip():
        messages.append({"role": "user", "content": user_message})

    client = get_client()
    if client is None:
        return jsonify({"error": "No API key configured. Set OPENAI_API_KEY or config/secrets_mason.json."}), 500

    try:
        completion = client.chat.completions.create(
            model=MODEL_NAME,
            messages=messages,
        )
        reply = completion.choices[0].message.content
    except Exception as e:
        logger.exception("OpenAI API error")
        return jsonify({"error": f"OpenAI error: {e}"}), 500

    return jsonify({"reply": reply, "model": MODEL_NAME})


if __name__ == "__main__":
    port = int(os.getenv("MASON_BRIDGE_PORT", "8484"))
    logger.info("Starting Mason bridge on http://127.0.0.1:%d using model=%s", port, MODEL_NAME)
    app.run(host="127.0.0.1", port=port)