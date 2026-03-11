import React from "react";
import type { MasonRuntime } from "../mason";
import { cryptoRandomId } from "../types";

export function ContactsView({ mason }: { mason: MasonRuntime }) {
  const s = mason.getStateNow();
  const [name, setName] = React.useState("");
  const [email, setEmail] = React.useState("");
  const add = () => {
    const c = { id: cryptoRandomId(), name: name || "Unnamed", email: email || undefined };
    mason.dispatchAction({ type: "CONTACT_ADD", contact: c });
    mason.emit("contact/created", c);
    setName(""); setEmail("");
  };
  return (
    <div>
      <div className="card">
        <div className="row">
          <input
            placeholder="Name"
            value={name}
            onChange={e => setName((e.target as HTMLInputElement).value)}
            style={{ padding: 8, border: "1px solid #cbd5e1", borderRadius: 6, flex: 1 }}
          />
          <input
            placeholder="Email"
            value={email}
            onChange={e => setEmail((e.target as HTMLInputElement).value)}
            style={{ padding: 8, border: "1px solid #cbd5e1", borderRadius: 6, flex: 1 }}
          />
          <button className="btn" onClick={add}>Add</button>
        </div>
      </div>
      {s.contacts.map(c => (
        <div key={c.id} className="card">
          <div><b>{c.name}</b></div>
          <div className="muted">{c.email || "—"}</div>
        </div>
      ))}
      {s.contacts.length === 0 && <div className="muted">No contacts yet.</div>}
    </div>
  );
}
