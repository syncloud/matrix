#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}
VERSION=$1
ARCH=$2
BRIDGE=$3
BUILD_DIR=${DIR}/build/snap
mkdir -p ${BUILD_DIR}

wget https://github.com/mautrix/$BRIDGE/releases/download/v$VERSION/mautrix-$BRIDGE-$ARCH -O $BUILD_DIR/bin/$BRIDGE
chmod +x $BUILD_DIR/bin/$BRIDGE
