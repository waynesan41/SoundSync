#!/bin/bash
set -e

# Ensure the keyfile is mounted before we copy it.
if [ ! -f /etc/mongo-keyfile-src ]; then
  echo "Keyfile source not found at /etc/mongo-keyfile-src" >&2
  exit 1
fi

cp /etc/mongo-keyfile-src /etc/mongo-keyfile
chmod 400 /etc/mongo-keyfile
chown mongodb:mongodb /etc/mongo-keyfile

exec /usr/local/bin/docker-entrypoint.sh "$@"
