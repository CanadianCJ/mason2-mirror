import React from "react";

type FileInfo = {
  path: string;
  size: number;
  lines: number;
  sha1: string;
  snippet?: string;
};

const BASE: string =
  (window as any).VITE_API_BASE || "http://127.0.0.1:8000";

export function CrawlerView() {
  const [status, setStatus] = React.useState<any>(null);
  const [files, setFiles] = React.useState<FileInfo[]>([]);
  const [openPath, setOpenPath] = React.useState<string | null>(null);
  const [openContent, setOpenContent] = React.useState<string>("");

  const fetchStatus = React.useCallback(async () => {
    const r = await fetch(`${BASE}/crawl/status`);
    const s = await r.json();
    setStatus(s);
    return s;
  }, []);

  const fetchFiles = React.useCallback(async () => {
    const r = await fetch(`${BASE}/crawl/files`);
    const list = await r.json();
    setFiles(list);
  }, []);

  const startCrawl = async () => {
    await fetch(`${BASE}/crawl/start`, { method: "POST" });
    setStatus({ status: "queued" });
    // poll until done
    let tries = 0;
    const poll = async () => {
      tries++;
      const s = await fetchStatus();
      if (s.status === "done") {
        await fetchFiles();
      } else if (tries < 120) {
        setTimeout(poll, 1000);
      }
    };
    setTimeout(poll, 500);
  };

  const viewFile = async (path: string) => {
    setOpenPath(path);
    setOpenContent("Loading…");
    const r = await fetch(
      `${BASE}/crawl/file?path=${encodeURIComponent(path)}`
    );
    const data = await r.json();
    setOpenContent(data.content || "No content");
  };

  React.useEffect(() => {
    // load current status on mount
    (async () => {
      const s = await fetchStatus();
      if (s?.status === "done") await fetchFiles();
    })();
  }, [fetchStatus, fetchFiles]);

  const count = status?.count ?? 0;
  const state = status?.status ?? "idle";

  return (
    <div>
      <div className="card">
        <div style={{ display: "flex", justifyContent: "space-between", gap: 10 }}>
          <div>
            <div><b>Code Crawler</b></div>
            <div className="muted">
              Status: <b>{state}</b> · Files: <b>{count}</b>
              {status?.root ? ` · Root: ${status.root}` : ""}
            </div>
          </div>
          <div style={{ display: "flex", gap: 8 }}>
            <button className="btn" onClick={startCrawl}>Start crawl</button>
            <button className="btn secondary" onClick={fetchStatus}>Refresh</button>
          </div>
        </div>
      </div>

      {files.length > 0 ? (
        <div className="card">
          <div style={{ marginBottom: 8 }}><b>Files</b></div>
          <div style={{ fontSize: 13 }}>
            {files.map((f) => (
              <div key={f.path} style={{ padding: "6px 0", borderBottom: "1px solid #eee" }}>
                <div style={{ display: "flex", justifyContent: "space-between", gap: 10 }}>
                  <div>
                    <div><code>{f.path}</code></div>
                    <div className="muted">
                      {f.lines} lines · {(f.size / 1024).toFixed(1)} KB · {f.sha1.slice(0, 8)}
                    </div>
                  </div>
                  <div>
                    <button className="btn secondary" onClick={() => viewFile(f.path)}>View</button>
                  </div>
                </div>
                {openPath === f.path && (
                  <pre style={{
                    marginTop: 8,
                    whiteSpace: "pre-wrap",
                    background: "#0b1020",
                    color: "#e6edf3",
                    padding: 12,
                    borderRadius: 8,
                    overflowX: "auto"
                  }}>
{openContent}
                  </pre>
                )}
              </div>
            ))}
          </div>
        </div>
      ) : (
        <div className="muted">No files yet. Click “Start crawl”.</div>
      )}
    </div>
  );
}
