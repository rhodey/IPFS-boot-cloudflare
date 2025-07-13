# IPFS-boot-cloudflare
Cloudflare Workers = faster gateway

## How to
These next steps all build on the bucket you just setup
+ Login to Cloudflare
+ Compute (Workers) > Hello World > Deploy
+ Edit Code > Copypaste worker.js > Deploy
+ Bindings > Add binding > R2 bucket > Add
+ Variable name = "BUCKET"
+ R2 bucket = yours
+ Deploy

## Swap bucket DNS with worker
For example domain = ipfs.lock.host
+ Account > R2 > Your bucket
+ Settings > Custom domain > delete
+ Account > lock.host > Worker routes
+ ipfs.lock.host/* > Your worker > Save

## Additional
+ At this point I had to add DNS CNAME=ipfs target=lock.host myself
+ Docs suggest this may be done automatically sometimes

## Final
+ Account > Compute (Workers) > Your worker > Logs
+ Make sure your domain name is in sw.js (service worker)
+ npm run dev & open incognito localhost:8080
+ boot a version of your app
+ close and re-open incognito localhost:8080
+ boot same version of your app
+ should see "cache hit" in worker logs

## License
MIT - Copyright 2025 - mike@rhodey.org
