sudo := "$(docker info > /dev/null 2>&1 || echo 'sudo')"

build:
    {{sudo}} docker buildx build --platform=linux/amd64 -t ipfs-pin .

bash:
    just build
    {{sudo}} docker run --rm -it --platform=linux/amd64 -v ./dist:/root/dist --entrypoint /bin/bash --env-file .env ipfs-pin

run:
    just build
    {{sudo}} docker run --rm -i --platform=linux/amd64 -v ./dist:/root/dist --env-file .env ipfs-pin
