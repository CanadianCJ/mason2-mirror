import React from "react";
import { createRoot } from "react-dom/client";
import App from "./App";

// NEW: expose React and your API base to the browser console
(window as any).React = React;
(window as any).VITE_API_BASE = import.meta.env?.VITE_API_BASE;

createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("/sw.js").catch(console.error);
}
