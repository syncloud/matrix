#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )/.." && pwd )
BUILD=$1
ARCH=$2
BUILD_DIR=${DIR}/build/snap/bin
mkdir -p ${BUILD_DIR}

${DIR}/download.sh http://${ARTIFACT_HOST}:8081/files/matrix/${BUILD}-shared/caddy-${ARCH} ${BUILD_DIR}/caddy
chmod +x ${BUILD_DIR}/caddy
