#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
$DIR/wait-for-db.sh signal
$DIR/wait-for-configure.sh
exec $DIR/../python/bin/python -m mautrix_signal -c /var/snap/matrix/current/config/signal.yaml

