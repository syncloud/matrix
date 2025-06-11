#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

apt update
apt install -y libmagic1
pip install -r requirements.txt

BUILD_DIR=${DIR}/../build/snap/python
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}
cp -r /usr ${BUILD_DIR}
cp -r /bin ${BUILD_DIR}
cp -r /lib ${BUILD_DIR}
cp -r ${DIR}/bin/* ${BUILD_DIR}/bin
