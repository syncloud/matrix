#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
$DIR/wait-for-configure.sh
$DIR/wait-for-matrix.sh
. /var/snap/matrix/current/config/livekit-jwt.env
exec $DIR/livekit-jwt
