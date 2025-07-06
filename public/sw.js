// Service Worker para PWA con auto-actualización
const CACHE_NAME = 'quotify-v1.0.0';
const API_CACHE = 'quotify-api-v1';

// Archivos para cachear (funcionamiento offline)
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/icon-192.png',
  '/icon-512.png'
];

// URLs que NO deben cachearse (siempre fresh)
const NO_CACHE_URLS = [
  '/api/',
  'youtube.com',
  'googlevideo.com',
  'openai.com'
];

// Instalación del Service Worker
self.addEventListener('install', event => {
  console.log('📦 Quotify SW: Installing...');
  
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('📦 Quotify SW: Caching static assets');
        return cache.addAll(STATIC_ASSETS);
      })
      .then(() => {
        console.log('✅ Quotify SW: Installation complete');
        return self.skipWaiting(); // Activar inmediatamente
      })
  );
});

// Activación del Service Worker
self.addEventListener('activate', event => {
  console.log('🔄 Quotify SW: Activating...');
  
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          // Eliminar caches antiguas
          if (cacheName !== CACHE_NAME && cacheName !== API_CACHE) {
            console.log('🗑️ Quotify SW: Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => {
      console.log('✅ Quotify SW: Activation complete');
      return self.clients.claim(); // Tomar control inmediatamente
    })
  );
});

// Intercepción de requests (estrategia de cache)
self.addEventListener('fetch', event => {
  const request = event.request;
  const url = new URL(request.url);
  
  // No cachear ciertas URLs
  if (NO_CACHE_URLS.some(pattern => url.href.includes(pattern))) {
    return; // Usar red directamente
  }
  
  // Estrategia: Network First para HTML, Cache First para assets
  if (request.destination === 'document') {
    event.respondWith(networkFirstStrategy(request));
  } else {
    event.respondWith(cacheFirstStrategy(request));
  }
});

// Estrategia Network First (para HTML/datos dinámicos)
async function networkFirstStrategy(request) {
  try {
    // Intentar red primero
    const response = await fetch(request);
    
    // Si es exitoso, cachear y devolver
    if (response.status === 200) {
      const cache = await caches.open(CACHE_NAME);
      cache.put(request, response.clone());
    }
    
    return response;
  } catch (error) {
    // Si falla la red, usar cache
    console.log('🔄 Quotify SW: Network failed, using cache for:', request.url);
    const cachedResponse = await caches.match(request);
    return cachedResponse || new Response('Offline', { status: 503 });
  }
}

// Estrategia Cache First (para assets estáticos)
async function cacheFirstStrategy(request) {
  // Buscar en cache primero
  const cachedResponse = await caches.match(request);
  
  if (cachedResponse) {
    return cachedResponse;
  }
  
  // Si no está en cache, obtener de red y cachear
  try {
    const response = await fetch(request);
    
    if (response.status === 200) {
      const cache = await caches.open(CACHE_NAME);
      cache.put(request, response.clone());
    }
    
    return response;
  } catch (error) {
    console.log('❌ Quotify SW: Failed to fetch:', request.url);
    return new Response('Resource not available', { status: 404 });
  }
}

// Auto-actualización en background
self.addEventListener('message', event => {
  if (event.data && event.data.type === 'CHECK_UPDATE') {
    checkForUpdates();
  }
});

async function checkForUpdates() {
  try {
    // Verificar si hay nueva versión
    const response = await fetch('/api/version');
    const data = await response.json();
    
    if (data.version !== CACHE_NAME.split('-v')[1]) {
      // Notificar al cliente que hay actualización
      const clients = await self.clients.matchAll();
      clients.forEach(client => {
        client.postMessage({
          type: 'UPDATE_AVAILABLE',
          version: data.version
        });
      });
    }
  } catch (error) {
    console.log('Failed to check for updates:', error);
  }
}

// Verificar actualizaciones cada 30 minutos
setInterval(checkForUpdates, 30 * 60 * 1000);