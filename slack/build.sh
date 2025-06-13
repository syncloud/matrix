#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}
VERSION=$1
BUILD_DIR=${DIR}/../build/snap
mkdir -p $BUILD_DIR/bin

cd ${DIR}/../build

wget https://github.com/mautrix/slack/archive/$VERSION.tar.gz
tar -xf $VERSION.tar.gz
cd slack-*
#GO_LDFLAGS="-s -w -linkmode external -extldflags -static -X main.Tag=0 -X main.Commit=0 -X 'main.BuildTime=`date '+%b %_d %Y, %H:%M:%S'`'"
CGO_ENABLED=0 go build -tags nocrypto -o $BUILD_DIR/bin/slack ./cmd/mautrix-slack
#go build -tags goolm -ldflags "$GO_LDFLAGS" -o $BUILD_DIR/bin/slack ./cmd/mautrix-slack
