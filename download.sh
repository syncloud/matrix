#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

ARCH=$(uname -m)
DOWNLOAD_URL=https://github.com/syncloud/3rdparty/releases/download/
VERSION=$1
apt update
apt install -y wget

BUILD_DIR=${DIR}/build/snap
mkdir -p $BUILD_DIR

cd ${DIR}/build
wget ${DOWNLOAD_URL}/nginx/nginx-${ARCH}.tar.gz
tar xf nginx-${ARCH}.tar.gz
mv nginx ${BUILD_DIR}

VERSION=main
wget https://github.com/cyberb/dendrite/archive/refs/heads/$VERSION.tar.gz -O matrix.tar.gz
#wget https://github.com/matrix-org/dendrite/archive/refs/tags/v$VERSION.tar.gz -O matrix.tar.gz
tar xf matrix.tar.gz
mv dendrite-$VERSION matrix

