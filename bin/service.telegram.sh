#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
$DIR/wait-for-db.sh telegram
$DIR/wait-for-configure.sh
exec $DIR/python/bin/python -m mautrix_telegram -c /var/snap/matrix/current/config/telegram.yaml

