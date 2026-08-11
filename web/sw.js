/* Admincraft service worker.
 *
 * Flutter's own service worker is deprecated and now unregisters itself on
 * activation, so caching has to be handled here.
 *
 * The strategy is chosen to make repeat visits fast without ever pinning
 * someone to an old build, which matters for a tool that controls a server:
 *
 *   - Navigations go to the network first. A new deployment is therefore
 *     picked up as soon as the user has connectivity, and the cached page is
 *     only used when the network fails.
 *   - Everything else is served from cache immediately and refreshed in the
 *     background (stale-while-revalidate), so the engine and assets do not
 *     have to be downloaded again while updates still land on the next load.
 *
 * Bump CACHE_VERSION to discard everything cached by a previous version.
 */
'use strict';

const CACHE_VERSION = 'v1';
const CACHE_NAME = `admincraft-${CACHE_VERSION}`;

self.addEventListener('install', (event) => {
  // Take over as soon as possible rather than waiting for every tab to close.
  event.waitUntil(self.skipWaiting());
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const names = await caches.keys();
      await Promise.all(
        names.filter((name) => name !== CACHE_NAME).map((name) => caches.delete(name))
      );
      await self.clients.claim();
    })()
  );
});

/** Puts a response in the cache, ignoring anything not worth storing. */
async function store(request, response) {
  if (!response || !response.ok || response.type !== 'basic') return response;
  const cache = await caches.open(CACHE_NAME);
  await cache.put(request, response.clone());
  return response;
}

async function networkFirst(request) {
  try {
    return await store(request, await fetch(request));
  } catch (e) {
    const cached = await caches.match(request);
    if (cached) return cached;
    throw e;
  }
}

async function staleWhileRevalidate(request, waitUntil) {
  const cached = await caches.match(request);

  const network = fetch(request)
    .then((response) => store(request, response))
    .catch(() => undefined);

  // Serve the cached copy the moment there is one; the refresh continues in
  // the background and is used by the next load. waitUntil is called while the
  // event is still active, which keeps the worker alive for that refresh.
  if (cached) {
    waitUntil(network);
    return cached;
  }

  const response = await network;
  if (response) return response;
  throw new Error('offline and not cached');
}

self.addEventListener('fetch', (event) => {
  const request = event.request;

  // Only GET, only this origin. Anything else (the WebSocket, other hosts)
  // must reach the network untouched.
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  if (request.mode === 'navigate') {
    event.respondWith(networkFirst(request));
    return;
  }

  event.respondWith(staleWhileRevalidate(request, (promise) => event.waitUntil(promise)));
});
