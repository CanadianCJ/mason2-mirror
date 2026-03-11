import React from "react";
import type { MasonRuntime } from "../mason";
import { cryptoRandomId } from "../types";

export function DealsView({ mason }: { mason: MasonRuntime }) {
  const s = mason.getStateNow();
  const [title, setTitle] = React.useState("");
  const [value, setValue] = React.useState(1000);
  const add = () => {
    const d = { id: cryptoRandomId(), title: title || "New deal", value: Number(value) || 0, stage: "new" as const };
    mason.dispatchAction({ type: "DEAL_ADD", deal: d });
    mason.emit("deal/created", d);
    setTitle(""); setValue(1000);
  };
  return (
    <div>
      <div className="card">
        <div className="row">
          <input
            placeholder="Deal title"
            value={title}
            onChange={e => setTitle((e.target as HTMLInputElement).value)}
            style={{ padding: 8, border: "1px solid #cbd5e1", borderRadius: 6, flex: 1 }}
          />
          <input
            type="number"
            placeholder="Value"
            value={value}
            onChange={e => setValue(parseInt((e.target as HTMLInputElement).value || "0"))}
            style={{ padding: 8, border: "1px solid #cbd5e1", borderRadius: 6, width: 120 }}
          />
          <button className="btn" onClick={add}>Add</button>
        </div>
      </div>
      {s.deals.map(d => (
        <div key={d.id} className="card">
          <div><b>{d.title}</b> <span className="muted">(${d.value.toLocaleString()})</span></div>
          <div className="muted">Stage: {d.stage}</div>
        </div>
      ))}
      {s.deals.length === 0 && <div className="muted">No deals yet.</div>}
    </div>
  );
}
