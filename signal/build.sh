#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}
VERSION=$1
ARCH=$2
BUILD_DIR=${DIR}/../build/snap
mkdir -p ${BUILD_DIR}

wget https://github.com/mautrix/signal/releases/download/v$VERSION/mautrix-signal-$ARCH -O $BUILD_DIR/bin/signal
chmod +x $BUILD_DIR/bin/signal
