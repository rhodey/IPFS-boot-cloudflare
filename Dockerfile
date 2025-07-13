FROM ubuntu:24.04

RUN apt update
RUN apt install -y curl unzip git

# ipfs cli = native pin
WORKDIR /root/ipfs
RUN curl https://dist.ipfs.tech/kubo/v0.32.0/kubo_v0.32.0_linux-amd64.tar.gz -o kubo_v0.32.0_linux-amd64.tar.gz
RUN tar -xvzf kubo_v0.32.0_linux-amd64.tar.gz
RUN cd kubo && bash -c "./install.sh"

COPY <<EOF /root/ipfs.sh
# add dir
ipfs init >>/dev/null 2>&1
cid=\$(ipfs add -q -r /root/dist | tail -n 1)
echo "CIDv0 = \$cid"
cb32=\$(ipfs cid base32 "\$cid")
echo "CIDv1 = \$cb32"
# pin local
echo "starting daemon ..."
ipfs daemon >>/dev/null 2>&1 &
sleep 3
ipfs pin add "$\cb32"
# upload
ipfs pin remote service add my_pin "\$pin_api" "\$pin_token"
echo "ok. may take up to 10 minutes for remote pin to succeed ..."
echo "may never succeed depending on your NAT ..."
begin=\$(date)
echo "begin = \$begin"
ipfs pin remote add --service=my_pin "\$cb32"
end=\$(date)
echo "done: https://\$cb32.ipfs.dweb.link/"
echo "end = \$end"
EOF

# filebase = fast pin
WORKDIR /root/s3
RUN curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip
RUN unzip awscliv2.zip
RUN bash -c "./aws/install"

COPY <<EOF /root/filebase.sh
# add dir
ipfs init >>/dev/null 2>&1
cid=\$(ipfs add -q -r /root/dist | tail -n 1)
echo "CIDv0 = \$cid"
cb32=\$(ipfs cid base32 "\$cid")
echo "CIDv1 = \$cb32"
# create .car
ipfs dag export "\$cb32" > /root/dist.car
# upload
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=\$pin_filebase_access
export AWS_SECRET_ACCESS_KEY=\$pin_filebase_secret
aws --endpoint https://s3.filebase.com s3 cp /root/dist.car s3://\$pin_filebase_bucket/\$cb32 --metadata 'import=car'
echo "done: https://\$cb32.ipfs.dweb.link"
EOF

# storacha = fast pin
WORKDIR /root/js
ENV NVM_DIR=/root/js/.nvm
RUN git clone --depth 1 --branch v0.40.1 https://github.com/nvm-sh/nvm nvm
RUN cd nvm && . ./nvm.sh && nvm install 20.11.1
ENV PATH="/root/js/.nvm/versions/node/v20.11.1/bin:$PATH"
RUN node -v && npx -y @web3-storage/w3cli@7.12.0 -v

COPY <<EOF /root/storacha.sh
# login
if [ ! -f "/root/.config/w3access/w3cli.json" ]; then
  npx @web3-storage/w3cli@7.12.0 login "\$pin_storacha_email"
fi
npx @web3-storage/w3cli@7.12.0 space use "\$pin_storacha_space"
# add dir
ipfs init >>/dev/null 2>&1
cid=\$(ipfs add -q -r /root/dist | tail -n 1)
echo "CIDv0 = \$cid"
cb32=\$(ipfs cid base32 "\$cid")
echo "CIDv1 = \$cb32"
# create .car
ipfs dag export "\$cb32" > /root/dist.car
# upload
npx @web3-storage/w3cli@7.12.0 up -c /root/dist.car
echo "done: https://\$cb32.ipfs.dweb.link"
EOF

# cloudflare = fast gateway
COPY <<EOF /root/cloudflare.sh
# add dir
ipfs init >>/dev/null 2>&1
cid=\$(ipfs add -q -r /root/dist | tail -n 1)
echo "CIDv0 = \$cid"
cb32=\$(ipfs cid base32 "\$cid")
echo "CIDv1 = \$cb32"
# start gateway
ipfs daemon >>/dev/null 2>&1 &
sleep 2
# upload every cid
echo "\$cb32" > /tmp/cids
ipfs refs -r "\$cb32" >> /tmp/cids
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=\$pin_cloudflare_access
export AWS_SECRET_ACCESS_KEY=\$pin_cloudflare_secret
while read -r cid; do
  curl -L "http://localhost:8080/ipfs/\$cid?format=raw" 2>/dev/null > /tmp/raw
  aws --endpoint \$pin_cloudflare_api s3 cp /tmp/raw s3://ipfs/\$cid
done < /tmp/cids
echo "done: https://\$cb32.ipfs.dweb.link"
EOF

COPY <<EOF /root/cmd.sh
if [[ -v pin_api ]]; then
    bash -c "/root/ipfs.sh"
    echo ""
fi
if [[ -v pin_filebase_bucket ]]; then
    bash -c "/root/filebase.sh"
    echo ""
fi
if [[ -v pin_storacha_email ]]; then
    bash -c "/root/storacha.sh"
    echo ""
fi
if [[ -v pin_cloudflare_access ]]; then
    bash -c "/root/cloudflare.sh"
fi
EOF

RUN chmod +x /root/ipfs.sh
RUN chmod +x /root/filebase.sh
RUN chmod +x /root/storacha.sh
RUN chmod +x /root/cloudflare.sh
RUN chmod +x /root/cmd.sh

CMD ["bash", "-c", "/root/cmd.sh"]
