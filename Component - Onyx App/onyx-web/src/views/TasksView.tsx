import React from "react";
import type { MasonRuntime } from "../mason";
import { cryptoRandomId } from "../types";

export function TasksView({ mason }: { mason: MasonRuntime }) {
  const s = mason.getStateNow();
  const [title, setTitle] = React.useState("");
  const add = () => {
    const task = { id: cryptoRandomId(), title: title || "Untitled", status: "todo" as const };
    mason.dispatchAction({ type: "TASK_ADD", task });
    mason.emit("task/created", task);
    setTitle("");
  };
  return (
    <div>
      <div className="card">
        <div className="row">
          <input
            placeholder="Task title"
            value={title}
            onChange={(e) => setTitle((e.target as HTMLInputElement).value)}
            style={{ padding: 8, border: "1px solid #cbd5e1", borderRadius: 6, flex: 1 }}
          />
          <button className="btn" onClick={add}>Add</button>
        </div>
      </div>
      {s.tasks.map(t => (
        <div key={t.id} className="card">
          <div><b>{t.title}</b></div>
          <div className="muted">Status: {t.status}{t.due ? ` · Due: ${t.due}` : ""}</div>
        </div>
      ))}
      {s.tasks.length === 0 && <div className="muted">No tasks yet.</div>}
    </div>
  );
}
