#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
$DIR/wait-for-db.sh telegram
$DIR/wait-for-configure.sh
exec $DIR/telegram -c /var/snap/matrix/current/config/telegram.yaml --ignore-foreign-tables --ignore-unsupported-server

