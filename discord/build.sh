#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
COMMIT=$1
BUILD_DIR=${DIR}/../build/snap
mkdir -p ${BUILD_DIR}/bin ${DIR}/../build

apk add --no-cache gcc musl-dev
cd ${DIR}/../build
${DIR}/../download.sh https://github.com/mautrix/discord/archive/${COMMIT}.tar.gz discord.tar.gz
tar xzf discord.tar.gz
cd discord-${COMMIT}
CGO_ENABLED=1 go build -tags goolm \
  -ldflags "-s -w -linkmode external -extldflags -static -X main.Commit=${COMMIT}" \
  -o ${BUILD_DIR}/bin/discord ./cmd/mautrix-discord
${BUILD_DIR}/bin/discord --version
