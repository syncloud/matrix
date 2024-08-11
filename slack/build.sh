#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/../build/snap
mkdir -p $BUILD_DIR/bin

cd ${DIR}/../build

wget https://github.com/mautrix/slack/archive/refs/heads/main.tar.gz
tar -xf main.tar.gz
rm -rf main.tar.gz
cd slack-main

GO_LDFLAGS="-s -w -linkmode external -extldflags -static -X main.Tag=0 -X main.Commit=0 -X 'main.BuildTime=`date '+%b %_d %Y, %H:%M:%S'`'"
go build -tags nocrypto -ldflags "$GO_LDFLAGS" -o $BUILD_DIR/bin/slack ./cmd/mautrix-slack
