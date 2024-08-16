#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
$DIR/wait-for-db.sh whatsapp
$DIR/wait-for-configure.sh
exec $DIR/whatsapp -c /var/snap/matrix/current/config/whatsapp.yaml --ignore-foreign-tables --ignore-unsupported-server

