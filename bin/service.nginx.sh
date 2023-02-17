#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

/bin/rm -f /var/snap/matrix/common/web.socket
exec ${DIR}/nginx/sbin/nginx -c /var/snap/matrix/current/config/nginx.conf -p ${DIR}/nginx -e stderr
