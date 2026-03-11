import React from "react";
import type { MasonRuntime } from "../mason";

export function OverviewView({ mason }: { mason: MasonRuntime }) {
  const s = mason.getStateNow();
  return (
    <div className="card">
      <div className="row" style={{ justifyContent: "space-between" }}>
        <div>
          <div><b>Overview</b></div>
          <div className="muted">Counts reflect local state (persisted in your browser).</div>
        </div>
        <button className="btn" onClick={() => mason.emit("overview/refresh")}>Refresh</button>
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 10, marginTop: 12 }}>
        <div className="card"><b>Tasks</b><div className="muted">{s.tasks.length}</div></div>
        <div className="card"><b>Contacts</b><div className="muted">{s.contacts.length}</div></div>
        <div className="card"><b>Deals</b><div className="muted">{s.deals.length}</div></div>
        <div className="card"><b>Invoices</b><div className="muted">{s.invoices.length}</div></div>
      </div>
    </div>
  );
}