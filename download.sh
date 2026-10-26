#!/bin/sh -e

URL=$1
OUT=$2
for attempt in 1 2 3 4 5; do
  if wget -q "$URL" -O "$OUT"; then
    exit 0
  fi
  echo "download failed ($attempt/5): $URL"
  sleep 10
done
exit 1
