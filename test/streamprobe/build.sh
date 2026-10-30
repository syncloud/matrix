#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
OUT=${DIR}/../../build/test
mkdir -p ${OUT}
cd ${DIR}

go test ./...
CGO_ENABLED=0 go build -o ${OUT}/streamprobe .
