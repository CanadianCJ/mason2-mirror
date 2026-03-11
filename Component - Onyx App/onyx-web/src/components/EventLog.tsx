import React from "react";
import type { EventBus, BusEvent } from "../bus";

export function EventLog({ bus }: { bus: EventBus }) {
  const [items, setItems] = React.useState<BusEvent[]>([]);
  React.useEffect(() => {
    const off = bus.on("*", (e) => setItems(prev => [e, ...prev].slice(0, 200)));
    return off;
  }, [bus]);
  return (
    <div className="card">
      <div className="muted" style={{ marginBottom: 6 }}>Event Log</div>
      <div style={{ maxHeight: 160, overflow: "auto", fontFamily: "ui-monospace, SFMono-Regular, Menlo, Consolas, monospace", fontSize: 12 }}>
        {items.length === 0 ? <div className="muted">No events yet.</div> :
          items.map((e, i) => (
            <div key={i}>
              <b>{e.type}</b> <span className="muted">[{new Date(e.at).toLocaleTimeString()}]</span>
              {e.data ? <pre style={{ margin: "4px 0 10px 0" }}>{JSON.stringify(e.data, null, 2)}</pre> : null}
            </div>
          ))
        }
      </div>
    </div>
  );
}