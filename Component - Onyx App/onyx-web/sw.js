// very tiny SW for installability + offline shell
const CACHE = "onyx-v1";
const ASSETS = ["/", "/index.html"];

self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(ASSETS)));
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    )
  );
});

self.addEventListener("fetch", (e) => {
  const req = e.request;
  // Network first, fallback to cache for same-origin GETs
  if (req.method === "GET" && new URL(req.url).origin === location.origin) {
    e.respondWith(
      fetch(req).catch(() => caches.match(req).then(r => r || caches.match("/")))
    );
  }
});
