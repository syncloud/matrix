#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
HOOKS_OUT=${DIR}/../build/snap/meta/hooks
BIN_OUT=${DIR}/../build/snap/bin
mkdir -p ${HOOKS_OUT} ${BIN_OUT}
cd ${DIR}

go test ./...
CGO_ENABLED=0 go build -o ${HOOKS_OUT}/install ./cmd/install
CGO_ENABLED=0 go build -o ${HOOKS_OUT}/configure ./cmd/configure
CGO_ENABLED=0 go build -o ${HOOKS_OUT}/pre-refresh ./cmd/pre-refresh
CGO_ENABLED=0 go build -o ${HOOKS_OUT}/post-refresh ./cmd/post-refresh
CGO_ENABLED=0 go build -o ${BIN_OUT}/cli ./cmd/cli
