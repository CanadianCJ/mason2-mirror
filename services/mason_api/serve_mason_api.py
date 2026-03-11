#!/usr/bin/env python3
import json
import os
import sys
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

SERVICE_NAME = "mason_api"
DEFAULT_PORT = 8383


def now_utc_iso() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def parse_port(env_name: str, default_port: int) -> int:
    raw = os.environ.get(env_name, str(default_port))
    try:
        port = int(raw)
    except ValueError:
        print(f"[{SERVICE_NAME}] invalid {env_name}='{raw}'", file=sys.stderr, flush=True)
        raise SystemExit(2)
    if port < 1 or port > 65535:
        print(f"[{SERVICE_NAME}] invalid port range for {env_name}='{raw}'", file=sys.stderr, flush=True)
        raise SystemExit(2)
    return port


class Handler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        if self.path == "/health":
            payload = {
                "ok": True,
                "service": SERVICE_NAME,
                "ts": now_utc_iso(),
            }
            body = json.dumps(payload).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        payload = {"service": SERVICE_NAME, "error": "not_found"}
        body = json.dumps(payload).encode("utf-8")
        self.send_response(404)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt: str, *args) -> None:
        message = fmt % args
        print(f"[{SERVICE_NAME}] {self.address_string()} - {message}", flush=True)


HOST = os.environ.get("MASON_BIND_HOST", "127.0.0.1")
if HOST != "127.0.0.1":
    print(f"[{SERVICE_NAME}] refusing non-loopback bind host '{HOST}'", file=sys.stderr, flush=True)
    raise SystemExit(2)

PORT = parse_port("MASON_API_PORT", DEFAULT_PORT)


def main() -> int:
    try:
        server = ThreadingHTTPServer((HOST, PORT), Handler)
    except OSError as exc:
        print(f"[{SERVICE_NAME}] failed to bind {HOST}:{PORT} -> {exc}", file=sys.stderr, flush=True)
        return 1

    print(f"[{SERVICE_NAME}] listening on http://{HOST}:{PORT}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
