#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
BUILD_DIR=${DIR}/../build/snap

${BUILD_DIR}/bin/caddy version
