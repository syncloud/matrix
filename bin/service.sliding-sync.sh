#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
$DIR/wait-for-db.sh sync
$DIR/wait-for-configure.sh
. /var/snap/matrix/current/config/env
export SYNCV3_BINDADDR=/var/snap/matrix/current/sliding-sync.sock
export SYNCV3_SERVER=/var/snap/matrix/current/matrix.socket
export SYNCV3_SECRET=$(cat /var/snap/matrix/current/sync.secret)
exec $DIR/sliding-sync
