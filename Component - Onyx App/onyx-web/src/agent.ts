// src/agent.ts
//
// Pulls approved agent scripts from the backend and executes them
// with a very small, explicit scope (mason, React, env).

type AgentScript = { id: string; code: string };

const POLL_MS = 15_000;

// Get API base the same way main.tsx exposed it
const API_BASE: string =
  (window as any).VITE_API_BASE ||
  (import.meta as any)?.env?.VITE_API_BASE ||
  "http://127.0.0.1:8000";

// Track which scripts we’ve already applied this session (and across reloads)
const STORE_KEY = "onyx_agent_applied_v1";
function loadApplied(): Record<string, true> {
  try {
    const raw = localStorage.getItem(STORE_KEY);
    return raw ? JSON.parse(raw) : {};
  } catch {
    return {};
  }
}
function saveApplied(map: Record<string, true>) {
  try {
    localStorage.setItem(STORE_KEY, JSON.stringify(map));
  } catch {}
}

function sleep(ms: number) {
  return new Promise((r) => setTimeout(r, ms));
}

async function waitForMason(): Promise<any> {
  for (;;) {
    const m = (window as any).mason;
    const R = (window as any).React;
    if (m && R) return { mason: m, React: R };
    await sleep(300);
  }
}

function runAgentScript(mason: any, React: any, script: AgentScript) {
  // Provide only what agent code needs — no global window access is required
  const env = {
    api: API_BASE,
    emit: (type: string, data?: any) => mason.emit(type, data),
    fetch: (input: RequestInfo | URL, init?: RequestInit) => fetch(input, init),
  };

  try {
    // eslint-disable-next-line no-new-func
    const fn = new Function("mason", "React", "env", script.code);
    const result = fn(mason, React, env);
    mason.emit("agent/applied", { id: script.id });
    console.log(`[agent] applied ${script.id}`, result);
  } catch (err: any) {
    console.error(`[agent] error in ${script.id}:`, err);
    mason.emit("agent/error", { id: script.id, error: String(err?.message || err) });
  }
}

async function pollAgent() {
  const { mason, React } = await waitForMason();
  const applied = loadApplied();

  for (;;) {
    try {
      const r = await fetch(`${API_BASE}/agent/scripts`);
      const j = (await r.json()) as { scripts: AgentScript[] };
      for (const s of j.scripts || []) {
        if (!s?.id || !s?.code) continue;
        if (applied[s.id]) continue;
        runAgentScript(mason, React, s);
        applied[s.id] = true;
        saveApplied(applied);
      }
    } catch (e) {
      console.warn("[agent] poll error:", e);
    }
    await sleep(POLL_MS);
  }
}

// kick off
pollAgent();
