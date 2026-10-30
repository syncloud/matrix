#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )/.." && pwd )
CADDY_VERSION=$1
L4_VERSION=$2
XCADDY_VERSION=$3
OUT=${DIR}/artifact/shared
mkdir -p ${OUT}
export CGO_ENABLED=0

go install github.com/caddyserver/xcaddy/cmd/xcaddy@v${XCADDY_VERSION}
for arch in amd64 arm64; do
  for attempt in 1 2 3 4 5; do
    if GOARCH=${arch} xcaddy build v${CADDY_VERSION} --with github.com/mholt/caddy-l4=github.com/cyberb/caddy-l4@v${L4_VERSION} --output ${OUT}/caddy-${arch}; then
      break
    fi
    if [ $attempt -eq 5 ]; then
      exit 1
    fi
    sleep 10
  done
done
ls -la ${OUT}
