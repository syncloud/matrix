#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

exec $DIR/dendrite-monolith-server --config ${SNAP_DATA}/config/matrix.yaml
