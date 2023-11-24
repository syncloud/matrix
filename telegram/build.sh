#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

TEMPLATE=${DIR}/../config/telegram.template.yaml
CONFIG=${DIR}/../config/telegram.yaml

cp $TEMPLATE $CONFIG
sed -i "s/{TELEGRAM_API_ID}/$TELEGRAM_API_ID/g" $CONFIG
sed -i "s/{TELEGRAM_API_HASH}/$TELEGRAM_API_HASH/g" $CONFIG

BUILD_DIR=${DIR}/../build/snap
cd ${DIR}/../build/mautrix-python
cp mautrix/appservice/appservice.py $BUILD_DIR/python/usr/local/lib/python3.8/site-packages/mautrix/appservice
cp mautrix/api.py $BUILD_DIR/python/usr/local/lib/python3.8/site-packages/mautrix
