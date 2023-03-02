#!/bin/bash

retry=0
retries=100
NEXT=/snap/matrix/current/version
CURRENT=/var/snap/matrix/current/version
while ! diff $NEXT $CURRENT; do
    if [[ $retry -gt $retries ]]; then
        echo "waiting for db failed after $retry attempts (current: $(cat $CURRENT), next $(cat $NEXT)"
        exit 1
    fi
    retry=$((retry + 1))
    echo "waiting for db $retry/$retries (current: $(cat $CURRENT), next $(cat $NEXT)"
    sleep 2
done
