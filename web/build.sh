#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

ELEMENT_VERSION=1.11.73
apt update
apt install -y wget

BUILD_DIR=${DIR}/../build/snap
mkdir -p $BUILD_DIR/bin

cd ${DIR}/../build
wget https://github.com/vector-im/element-web/releases/download/v$ELEMENT_VERSION/element-v$ELEMENT_VERSION.tar.gz -O element.tar.gz
tar xf element.tar.gz
mv element-v$ELEMENT_VERSION ${BUILD_DIR}/element
cd ${BUILD_DIR}/element
ln -s /var/snap/matrix/current/config/element.json config.json

