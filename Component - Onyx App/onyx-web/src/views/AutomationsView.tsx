import React from "react";
import type { MasonRuntime } from "../mason";

export function AutomationsView({ mason }: { mason: MasonRuntime }) {
  return (
    <div className="card">
      <div><b>Automations</b></div>
      <div className="muted">Let Mason register background tasks and workflows here.</div>
      <button className="btn" onClick={() => mason.emit("automation/run", { name: "example" })}>Run example</button>
    </div>
  );
}