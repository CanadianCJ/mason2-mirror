export type Id = string;

export type Task = { id: Id; title: string; status: "todo" | "doing" | "done"; due?: string | null };
export type Contact = { id: Id; name: string; email?: string | null };
export type Deal = { id: Id; title: string; value: number; stage: "new" | "negotiating" | "won" | "lost" };
export type Invoice = { id: Id; number: string; client: string; amount: number; status: "draft" | "sent" | "paid" };

export type State = {
  tasks: Task[];
  contacts: Contact[];
  deals: Deal[];
  invoices: Invoice[];
};

export type Action =
  | { type: "TASK_ADD"; task: Task }
  | { type: "CONTACT_ADD"; contact: Contact }
  | { type: "DEAL_ADD"; deal: Deal }
  | { type: "INVOICE_ADD"; invoice: Invoice };

export function cryptoRandomId(): Id {
  // good-enough random for demo
  return Math.random().toString(36).slice(2) + Math.random().toString(36).slice(2);
}