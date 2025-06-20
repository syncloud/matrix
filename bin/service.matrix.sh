#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
$DIR/wait-for-db.sh matrix
$DIR/wait-for-configure.sh
exec $DIR/../bin/dendrite --config /var/snap/matrix/current/config/matrix.yaml --unix-socket=/var/snap/matrix/current/matrix.socket
