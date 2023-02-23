#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
$DIR/wait-for-db.sh
exec $DIR/dendrite --config /var/snap/matrix/current/config/matrix.yaml --unix-socket=/var/snap/matrix/current/matrix.socket
