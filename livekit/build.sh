#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
LIVEKIT_VERSION=$1
JWT_VERSION=$2
ARCH=$3
BUILD_DIR=${DIR}/../build/snap
mkdir -p ${BUILD_DIR}/bin

${DIR}/../download.sh https://github.com/cyberb/livekit/releases/download/v${LIVEKIT_VERSION}/livekit-${ARCH} ${BUILD_DIR}/bin/livekit
chmod +x ${BUILD_DIR}/bin/livekit
${BUILD_DIR}/bin/livekit --version

${DIR}/../download.sh https://github.com/cyberb/lk-jwt-service/releases/download/v${JWT_VERSION}/lk-jwt-service-${ARCH} ${BUILD_DIR}/bin/livekit-jwt
chmod +x ${BUILD_DIR}/bin/livekit-jwt
