#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
VERSION=$1
#VERSION=syncloud

BUILD_DIR=${DIR}/../build/snap/matrix
mkdir -p $BUILD_DIR/bin

cd $DIR/../build

wget https://github.com/cyberb/dendrite/archive/refs/heads/$VERSION.tar.gz -O matrix.tar.gz
#wget https://github.com/matrix-org/dendrite/archive/refs/tags/v$VERSION.tar.gz -O matrix.tar.gz
tar xf matrix.tar.gz
cd dendrite-$VERSION

go build -trimpath -v -o $BUILD_DIR/bin/matrix ./cmd/dendrite
go build -ldflags '-linkmode external -extldflags -static' -trimpath -v -o $BUILD_DIR/bin/generate-keys ./cmd/generate-keys
ldd $BUILD_DIR/bin/matrix
cp $DIR/bin/* $BUILD_DIR/bin
mkdir $BUILD_DIR/lib
cp /lib/*/libpthread.so* $BUILD_DIR/lib
cp /lib/*/libdl.so.* $BUILD_DIR/lib
cp /lib/*/libc.so.* $BUILD_DIR/lib
cp /lib/*/ld-*.so $BUILD_DIR/lib
