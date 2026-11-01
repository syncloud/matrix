#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
BUILD_DIR=${DIR}/../build/snap

${BUILD_DIR}/bin/caddy version
${BUILD_DIR}/bin/caddy list-modules | grep -q '^layer4.matchers.regexp$'
