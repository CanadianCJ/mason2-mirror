import React from "react";
import { reducer, loadInitialState, persist } from "./state";
import { MasonRuntime } from "./mason";
import { TopBar } from "./components/TopBar";
import { Sidebar } from "./components/Sidebar";
import { EventLog } from "./components/EventLog";
import { EventBus } from "./bus";
import { cryptoRandomId } from "./types";
import { OverviewView } from "./views/OverviewView";
import { TasksView } from "./views/TasksView";
import { ContactsView } from "./views/ContactsView";
import { DealsView } from "./views/DealsView";
import { InvoicesView } from "./views/InvoicesView";
import { AutomationsView } from "./views/AutomationsView";
import { ReportsView } from "./views/ReportsView";

export default function App() {
  const [state, dispatch] = React.useReducer(reducer, undefined, loadInitialState);
  React.useEffect(() => { persist(state); }, [state]);

  const bus = React.useMemo(() => new EventBus(), []);
  const mason = React.useMemo(() => new MasonRuntime(() => state, dispatch, bus), [state, dispatch, bus]);

  React.useEffect(() => {
    (window as any).mason = mason;
    return () => { delete (window as any).mason; };
  }, [mason]);

  React.useEffect(() => {
    mason.registerTool(
      { name: "createTask", description: "Create a task", parameters: { type: "object", properties: { title: { type: "string" }, due: { type: "string", format: "date" }}} },
      ({ title, due }) => {
        const task = { id: cryptoRandomId(), title: title ?? "Untitled", status: "todo" as const, due };
        mason.dispatchAction({ type: "TASK_ADD", task });
        mason.emit("task/created", task);
        return task;
      }
    );
    mason.registerTool(
      { name: "addContact", description: "Add a contact", parameters: { type: "object", properties: { name: { type: "string" }, email: { type: "string" }}} },
      ({ name, email }) => {
        const contact = { id: cryptoRandomId(), name: name ?? "Unnamed", email };
        mason.dispatchAction({ type: "CONTACT_ADD", contact });
        mason.emit("contact/created", contact);
        return contact;
      }
    );
    mason.registerTool(
      { name: "sendInvoice", description: "Create & send an invoice (mock)", parameters: { type: "object", properties: { client: { type: "string" }, amount: { type: "number" }}} },
      ({ client, amount }) => {
        const invoice = { id: cryptoRandomId(), number: `INV-${Math.floor(Math.random()*9999).toString().padStart(4,"0")}`, client: client ?? "Client", amount: amount ?? 0, status: "sent" as const };
        mason.dispatchAction({ type: "INVOICE_ADD", invoice });
        mason.emit("invoice/created", invoice);
        return { ok: true, invoice };
      }
    );
  }, [mason]);

  function handleMic(){ alert("🔊 Hook this to Mason's voice capture → bridge for live commands & dictation."); }

  const [active, setActive] = React.useState("overview");
  const dynamicViews = mason.listViews();

  const items = [
    { id: "overview",   title: "Overview" },
    { id: "tasks",      title: "Tasks",      count: state.tasks.length },
    { id: "contacts",   title: "Contacts",   count: state.contacts.length },
    { id: "deals",      title: "Deals",      count: state.deals.length },
    { id: "invoices",   title: "Invoices",   count: state.invoices.length },
    { id: "automations",title: "Automations" },
    { id: "reports",    title: "Reports" },
    ...dynamicViews.map(v => ({ id: v.id, title: v.title }))
  ];

  const Active = () => {
    if (active === "overview") return <OverviewView mason={mason} />;
    if (active === "tasks") return <TasksView mason={mason} />;
    if (active === "contacts") return <ContactsView mason={mason} />;
    if (active === "deals") return <DealsView mason={mason} />;
    if (active === "invoices") return <InvoicesView mason={mason} />;
    if (active === "automations") return <AutomationsView mason={mason} />;
    if (active === "reports") return <ReportsView mason={mason} />;
    const dyn = dynamicViews.find(v => v.id === active);
    return dyn ? dyn.render(mason) : <div className="muted">No view.</div>;
  };

  return (
    <div style={{ height: "100%", display: "grid", gridTemplateRows: "auto 1fr" }}>
      <TopBar onMic={handleMic} />
      <div style={{ display: "grid", gridTemplateColumns: "240px 1fr", height: "100%" }}>
        <Sidebar items={items} active={active} setActive={setActive} />
        <main className="main" style={{ padding: 16 }}>
          <Active />
          <div style={{ height: 12 }} />
          <EventLog bus={bus} />
        </main>
      </div>
    </div>
  );
}
