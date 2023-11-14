#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
$DIR/wait-for-db.sh sync
$DIR/wait-for-configure.sh
. /var/snap/matrix/current/env
export SYNCV3_BINDADDR=/var/snap/matrix/current/sliding-sync.sock
export SYNCV3_SERVER=/var/snap/matrix/current/matrix.socket
exec $DIR/sliding-sync
