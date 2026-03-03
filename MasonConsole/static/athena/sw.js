const CACHE_NAME = "athena-pwa-v3";
const ASSETS = [
  "/athena/",
  "/athena/index.html",
  "/athena/manifest.webmanifest",
  "/athena/icon-192.svg",
  "/athena/icon-512.svg"
];

self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(ASSETS)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (event) => {
  const { request } = event;
  if (request.method !== "GET") {
    return;
  }

  const url = new URL(request.url);
  const isAthenaIndex = url.pathname === "/athena/" || url.pathname === "/athena/index.html";

  if (isAthenaIndex) {
    // Network-first for app shell to prevent stale iOS PWA UI after updates.
    event.respondWith(
      fetch(request)
        .then((response) => {
          const copy = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put("/athena/index.html", copy));
          return response;
        })
        .catch(() => caches.match("/athena/index.html"))
    );
    return;
  }

  event.respondWith(
    fetch(request)
      .then((response) => {
        const copy = response.clone();
        caches.open(CACHE_NAME).then((cache) => cache.put(request, copy));
        return response;
      })
      .catch(() => caches.match(request).then((hit) => hit || caches.match("/athena/index.html")))
  );
});
