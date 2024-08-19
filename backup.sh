#!/bin/bash
set -euo pipefail

MONGO_USERNAME=${MONGO_USERNAME:=""}
MONGO_PASSWORD=${MONGO_PASSWORD:=""}

start=$(date +%s)
echo "Starting mongodump at $(date +"%Y-%m-%d %H:%M:%S")"
mkdir -p /backups/
if [[ "$MONGO_AUTH_DISABLED" == "1" || "$MONGO_AUTH_DISABLED" == "true" ]]; then
    mongodump --host="$MONGO_HOST:${MONGO_PORT:-27017}" --archive="/backups/backup.archive"
else
    mongodump --host="$MONGO_HOST:${MONGO_PORT:-27017}" -u "$MONGO_USERNAME" -p "$MONGO_PASSWORD" --archive="/backups/backup.archive"
fi

end=$(date +%s)
echo "Finished mongodump at $(date +"%Y-%m-%d %H:%M:%S") after $((end-start)) seconds"

if ! restic unlock; then
    echo "Init restic repository..."
    restic init
fi

echo "Perform backup..."
retry_count=0
max_retries=5
# As a result of network problems or other types of issues that I can't remember,
# a loop is implemented here to make 5 backup attempts before returning an error.
while ! restic backup "/backups/"; do
    retry_count=$((retry_count + 1))
    if [ $retry_count -ge $max_retries ]; then
        echo "Reached maximum retry limit of $max_retries. Exiting."
        exit 1
    fi
    echo "Sleeping for 10 seconds before retry..."
    sleep 10
done

# Delete dump file after upload by restic
rm -rf /backups/*

RESTIC_DOCKER_IS_FORGET_DISABLED=${RESTIC_DOCKER_IS_FORGET_DISABLED:-""}

if [[ ! ( $RESTIC_DOCKER_IS_FORGET_DISABLED == "1" || $RESTIC_DOCKER_IS_FORGET_DISABLED == "true" ) ]]; then
    echo "Forgetting old snapshots"
    retry_count=0
    max_retries=5
    while ! restic forget \
                    --compact \
                    --prune \
                    --keep-hourly="${RESTIC_KEEP_HOURLY:-24}" \
                    --keep-daily="${RESTIC_KEEP_DAILY:-7}" \
                    --keep-weekly="${RESTIC_KEEP_WEEKLY:-4}" \
                    --keep-monthly="${RESTIC_KEEP_MONTHLY:-12}"; do
        retry_count=$((retry_count + 1))
        if [ $retry_count -ge $max_retries ]; then
            echo "Reached maximum retry limit of $max_retries. Exiting."
            exit 1
        fi
        echo "Sleeping for 10 seconds before retry..."
        sleep 10
    done
fi

echo "Check repository"
restic check --no-lock

# Remove unwanted cache
rm -rf /tmp/restic-check-cache-*

echo 'Finished forget with prune successfully'
