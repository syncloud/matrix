#!/bin/bash -e
DIR=$(cd "$(dirname "$0")" && pwd)
cd "$DIR"

ARTIFACT_SUBDIR=$1
SPEC=${2:-specs}
PROJECT=${3:-desktop}

export PLAYWRIGHT_FULL_DOMAIN=bookworm.com
export PLAYWRIGHT_APP_DOMAIN=matrix.bookworm.com
export PLAYWRIGHT_DEVICE_HOST=matrix.bookworm.com
export PLAYWRIGHT_DEVICE_USER=user
export PLAYWRIGHT_DEVICE_PASSWORD=Password1
export PLAYWRIGHT_SSH_USER=root
export PLAYWRIGHT_SSH_PASSWORD=Password1
export PLAYWRIGHT_PROJECT=${PROJECT}
export PLAYWRIGHT_ARTIFACT_DIR=/drone/src/artifact/${ARTIFACT_SUBDIR}

apt-get update -qq
apt-get install -y -qq sshpass openssh-client curl

APP_IP=$(getent hosts "$PLAYWRIGHT_APP_DOMAIN" | awk '{print $1}' | head -1)
if [ -n "$APP_IP" ]; then
  echo "$APP_IP auth.$PLAYWRIGHT_FULL_DOMAIN" >> /etc/hosts
fi

npm install --no-audit --no-fund
npx playwright test --project="${PROJECT}" "$SPEC"
