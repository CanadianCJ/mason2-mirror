import React from "react";

type Item = { id: string; title: string; count?: number };

export function Sidebar({
  items, active, setActive
}: { items: Item[]; active: string; setActive: (id: string) => void }) {
  return (
    <div className="sidebar" style={{ width: 240, height: "100%", padding: 8 }}>
      {items.map(it => (
        <a key={it.id}
           href="#"
           className={["link", it.id === active ? "active" : ""].join(" ")}
           onClick={e => { e.preventDefault(); setActive(it.id); }}>
          {it.title}
          {typeof it.count === "number" ? <span className="chip">{it.count}</span> : null}
        </a>
      ))}
    </div>
  );
}