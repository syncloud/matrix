#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
$DIR/wait-for-db.sh slack
$DIR/wait-for-configure.sh
exec $DIR/slack -c /var/snap/matrix/current/config/slack.yaml --ignore-foreign-tables

