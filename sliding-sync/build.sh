#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
VERSION=$1
ARCH=$2
BUILD_DIR=${DIR}/../build/snap
mkdir -p $BUILD_DIR/bin
wget https://github.com/matrix-org/sliding-sync/releases/download/v$VERSION/syncv3_linux_$ARCH -O $BUILD_DIR/bin/sliding-sync
chmod +x $BUILD_DIR/bin/sliding-sync