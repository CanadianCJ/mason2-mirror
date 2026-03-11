export type BusEvent = { type: string; data?: any; at: number };

export class EventBus {
  private map = new Map<string, Set<(e: BusEvent) => void>>();
  private all = new Set<(e: BusEvent) => void>();
  emit(type: string, data?: any) {
    const evt = { type, data, at: Date.now() };
    this.map.get(type)?.forEach(fn => fn(evt));
    this.all.forEach(fn => fn(evt));
  }
  on(type: string, fn: (e: BusEvent) => void): () => void {
    if (type === "*") { this.all.add(fn); return () => this.all.delete(fn); }
    if (!this.map.has(type)) this.map.set(type, new Set());
    this.map.get(type)!.add(fn);
    return () => this.map.get(type)!.delete(fn);
  }
}