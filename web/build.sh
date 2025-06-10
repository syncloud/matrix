#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

VERSION=$1
apt update
apt install -y wget

BUILD_DIR=${DIR}/../build/snap
mkdir -p $BUILD_DIR/bin

cd ${DIR}/../build
wget https://github.com/element-hq/element-web/releases/download/v$VERSION/element-v$VERSION.tar.gz -O element.tar.gz
tar xf element.tar.gz
mv element-v$VERSION ${BUILD_DIR}/element
cd ${BUILD_DIR}/element
ln -s /var/snap/matrix/current/config/element.json config.json

