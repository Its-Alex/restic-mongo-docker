#!/bin/bash
set -euo pipefail

if [[ $# -ne 0 ]]; then
    for value in "$@"
    do
        if [[ "$value" == "start-backup-now" ]]; then
            /opt/restic/backup.sh
            exit 0
        fi
        if [[ "$value" == "restore" ]]; then
            /opt/restic/restore.sh
            exit 0
        fi
    done

    # If command are passed to docker container execute restic
    restic "$@"
    exit 0
fi

RESTIC_DOCKER_BACKUP_CRON_SCHEDULE=${RESTIC_DOCKER_BACKUP_CRON_SCHEDULE:-"0 * * * *"} # hourly

echo "$RESTIC_DOCKER_BACKUP_CRON_SCHEDULE flock -n /opt/restic/backup.lockfile /opt/restic/backup.sh" > /main.crontab

supercronic /main.crontab
