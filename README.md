# IPFS-boot-cloudflare
Cloudflare R2 bucket = fast gateway

Parent repo = [IPFS-boot](https://github.com/rhodey/IPFS-boot)

## How to
This repo contains a Dockerfile which replaces the image built [here](https://github.com/rhodey/IPFS-boot#pin)
```
docker buildx build --platform=linux/amd64 -t ipfs-pin .
```

After you build the image add the following to your .env
```
pin_cloudflare_api=https://abc123.r2.cloudflarestorage.com/bucket-name
pin_cloudflare_access=abc123
pin_cloudflare_secret=abc123
```

All docs about pin and publish continue to work the same except now your app is loaded also from Cloudflare

IPFS-boot uses [verifiedFetch](https://github.com/ipfs/helia-verified-fetch) such that every file fetched is checked by hash against CID

In this way Cloudflare nor any other gateway need be trusted

## Cloudflare setup
+ Create a Cloudflare account
+ Type "R2" in the console search bar
+ Add a credit card which will be billed if you go over [free tier](https://developers.cloudflare.com/r2/pricing/#free-tier)
+ Create a bucket and enable CORS "*"
+ Manage API tokens > Create API token > Object Read & Write

## Disclaimer
+ The result is suitable for use with [verifiedFetch](https://github.com/ipfs/helia-verified-fetch)
+ The result will not be a url which get pasted into the url bar
+ Setup your Cloudflare bucket to use "custom domain"
+ The "development url" seems to rate limit sometimes

## Also
+ Cloudflare R2 is used in addition to a list of default gateways (resilient!)
+ See [WORKER.md](https://github.com/rhodey/IPFS-boot-cloudflare/blob/master/WORKER.md) for adding cache layer (faster!)

## License
MIT - Copyright 2025 - mike@rhodey.org
