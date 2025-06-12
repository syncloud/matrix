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
wget "https://mau.dev/mautrix/telegramgo/-/jobs/artifacts/$VERSION/download?job=build $ARCH v2" -O telegram.zip
unzip telegram.zip
mv mautrix-telegram $BUILD_DIR/bin/telegram
chmod +x $BUILD_DIR/bin/telegram