#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
VERSION=$1

BUILD_DIR=${DIR}/../build/snap/matrix
mkdir -p $BUILD_DIR/bin

cd $DIR/../build

wget https://github.com/cyberb/dendrite/archive/refs/heads/$VERSION.tar.gz -O matrix.tar.gz
tar xf matrix.tar.gz
cd dendrite-$VERSION

CGO_ENABLED=0 go build -trimpath -v -o $BUILD_DIR/bin/matrix ./cmd/dendrite
CGO_ENABLED=0 go build -trimpath -v -o $BUILD_DIR/bin/generate-keys ./cmd/generate-keys
ldd $BUILD_DIR/bin/matrix || true
ldd $BUILD_DIR/bin/generate-keys || true
