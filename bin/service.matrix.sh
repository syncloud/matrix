#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

exec $DIR/dendrite-monolith-server --config /var/snap/matrix/current/config/matrix.yaml --unix-socket=/var/snap/matrix/common/web.socket
