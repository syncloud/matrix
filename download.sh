#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

ARCH=$(uname -m)
DOWNLOAD_URL=https://github.com/syncloud/3rdparty/releases/download/
VERSION=$1
GO_ARCH=$2
ELEMENT_VERSION=1.11.23
WHATSAPP_VERSION=0.8.2
MAUTRIX_GO=master
apt update
apt install -y wget

BUILD_DIR=${DIR}/build/snap
mkdir -p $BUILD_DIR/bin

cd ${DIR}/build
wget ${DOWNLOAD_URL}/nginx/nginx-${ARCH}.tar.gz
tar xf nginx-${ARCH}.tar.gz
mv nginx ${BUILD_DIR}

cd ${DIR}/build
VERSION=syncloud
wget https://github.com/cyberb/dendrite/archive/refs/heads/$VERSION.tar.gz -O matrix.tar.gz
#wget https://github.com/matrix-org/dendrite/archive/refs/tags/v$VERSION.tar.gz -O matrix.tar.gz
tar xf matrix.tar.gz
mv dendrite-$VERSION matrix

cd ${DIR}/build
wget https://github.com/vector-im/element-web/releases/download/v$ELEMENT_VERSION/element-v$ELEMENT_VERSION.tar.gz -O element.tar.gz
tar xf element.tar.gz
mv element-v$ELEMENT_VERSION ${BUILD_DIR}/element
cd ${BUILD_DIR}/element
ln -s /var/snap/matrix/current/config/element.json config.json

cd ${DIR}/build
#wget https://github.com/mautrix/whatsapp/releases/download/v$WHATSAPP_VERSION/mautrix-whatsapp-$GO_ARCH -O $BUILD_DIR/bin/whatsapp
#chmod +x $BUILD_DIR/bin/whatsapp
#BRANCH=master
#wget https://github.com/cyberb/mautrix-go/archive/refs/heads/$BRANCH.tar.gz
#tar -xf $BRANCH.tar.gz
#rm -rf $BRANCH.tar.gz
#mv mautrix-go-$BRANCH mautrix-go
wget https://github.com/mautrix/go/archive/refs/tags/v${MAUTRIX_GO}.tar.gz
tar xf v${MAUTRIX_GO}.tar.gz
rm v${MAUTRIX_GO}.tar.gz
mv go-${MAUTRIX_GO} mautrix-go

#wget https://github.com/cyberb/whatsapp/archive/refs/heads/master.tar.gz
wget https://github.com/mautrix/whatsapp/archive/refs/heads/master.tar.gz
tar -xf master.tar.gz
rm -rf master.tar.gz
mv whatsapp-master whatsapp

