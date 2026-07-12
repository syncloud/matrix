#!/bin/sh -xe

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
wget "https://github.com/mautrix/telegram/releases/download/v$VERSION/mautrix-telegram-$ARCH" -O $BUILD_DIR/bin/telegram
chmod +x $BUILD_DIR/bin/telegram