#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

BUILD_DIR=${DIR}/../build/snap
mkdir -p $BUILD_DIR/bin

cd $DIR/../build

#wget https://github.com/cyberb/sliding-sync/archive/refs/heads/master.tar.gz
wget https://github.com/matrix-org/sliding-sync/archive/refs/heads/main.tar.gz
tar -xf main.tar.gz
rm -rf main.tar.gz
cd sliding-sync-main

go build -o $BUILD_DIR/bin/sliding-sync ./cmd/syncv3
ldd $BUILD_DIR/bin/sliding-sync
