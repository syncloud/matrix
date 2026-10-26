#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
$DIR/wait-for-configure.sh
exec $DIR/tuwunel --config /var/snap/matrix/current/config/tuwunel.toml
