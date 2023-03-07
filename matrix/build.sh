#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

BUILD_DIR=${DIR}/../build/snap/matrix
mkdir -p $BUILD_DIR/bin

cd $DIR/../build/matrix
go build -trimpath -v -o $BUILD_DIR/bin/matrix ./cmd/dendrite
ldd $BUILD_DIR/bin/matrix
go build -ldflags '-linkmode external -extldflags -static' -trimpath -v -o $BUILD_DIR/bin/generate-keys ./cmd/generate-keys
cp $BDIR/bin/* $BUILD_DIR/bin
mkdir $BUILD_DIR/lib
cp /lib/*/libpthread.so* $BUILD_DIR/lib
cp /lib/*/libdl.so.* $BUILD_DIR/lib
cp /lib/*/libc.so.* $BUILD_DIR/lib
cp /lib/*/ld-*.so $BUILD_DIR/lib
