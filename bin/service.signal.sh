#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
$DIR/wait-for-db.sh signal
$DIR/wait-for-configure.sh
exec $DIR/signal -c /var/snap/matrix/current/config/signal.yaml --ignore-foreign-tables --ignore-unsupported-server

