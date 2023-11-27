#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
$DIR/wait-for-db.sh signald
$DIR/wait-for-configure.sh
exec $DIR/../signal/bin/java.sh -classpath "$DIR/../signal/lib/*" io.finn.signald.Main \
  --socket=/var/snap/matrix/current/signald.socket \
  '--database=postgresql://matrix:matrix@localhost/signald?socketFactory=org.newsclub.net.unix.AFUNIXSocketFactory$FactoryArg&socketFactoryArg=/var/snap/matrix/current/database/.s.PGSQL.5436'
