import os
import json
import logging
from pathlib import Path

from flask import Flask, request, jsonify
from openai import OpenAI

# Default model; can override with env var MASON_MODEL
DEFAULT_MODEL = "gpt-5.1"
MODEL_NAME = os.getenv("MASON_MODEL", DEFAULT_MODEL)

# Configure logging (never log secrets)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s - %(message)s",
)
logger = logging.getLogger("mason_bridge")

app = Flask(__name__)

# Lazy client creation (avoids instantiating with missing/invalid keys)
_client: OpenAI | None = None
_client_key_source: str | None = None


def _repo_root() -> Path:
    """
    Resolve repo root as: .../bridge/mason_bridge_server.py -> repo root is parent of 'bridge'
    """
    return Path(__file__).resolve().parent.parent


def _load_api_key_from_secrets_file(repo_root: Path) -> str | None:
    """
    Loads OpenAI API key from config/secrets_mason.json if present.

    Supported schemas:
      { "openai_api_key": "..." }
      { "openai": { "api_key": "..." } }
      { "OPENAI_API_KEY": "..." }  # allowed, but prefer the above
    """
    secrets_path = repo_root / "config" / "secrets_mason.json"
    if not secrets_path.exists():
        return None

    try:
        raw = secrets_path.read_text(encoding="utf-8")
        if not raw.strip():
            return None

        data = json.loads(raw)
        if not isinstance(data, dict):
            return None

        v = data.get("openai_api_key")
        if isinstance(v, str) and v.strip():
            return v.strip()

        openai_obj = data.get("openai")
        if isinstance(openai_obj, dict):
            v2 = openai_obj.get("api_key")
            if isinstance(v2, str) and v2.strip():
                return v2.strip()

        v3 = data.get("OPENAI_API_KEY")
        if isinstance(v3, str) and v3.strip():
            return v3.strip()

        return None
    except Exception:
        # Never log secret content
        logger.exception("Failed to parse config/secrets_mason.json")
        return None


def _get_openai_api_key() -> tuple[str | None, str | None]:
    """
    Returns (api_key, source) where source is one of:
      - "env:OPENAI_API_KEY"
      - "file:config/secrets_mason.json"
      - None
    """
    env_key = os.getenv("OPENAI_API_KEY")
    if env_key and env_key.strip():
        return env_key.strip(), "env:OPENAI_API_KEY"

    file_key = _load_api_key_from_secrets_file(_repo_root())
    if file_key:
        return file_key, "file:config/secrets_mason.json"

    return None, None


def _get_client() -> OpenAI | None:
    global _client, _client_key_source

    # If we already built a client, keep it.
    if _client is not None:
        return _client

    api_key, source = _get_openai_api_key()
    if not api_key:
        return None

    _client = OpenAI(api_key=api_key)
    _client_key_source = source
    return _client


@app.route("/health", methods=["GET"])
def health():
    """
    Simple health check: confirms bridge is up and which model it's using.
    Never returns secrets.
    """
    api_key, source = _get_openai_api_key()
    return jsonify({
        "status": "ok",
        "model": MODEL_NAME,
        "api_key_configured": bool(api_key),
        "api_key_source": source,  # safe metadata; no secret value
    })


@app.route("/api/chat", methods=["POST"])
def api_chat():
    """
    Core chat endpoint for Mason/Athena.

    Expected JSON body:
    {
        "message": "User's latest message",          # required if no history
        "history": [                                 # optional
            {"role": "user", "content": "..."},
            {"role": "assistant", "content": "..."}
        ],
        "system_prompt": "optional custom system prompt"
    }

    Response:
    {
        "reply": "Assistant reply text",
        "model": "gpt-5.1"
    }
    """
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
        "You can reason deeply about tasks, but you never execute code or make system changes directly. "
        "You explain your reasoning and give concrete, low-risk suggestions that a human or another tool can carry out."
    )

    if not user_message and not history:
        return jsonify({"error": "Provide at least 'message' or non-empty 'history'."}), 400

    messages = [{"role": "system", "content": system_prompt}]

    if isinstance(history, list):
        for m in history:
            if not isinstance(m, dict):
                continue
            role = m.get("role")
            content = m.get("content")
            if role in ("user", "assistant") and isinstance(content, str) and content.strip():
                messages.append({"role": role, "content": content})

    if isinstance(user_message, str) and user_message.strip():
        messages.append({"role": "user", "content": user_message})

    client = _get_client()
    if client is None:
        logger.warning("OpenAI API key not configured (OPENAI_API_KEY or config/secrets_mason.json).")
        return jsonify({"error": "OpenAI API key not configured. Set OPENAI_API_KEY or config/secrets_mason.json."}), 500

    logger.info("Calling OpenAI model=%s messages=%d", MODEL_NAME, len(messages))

    try:
        completion = client.chat.completions.create(
            model=MODEL_NAME,
            messages=messages,
        )
        reply = completion.choices[0].message.content
    except Exception as e:
        logger.exception("OpenAI API error")
        return jsonify({"error": f"OpenAI error: {e}"}), 500

    return jsonify({
        "reply": reply,
        "model": MODEL_NAME
    })


if __name__ == "__main__":
    port = int(os.getenv("MASON_BRIDGE_PORT", "8484"))
    logger.info("Starting Mason bridge on http://127.0.0.1:%d using model=%s", port, MODEL_NAME)
    app.run(host="127.0.0.1", port=port)