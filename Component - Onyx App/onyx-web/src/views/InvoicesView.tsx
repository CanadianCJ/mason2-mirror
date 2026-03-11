import React from "react";
import type { MasonRuntime } from "../mason";
import { cryptoRandomId } from "../types";

export function InvoicesView({ mason }: { mason: MasonRuntime }) {
  const s = mason.getStateNow();
  const [client, setClient] = React.useState("");
  const [amount, setAmount] = React.useState(0);
  const add = () => {
    const inv = {
      id: cryptoRandomId(),
      number: `INV-${Math.floor(Math.random()*9999).toString().padStart(4,"0")}`,
      client: client || "Client",
      amount: Number(amount)||0,
      status: "sent" as const
    };
    mason.dispatchAction({ type: "INVOICE_ADD", invoice: inv });
    mason.emit("invoice/created", inv);
    setClient(""); setAmount(0);
  };
  return (
    <div>
      <div className="card">
        <div className="row">
          <input
            placeholder="Client"
            value={client}
            onChange={e => setClient((e.target as HTMLInputElement).value)}
            style={{ padding: 8, border: "1px solid #cbd5e1", borderRadius: 6, flex: 1 }}
          />
          <input
            type="number"
            placeholder="Amount"
            value={amount}
            onChange={e => setAmount(parseFloat((e.target as HTMLInputElement).value || "0"))}
            style={{ padding: 8, border: "1px solid #cbd5e1", borderRadius: 6, width: 120 }}
          />
          <button className="btn" onClick={add}>Send</button>
        </div>
      </div>
      {s.invoices.map(i => (
        <div key={i.id} className="card">
          <div><b>{i.number}</b> <span className="muted"> → {i.client}</span></div>
          <div className="muted">${i.amount.toLocaleString()} · {i.status}</div>
        </div>
      ))}
      {s.invoices.length === 0 && <div className="muted">No invoices yet.</div>}
    </div>
  );
}
