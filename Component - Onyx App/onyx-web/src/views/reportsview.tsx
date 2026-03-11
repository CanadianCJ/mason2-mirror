import React from "react";
import type { MasonRuntime } from "../mason";

export function ReportsView({ mason }: { mason: MasonRuntime }) {
  const base =
    (import.meta as any).env?.VITE_API_BASE ?? "http://127.0.0.1:8000";

  const [loading, setLoading] = React.useState(false);
  const [error, setError] = React.useState<string>("");
  const [text, setText] = React.useState<string>("");

  // Update the panel whenever a report is emitted (e.g., from console/tools)
  React.useEffect(() => {
    const off = mason.on("report/received", (e: any) => {
      const t = e?.data?.text;
      if (t) setText(String(t));
    });
    return off;
  }, [mason]);

  async function runReport() {
    setLoading(true);
    setError("");
    try {
      const r = await fetch(`${base}/onyx/report`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ period: "last_7_days", format: "text" }),
      });
      if (!r.ok) throw new Error(`HTTP ${r.status}`);
      const data = await r.json();
      mason.emit("report/received", data); // also shows up in Event Log
    } catch (err: any) {
      setError(err?.message || "Failed to fetch report");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="card">
      <div className="row" style={{ justifyContent: "space-between" }}>
        <div>
          <div><b>Reports</b></div>
          <div className="muted">Calls your Onyx backend and logs results.</div>
        </div>
        <button className="btn" onClick={runReport} disabled={loading}>
          {loading ? "Running…" : "Run weekly report"}
        </button>
      </div>

      {error && <div style={{ color: "crimson", marginTop: 10 }}>Error: {error}</div>}
      {text && <pre style={{ marginTop: 10 }}>{text}</pre>}
      {!text && !loading && !error && (
        <div className="muted" style={{ marginTop: 10 }}>
          No report yet.
        </div>
      )}
    </div>
  );
}
