#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
BUILD_DIR=${DIR}/../build/snap

${BUILD_DIR}/bin/livekit --version
${BUILD_DIR}/bin/livekit-jwt 2>&1 | grep 'LIVEKIT_URL must be set'
