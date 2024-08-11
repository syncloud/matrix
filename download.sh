#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

ARCH=$(uname -m)
GO_ARCH=$1
ELEMENT_VERSION=1.11.73
apt update
apt install -y wget

BUILD_DIR=${DIR}/build/snap
mkdir -p $BUILD_DIR/bin

cd ${DIR}/build
wget https://github.com/vector-im/element-web/releases/download/v$ELEMENT_VERSION/element-v$ELEMENT_VERSION.tar.gz -O element.tar.gz
tar xf element.tar.gz
mv element-v$ELEMENT_VERSION ${BUILD_DIR}/element
cd ${BUILD_DIR}/element
ln -s /var/snap/matrix/current/config/element.json config.json

cd ${DIR}/build
#wget https://github.com/cyberb/sliding-sync/archive/refs/heads/master.tar.gz
wget https://github.com/matrix-org/sliding-sync/archive/refs/heads/main.tar.gz
tar -xf main.tar.gz
rm -rf main.tar.gz
mv sliding-sync-main sliding-sync

cd ${DIR}/build
wget https://github.com/cyberb/mautrix-python/archive/refs/heads/master.tar.gz
tar -xf master.tar.gz
rm -rf master.tar.gz
mv mautrix-python-master mautrix-python

cd ${DIR}/build
wget https://github.com/mautrix/slack/archive/refs/heads/main.tar.gz
tar -xf main.tar.gz
rm -rf main.tar.gz
mv slack-main slack

cd ${DIR}/build
wget https://github.com/mautrix/discord/archive/refs/heads/main.tar.gz
tar -xf main.tar.gz
rm -rf main.tar.gz
mv discord-main discord
