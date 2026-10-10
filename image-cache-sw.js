/* NFLM image cache: only images, never account data or API responses. */
const CACHE_NAME="nflm-card-images-v1";
const MAX_IMAGES=100;
self.addEventListener("install",event=>{self.skipWaiting()});
self.addEventListener("activate",event=>{event.waitUntil((async()=>{for(const name of await caches.keys()){if(name.startsWith("nflm-card-images-")&&name!==CACHE_NAME)await caches.delete(name)}await self.clients.claim()})())});
function isCardImage(url){return (url.hostname==="images.scrydex.com"||url.hostname==="assets.tcgdex.net"||url.hostname==="assets.tcgdex.net"||url.hostname==="cdn.tcgdex.net")&&/\.(?:webp|png|jpe?g)(?:$|\?)/i.test(url.pathname+url.search)||url.hostname==="images.scrydex.com"&&url.pathname.startsWith("/pokemon/")}
self.addEventListener("fetch",event=>{
 const req=event.request;
 if(req.method!=="GET"||req.destination!=="image"||!isCardImage(new URL(req.url)))return;
 event.respondWith((async()=>{
  const cache=await caches.open(CACHE_NAME);
  const saved=await cache.match(req);
  if(saved)return saved;
  try{
   const response=await fetch(req);
   if(response.ok||response.type==="opaque"){
    event.waitUntil((async()=>{try{await cache.put(req,response.clone());const keys=await cache.keys();if(keys.length>MAX_IMAGES)await Promise.all(keys.slice(0,keys.length-MAX_IMAGES).map(k=>cache.delete(k)))}catch(e){console.warn("Image cache skipped",e)}})());
   }
   return response;
  }catch(e){return saved||Response.error()}
 })());
});
