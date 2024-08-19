# How to use itsalex/restic-mongo image

## Backup

First you should launch the demo stack:

```sh
$ docker compose up -d
```

This will launch:

- [restic-mongo](../)
- [mongodb](https://www.mongodb.com/)
- [minio](https://min.io/) (as storage for backup)

Then you should add some fake data in database:

```sh
$ docker compose exec mongo mongosh -u mongo -p password --eval 'db.user.insert({name: "Ada Lovelace", age: 205})'
{
  acknowledged: true,
  insertedIds: { '0': ObjectId('66c33e8dffb8c4b9ed5e739c') }
}
```

Finally perform a backup:

```sh
$ docker compose run --rm restic-mongo-dump start-backup-now
Starting mongodump at 2024-08-19 12:45:23
2024-08-19T12:45:23.964+0000    writing admin.system.users to archive '/backups/backup.archive'
2024-08-19T12:45:23.966+0000    done dumping admin.system.users (1 document)
2024-08-19T12:45:23.967+0000    writing admin.system.version to archive '/backups/backup.archive'
2024-08-19T12:45:23.971+0000    done dumping admin.system.version (2 documents)
2024-08-19T12:45:23.971+0000    writing test.user to archive '/backups/backup.archive'
2024-08-19T12:45:23.973+0000    done dumping test.user (2 documents)
Finished mongodump at 2024-08-19 12:45:23 after 0 seconds
repository 94ce7855 opened (version 2, compression level auto)
created new cache in /root/.cache/restic
Perform backup...
repository 94ce7855 opened (version 2, compression level auto)
no parent snapshot found, will read all files
...
```

As of now you have a backup containing your created user.

## Restore

You should have a backup to do this section, if you have followed the
[Backup](#backup) section you can continue with this one.

You should be sure that mongodb has no data in it:

```sh
$ docker compose down && \
    sudo rm -rf volumes/mongo && \
    docker compose up -d
```

Then perform the restore operation, you can use **RESTIC_DOCKER_SNAPSHOT_ID**
to select snapshot, for this example we will use `latest`:

```sh
$ docker run --rm -it \
    --network restic-mongo-docker \
    -e AWS_ACCESS_KEY_ID="admin" \
    -e AWS_SECRET_ACCESS_KEY="password" \
    -e RESTIC_REPOSITORY="s3:http://minio:9000/bucket1" \
    -e RESTIC_PASSWORD="secret" \
    -e RESTIC_HOST=db-test \
    -e RESTIC_DOCKER_SNAPSHOT_ID=latest \
    -e MONGO_USERNAME="mongo" \
    -e MONGO_PASSWORD="password" \
    -e MONGO_HOST="mongo" \
    -e MONGO_DATABASES="mongo" \
    itsalex/restic-mongo:latest \
    restore
Download snapshot "latest"...
repository 45ac61d0 opened (version 2, compression level auto)
created new cache in /root/.cache/restic

restoring <Snapshot 81c58c6c of [/backups] at 2024-08-19 12:46:13.651678754 +0000 UTC by root@1f35df5f6a31> to /
Summary: Restored 2 files/dirs (2.080 KiB) in 0:00
2024-08-19T12:47:04.372+0000    preparing collections to restore from
2024-08-19T12:47:04.375+0000    reading metadata for test.user from archive '/backups/backup.archive'
2024-08-19T12:47:04.399+0000    restoring test.user from archive '/backups/backup.archive'
2024-08-19T12:47:04.410+0000    finished restoring test.user (1 document, 0 failures)
2024-08-19T12:47:04.410+0000    restoring users from archive '/backups/backup.archive'
2024-08-19T12:47:04.442+0000    no indexes to restore for collection test.user
2024-08-19T12:47:04.442+0000    1 document(s) restored successfully. 0 document(s) failed to restore.
```

Now if you try to list users you will find the one created in previous section:

```sh
$ docker compose exec mongo mongosh -u mongo -p password --eval 'db.user.find()'
```