#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
VERSION=$1
ARCH=$2
BUILD_DIR=${DIR}/../build/snap/bin
mkdir -p ${BUILD_DIR}

${DIR}/../download.sh https://github.com/cyberb/caddy-syncloud/releases/download/v${VERSION}/caddy-${ARCH} ${BUILD_DIR}/caddy
chmod +x ${BUILD_DIR}/caddy
${BUILD_DIR}/caddy version
${BUILD_DIR}/caddy list-modules | grep -q '^layer4.matchers.regexp$'
