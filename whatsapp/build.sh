#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

#WHATSAPP_VERSION=0.8.2
VERSION=$1

BUILD_DIR=${DIR}/../build/snap
mkdir -p $BUILD_DIR/bin

cd ${DIR}/../build

#wget https://github.com/mautrix/whatsapp/releases/download/v$WHATSAPP_VERSION/mautrix-whatsapp-$GO_ARCH -O $BUILD_DIR/bin/whatsapp
#chmod +x $BUILD_DIR/bin/whatsapp
#BRANCH=master
#wget https://github.com/cyberb/mautrix-go/archive/refs/heads/$BRANCH.tar.gz
#tar -xf $BRANCH.tar.gz
#rm -rf $BRANCH.tar.gz

#wget https://github.com/cyberb/whatsapp/archive/refs/heads/master.tar.gz
#wget https://github.com/mautrix/whatsapp/archive/refs/heads/main.tar.gz
#tar -xf main.tar.gz
#rm -rf main.tar.gz
#cd whatsapp-*

#cat <<EOT >> go.work

#go 1.20

#use (
#    ./whatsapp
#    ./mautrix-go
#)
#EOT

wget https://github.com/mautrix/whatsapp/archive/refs/tags/v$VERSION.tar.gz
tar xf v$VERSION.tar.gz
cd whatsapp-$VERSION

CGO_ENABLED=0
GO_LDFLAGS="-X main.Tag=0 -X main.Commit=0 -X 'main.BuildTime=`date '+%b %_d %Y, %H:%M:%S'`'"
go build -tags nocrypto -ldflags "$GO_LDFLAGS" -o $BUILD_DIR/bin/whatsapp ./cmd/mautrix-whatsapp
