#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}
apt update
apt install -y wget
TEMPLATE=${DIR}/../config/telegram.template.yaml
CONFIG=${DIR}/../config/telegram.yaml

cp $TEMPLATE $CONFIG
sed -i "s/{TELEGRAM_API_ID}/$TELEGRAM_API_ID/g" $CONFIG
sed -i "s/{TELEGRAM_API_HASH}/$TELEGRAM_API_HASH/g" $CONFIG

BUILD_DIR=${DIR}/../build/snap
cd ${DIR}/../build
wget https://github.com/cyberb/mautrix-python/archive/refs/heads/master.tar.gz
tar -xf master.tar.gz
rm -rf master.tar.gz
cd mautrix-python-master

cp mautrix/appservice/appservice.py $BUILD_DIR/python/usr/local/lib/python*/site-packages/mautrix/appservice
cp mautrix/api.py $BUILD_DIR/python/usr/local/lib/python*/site-packages/mautrix
