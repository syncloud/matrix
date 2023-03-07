#!/bin/bash

retry=0
retries=100
while ! snap run matrix.psql $1 -c "" ; do
    if [[ $retry -gt $retries ]]; then
        echo "waiting for db failed after $retry attempts"
        exit 1
    fi
    retry=$((retry + 1))
    echo "waiting for db $retry/$retries"
    sleep 2
done
echo "db $1 is ready"
