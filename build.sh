#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/build/snap
mkdir -p $BUILD_DIR/bin

cd ${DIR}/build/matrix
CGO_ENABLED=1 go build -trimpath -v -o $BUILD_DIR/bin ./cmd/...
rm $BUILD_DIR/bin/dendrite-*

cd ${DIR}/build/whatsapp-master
#apt update
#apt install -y libolm-dev
GO_LDFLAGS="-s -w -linkmode external -extldflags -static -X main.Tag=0 -X main.Commit=0 -X 'main.BuildTime=`date '+%b %_d %Y, %H:%M:%S'`'"
go build -tags nocrypto -ldflags "$GO_LDFLAGS" -o $BUILD_DIR/bin/whatsapp
