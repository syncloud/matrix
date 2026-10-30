#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
$DIR/wait-for-configure.sh
exec $DIR/livekit --config /var/snap/matrix/current/config/livekit.yaml
