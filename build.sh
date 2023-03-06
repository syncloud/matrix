#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/build/snap
mkdir -p $BUILD_DIR/bin

cd ${DIR}/build/matrix
go build -ldflags '-s -w -linkmode external -extldflags -static' -trimpath -v -o $BUILD_DIR/bin/dendrite ./cmd/dendrite
go build -ldflags '-s -w -linkmode external -extldflags -static' -trimpath -v -o $BUILD_DIR/bin/generate-keys ./cmd/generate-keys

cd ${DIR}/build
cat <<EOT >> go.work

go 1.18

use (
    ./whatsapp-master
    ./mautrix-go-master
)
EOT              
GO_LDFLAGS="-s -w -linkmode external -extldflags -static -X main.Tag=0 -X main.Commit=0 -X 'main.BuildTime=`date '+%b %_d %Y, %H:%M:%S'`'"
go build -tags nocrypto -ldflags "$GO_LDFLAGS" -o $BUILD_DIR/bin/whatsapp ./whatsapp-master
