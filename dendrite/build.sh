#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
VERSION=$1

BUILD_DIR=${DIR}/../build/snap
mkdir -p $BUILD_DIR/bin

cd $DIR/../build

wget https://github.com/cyberb/dendrite/archive/refs/heads/$VERSION.tar.gz -O dendrite.tar.gz
tar xf dendrite.tar.gz
cd dendrite-$VERSION

CGO_ENABLED=0 go build -trimpath -v -o $BUILD_DIR/bin/dendrite ./cmd/dendrite
CGO_ENABLED=0 go build -trimpath -v -o $BUILD_DIR/bin/generate-keys ./cmd/generate-keys
ldd $BUILD_DIR/bin/dendrite || true
ldd $BUILD_DIR/bin/generate-keys || true
