#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/build/snap
mkdir -p $BUILD_DIR/bin

cd ${DIR}/build/matrix
CGO_ENABLED=1 go build -trimpath -v -o $BUILD_DIR/bin ./cmd/...
rm $BUILD_DIR/bin/dendrite-*

cd ${DIR}/build/whatsapp-master
cat <<EOT >> work.go
go 1.18

use (
    ../mautrix-go-master
)
EOT

go build -tags nocrypto -o $BUILD_DIR/bin/whatsapp
