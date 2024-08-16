#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

#WHATSAPP_VERSION=0.8.2
#MAUTRIX_GO=master

BUILD_DIR=${DIR}/../build/snap
mkdir -p $BUILD_DIR/bin

cd ${DIR}/../build

#wget https://github.com/mautrix/whatsapp/releases/download/v$WHATSAPP_VERSION/mautrix-whatsapp-$GO_ARCH -O $BUILD_DIR/bin/whatsapp
#chmod +x $BUILD_DIR/bin/whatsapp
#BRANCH=master
#wget https://github.com/cyberb/mautrix-go/archive/refs/heads/$BRANCH.tar.gz
#tar -xf $BRANCH.tar.gz
#rm -rf $BRANCH.tar.gz
#mv mautrix-go-$BRANCH mautrix-go
#wget https://github.com/mautrix/go/archive/refs/heads/${MAUTRIX_GO}.tar.gz
#tar xf ${MAUTRIX_GO}.tar.gz
#rm ${MAUTRIX_GO}.tar.gz
#mv go-${MAUTRIX_GO} mautrix-go

#wget https://github.com/cyberb/whatsapp/archive/refs/heads/master.tar.gz
wget https://github.com/mautrix/whatsapp/archive/refs/heads/main.tar.gz
tar -xf main.tar.gz
rm -rf main.tar.gz
cd whatsapp-*

#cat <<EOT >> go.work

#go 1.20

#use (
#    ./whatsapp
#    ./mautrix-go
#)
#EOT

GO_LDFLAGS="-s -w -linkmode external -extldflags -static -X main.Tag=0 -X main.Commit=0 -X 'main.BuildTime=`date '+%b %_d %Y, %H:%M:%S'`'"
go build -tags nocrypto -ldflags "$GO_LDFLAGS" -o $BUILD_DIR/bin/whatsapp .
