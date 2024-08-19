#!/bin/bash
set -euo pipefail

MONGO_USERNAME=${MONGO_USERNAME:=""}
MONGO_PASSWORD=${MONGO_PASSWORD:=""}
RESTIC_DOCKER_SNAPSHOT_ID=${RESTIC_DOCKER_SNAPSHOT_ID:="latest"}

echo "Download snapshot \"$RESTIC_DOCKER_SNAPSHOT_ID\"..."
restic restore "$RESTIC_DOCKER_SNAPSHOT_ID" --target /


if [[ "$MONGO_AUTH_DISABLED" == "1" || "$MONGO_AUTH_DISABLED" == "true" ]]; then
    mongorestore --host="$MONGO_HOST:${MONGO_PORT:-27017}" --archive="/backups/backup.archive"
else
    mongorestore --host="$MONGO_HOST:${MONGO_PORT:-27017}" -u "$MONGO_USERNAME" -p "$MONGO_PASSWORD" --archive="/backups/backup.archive"
fi
