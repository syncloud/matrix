#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
VERSION=$1
ARCH=$2
BUILD_DIR=${DIR}/../build/snap
mkdir -p ${BUILD_DIR}/bin

${DIR}/../download.sh https://github.com/cyberb/tuwunel/releases/download/v${VERSION}/tuwunel-${ARCH} ${BUILD_DIR}/bin/tuwunel
chmod +x ${BUILD_DIR}/bin/tuwunel
${BUILD_DIR}/bin/tuwunel --version
