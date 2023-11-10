#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

BUILD_DIR=${DIR}/../build/snap/matrix
mkdir -p $BUILD_DIR/bin

cd $DIR/../build/sliding-sinc
go build -o $BUILD_DIR/bin/sliding-sync ./cmd/syncv3
ldd $BUILD_DIR/bin/sliding-sync
