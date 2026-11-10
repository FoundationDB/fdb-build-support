#!/usr/bin/env bash
set -Eeuo pipefail

mkdir -p ~/.docker
cat > ~/.docker/config.json << EOF
{
 "aliases": {
   "builder": "buildx"
 },
 "proxies":
 {
   "default":
   {
     "httpProxy": "${HTTP_PROXY}",
     "httpsProxy": "${HTTPS_PROXY}",
     "noProxy": "${NO_PROXY}"
   }
 }
}
EOF
