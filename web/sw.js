// Offline support for the web version (iPad / iPhone / any browser).
// On first visit the whole app (textbook PDF, audio, pictures, code) is
// downloaded into the cache; afterwards it works without internet.
// __VERSION__ and offline_files.json are written by tool/build_web.sh.
const VERSION = '__VERSION__';
const CACHE = 'english-for-iraq-' + VERSION;

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    const res = await fetch('offline_files.json', { cache: 'no-store' });
    const files = await res.json();
    // Add in small batches so one slow file does not stall everything.
    for (let i = 0; i < files.length; i += 20) {
      await cache.addAll(files.slice(i, i + 20).map((f) => new Request(f, { cache: 'reload' })));
    }
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    for (const key of await caches.keys()) {
      if (key.startsWith('english-for-iraq-') && key !== CACHE) await caches.delete(key);
    }
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET' || new URL(req.url).origin !== self.location.origin) return;
  event.respondWith((async () => {
    const cache = await caches.open(CACHE);
    // Range requests (audio/video seeking) are answered from the full cached file.
    const cached = await cache.match(req, { ignoreSearch: true }) ||
      (req.mode === 'navigate' ? await cache.match('index.html') : undefined);
    if (cached) {
      const range = req.headers.get('range');
      if (range && cached.status === 200) return rangeResponse(cached, range);
      return cached;
    }
    try {
      const res = await fetch(req);
      if (res.ok && res.status === 200 && !req.headers.get('range')) cache.put(req, res.clone());
      return res;
    } catch (e) {
      return new Response('Offline', { status: 503, statusText: 'Offline' });
    }
  })());
});

async function rangeResponse(response, range) {
  const buf = await response.arrayBuffer();
  const m = /bytes=(\d*)-(\d*)/.exec(range);
  const start = m && m[1] ? parseInt(m[1], 10) : 0;
  const end = m && m[2] ? parseInt(m[2], 10) : buf.byteLength - 1;
  const slice = buf.slice(start, end + 1);
  return new Response(slice, {
    status: 206,
    statusText: 'Partial Content',
    headers: {
      'Content-Type': response.headers.get('Content-Type') || 'application/octet-stream',
      'Content-Range': `bytes ${start}-${end}/${buf.byteLength}`,
      'Content-Length': String(slice.byteLength),
    },
  });
}
