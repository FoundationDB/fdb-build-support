#!/bin/sh
set -e

/usr/local/bin/dockerd \
  --host=unix:///var/run/docker.sock \
  --host=tcp://127.0.0.1:2375 \
  --storage-driver=overlay2 &>/var/log/docker.log &


tries=0
d_timeout=60
until docker info >/dev/null 2>&1; do
    if [ "$tries" -gt "$d_timeout" ]; then
                cat /var/log/docker.log
        echo 'Timed out trying to connect to internal docker host.' >&2
        exit 1
    fi
        tries=$(( $tries + 1 ))
    sleep 1
done

# Set buildx as the default builder to ensure we use buildkit:
# https://docs.docker.com/build/builders/
docker buildx install
# Install a custom builder with buildx to support multi-arch images:
# https://docs.docker.com/build/building/multi-platform/#prerequisites
docker buildx create \
  --name container-builder \
  --driver docker-container \
  --driver-opt '"env.http_proxy='$HTTP_PROXY'"' \
  --driver-opt '"env.https_proxy='$HTTPS_PROXY'"' \
  --driver-opt '"env.no_proxy='$NO_PROXY'"' \
  --bootstrap \
  --use

# https://hub.docker.com/r/tonistiigi/binfmt used to install qemu for multi-arch
# support: https://docs.docker.com/build/building/multi-platform/#qemu.
docker run --privileged --rm docker.io/tonistiigi/binfmt:qemu-v9.2.2 --install all

# Enable to ensure that the newly created builder is used per default when running docker build.
# export BUILDX_BUILDER=container-builder

eval "$@"
