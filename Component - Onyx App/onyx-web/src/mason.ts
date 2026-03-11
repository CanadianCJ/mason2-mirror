import type { Action, State } from "./types";
import { EventBus } from "./bus";

export type ToolMeta = { name: string; description?: string; parameters?: any };
export type ToolHandler = (args: any) => any | Promise<any>;
export type ViewDef = { id: string; title: string; render: (ctx: MasonRuntime) => JSX.Element };

export class MasonRuntime {
  private tools = new Map<string, { meta: ToolMeta; handler: ToolHandler }>();
  private views: ViewDef[] = [];
  constructor(private getState: () => State, private dispatch: (a: Action) => void, public bus: EventBus) {}

  registerTool(meta: ToolMeta, handler: ToolHandler) {
    this.tools.set(meta.name, { meta, handler });
    return () => this.tools.delete(meta.name);
  }
  listTools() { return Array.from(this.tools.values()).map(t => t.meta); }
  async invokeTool(name: string, args: any) {
    const t = this.tools.get(name); if (!t) throw new Error(`Tool not found: ${name}`);
    const res = await t.handler(args);
    return res;
  }

  addView(v: ViewDef) {
    if (this.views.find(x => x.id === v.id)) return;
    this.views.push(v);
  }
  listViews() { return [...this.views]; }

  emit(type: string, data?: any) { this.bus.emit(type, data); }
  on(type: string, fn: (e: any) => void) { return this.bus.on(type, fn); }

  getStateNow() { return this.getState(); }
  dispatchAction(a: Action) { this.dispatch(a); }
}