const getParts = (url) => {
  const parts = url.pathname.split('/')
  const ipfs = parts[1]
  const cid = parts[2]
  const isIpfs = ((cid && (cid.length === 46 || cid.length === 59)) && (ipfs && ipfs === 'ipfs'))
  if (!isIpfs) { return null }
  let path = parts.slice(3).join('/')
  path = path ? `/${path}` : ''
  path += url.search
  return [cid, path]
}

const okOr404 = (res) => {
  if (res.ok || res.status === 404) { return res }
  return Promise.reject(res)
}

const cacheAge = 60 * 60 * 24 * 7

const gateways = ['dweb.link', 'ipfs.w3s.link']

const fetchMulti = (cid, path, headers, cache) => {
  let aborts = []
  const go = async (gateway) => {
    const ctrl = new AbortController()
    aborts.push(ctrl)

    const abort = () => {
      aborts.filter((c) => c !== ctrl).forEach((c) => c.abort())
      aborts = []
    }

    const url = `https://${gateway}/ipfs/${cid}${path}`
    const ok = await cache.match(url)
    if (ok) {
      console.log('cache hit', gateway, cid)
      abort()
      return [ok, Promise.resolve(1)]
    }

    const { signal } = ctrl
    console.log('cache miss', gateway, cid)
    return fetch(url, { method: 'GET', redirect: 'follow', headers, signal }).then(okOr404).then((ok) => {
      abort()
      let copy = new Response(ok.body, ok)
      copy.headers.forEach((val, key) => copy.headers.delete(key))
      copy.headers.set('Cache-Control', `public, max-age=${cacheAge}`)
      return [copy, cache.put(url, copy.clone())]
    })
  }
  return Promise.any(gateways.map(go))
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization'
}

export default {
  async fetch(request, env, ctx) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders })
    }

    const url = new URL(request.url)
    const parts = getParts(url)
    if (!parts) { return new Response('Bad Request', { status: 400 }) }

    const [cid, path] = parts
    let headers = new Headers(request.headers)
    const cache = await caches.open('v1')

    try {

      const res = await fetchMulti(cid, path, headers, cache)
      const [ok, wait] = res
      ctx.waitUntil(wait)

      headers = new Headers(ok.headers);
      for (const [key, value] of Object.entries(corsHeaders)) {
        headers.set(key, value)
      }

      return new Response(ok.body, {
        status: ok.status,
        statusText: ok.statusText,
        headers
      })

    } catch (err) {
      return new Response('Error', { status: 500 })
    }
  }
}
