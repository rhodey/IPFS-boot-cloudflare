const cacheAge = 60 * 60 * 24 * 7

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization'
}

const parseCid = (url) => {
  const parts = url.pathname.split('/')
  const ipfs = parts[1]
  const cid = parts[2]
  const isIpfs = ipfs && ipfs === 'ipfs' && cid && cid.length > 0
  if (!isIpfs) { return null }
  return cid
}

export default {
  async fetch(request, env, ctx) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders })
    }

    const url = new URL(request.url)
    const cid = parseCid(url)
    if (!cid) { return new Response('Bad Request', { status: 400 }) }

    const cache = caches.default
    let ok = await cache.match(request)
    if (ok) {
      console.log('cache hit', cid)
      return ok
    }

    try {

      console.log('cache miss', cid)
      const obj = await env.BUCKET.get('ipfs/' + cid)
      if (!obj) { return new Response('Not found', { status: 404 }) }

      const headers = new Headers()
      headers.set('Cache-Control', `public, max-age=${cacheAge}`)
      for (const [key, value] of Object.entries(corsHeaders)) { headers.set(key, value) }

      ok = new Response(obj.body, { headers })
      ctx.waitUntil(cache.put(request, ok.clone()))
      return ok

    } catch (err) {
      console.log('error', request.url, cid, err)
      return new Response('Error', { status: 500 })
    }
  }
}
