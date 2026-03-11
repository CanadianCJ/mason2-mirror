import React from "react";
export function TopBar({ onMic }: { onMic: () => void }) {
  const apiBase = import.meta.env.VITE_API_BASE ?? "—";
  return (
    <div className="topbar">
      <div className="brand">ONYX</div>
      <div className="row">
        <div className="muted">API: {String(apiBase)}</div>
        <button className="btn secondary" onClick={onMic}>🎙️ Voice</button>
      </div>
    </div>
  );
}