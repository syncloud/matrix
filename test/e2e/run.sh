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
apt-get install -y -qq sshpass openssh-client curl ca-certificates libnss3-tools

APP_IP=$(getent hosts "$PLAYWRIGHT_APP_DOMAIN" | awk '{print $1}' | head -1)
if [ -n "$APP_IP" ]; then
  echo "$APP_IP auth.$PLAYWRIGHT_FULL_DOMAIN" >> /etc/hosts
fi

# Trust the Syncloud platform CA so the device cert is valid: a genuine
# secure context lets element-web's media service worker register (avoids
# the "failed to load service worker" toast) instead of masking it.
CA=/tmp/syncloud.ca.crt
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"
sshpass -p "$PLAYWRIGHT_SSH_PASSWORD" scp $SSH_OPTS \
  "$PLAYWRIGHT_SSH_USER@$PLAYWRIGHT_DEVICE_HOST:/var/snap/platform/current/syncloud.ca.crt" "$CA"
cp "$CA" /usr/local/share/ca-certificates/syncloud.crt
update-ca-certificates
export NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt
mkdir -p "$HOME/.pki/nssdb"
certutil -d "sql:$HOME/.pki/nssdb" -A -n syncloud -t "C,," -i "$CA"

npm install --no-audit --no-fund
npx playwright test --project="${PROJECT}" "$SPEC"
