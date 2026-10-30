#!/bin/bash

retry=0
retries=100
SOCKET=/var/snap/matrix/current/matrix.sock
while [[ ! -S $SOCKET ]]; do
    if [[ $retry -gt $retries ]]; then
        echo "waiting for matrix socket failed after $retry attempts"
        exit 1
    fi
    retry=$((retry + 1))
    echo "waiting for matrix socket $retry/$retries"
    sleep 2
done
echo "matrix socket is ready"
