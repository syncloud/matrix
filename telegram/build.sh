#!/bin/sh -e

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

VERSION=$1
ARCH=$2

TEMPLATE=${DIR}/../config/telegram.template.yaml
CONFIG=${DIR}/../config/telegram.yaml

cp $TEMPLATE $CONFIG
sed -i "s/{TELEGRAM_API_ID}/$TELEGRAM_API_ID/g" $CONFIG
sed -i "s/{TELEGRAM_API_HASH}/$TELEGRAM_API_HASH/g" $CONFIG

BUILD_DIR=${DIR}/../build/snap
#cd ${DIR}/../build
#wget https://github.com/cyberb/mautrix-python/archive/refs/heads/master.tar.gz
#tar -xf master.tar.gz
#rm -rf master.tar.gz
#cd mautrix-python-master
#cp mautrix/appservice/appservice.py $BUILD_DIR/python/usr/local/lib/python*/site-packages/mautrix/appservice
#cp mautrix/api.py $BUILD_DIR/python/usr/local/lib/python*/site-packages/mautrix

#wget "https://mau.dev/mautrix/telegramgo/-/jobs/artifacts/$VERSION/raw/mautrix-telegram?job=build $ARCH v2" -O $BUILD_DIR/bin/telegram
wget "https://mau.dev/mautrix/telegramgo/-/jobs/artifacts/$VERSION/download?job=build $ARCH v2" -O telegram.zip
unzip telegram.zip
mv mautrix-telegram $BUILD_DIR/bin/telegram
chmod +x $BUILD_DIR/bin/telegram