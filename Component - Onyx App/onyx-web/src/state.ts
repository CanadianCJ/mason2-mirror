import { Action, State } from "./types";

const STORAGE_KEY = "onyx_state_v1";

export function loadInitialState(): State {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) return JSON.parse(raw) as State;
  } catch {}
  return { tasks: [], contacts: [], deals: [], invoices: [] };
}

export function reducer(state: State, action: Action): State {
  switch (action.type) {
    case "TASK_ADD": return { ...state, tasks: [action.task, ...state.tasks] };
    case "CONTACT_ADD": return { ...state, contacts: [action.contact, ...state.contacts] };
    case "DEAL_ADD": return { ...state, deals: [action.deal, ...state.deals] };
    case "INVOICE_ADD": return { ...state, invoices: [action.invoice, ...state.invoices] };
    default: return state;
  }
}

export function persist(state: State) {
  try { localStorage.setItem(STORAGE_KEY, JSON.stringify(state)); } catch {}
}