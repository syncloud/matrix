#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
$DIR/wait-for-db.sh discord
$DIR/wait-for-configure.sh
$DIR/wait-for-matrix.sh
exec $DIR/discord -c /var/snap/matrix/current/config/discord.yaml --ignore-foreign-tables

