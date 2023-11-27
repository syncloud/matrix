#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/../build/snap/signal
while ! docker build -t signal:syncloud . ; do
  echo "retry docker"
  sleep 2
done
docker create --name=signal signal:syncloud
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}
docker export signal -o app.tar
tar xf app.tar
rm -rf app.tar
cp ${DIR}/java.sh ${BUILD_DIR}/bin/