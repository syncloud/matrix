#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

TEMPLATE=${DIR}/../config/telegram.yaml.template
CONFIG=${DIR}/../config/telegram.yaml

cp $TEMPLATE $CONFIG
sed -i "s/$TELEGRAM_API_ID/{TELEGRAM_API_ID}/g" $CONFIG
sed -i "s/$TELEGRAM_API_HASH/{TELEGRAM_API_HASH}/g" $CONFIG