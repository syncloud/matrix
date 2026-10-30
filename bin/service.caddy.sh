#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
$DIR/bin/wait-for-configure.sh
rm -f $SNAP_COMMON/web.socket $SNAP_COMMON/stream.socket $SNAP_DATA/stream-http.sock
export XDG_DATA_HOME=$SNAP_DATA/caddy
exec $DIR/bin/caddy run --config $SNAP_DATA/config/Caddyfile --adapter caddyfile
