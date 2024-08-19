# Docker Image to backup Mongodb database with Restic

You can use this Docker image `itsalex/restic-mongo:latest` sidecar to backup your Mongodb database.

This Docker image is powered by:

- [`mongodb database tools`](https://www.mongodb.com/try/download/database-tools) - Collection of command-line utilities for working with a MongoDB deployment.
- [`restic`](https://github.com/restic/restic/) - Fast, secure, efficient backup program.
- [`Rclone`](https://rclone.org/) - Rclone is a command-line program to manage files on cloud storage.
- [`supercronic`](https://github.com/aptible/supercronic) - Cron for containers.

If you are looking for a Restic based Docker image to backup your files, you can check out the following project: https://github.com/stephane-klein/restic-pg_dump-docker/


## Getting started

To use this container you can launch it from docker cli:

```sh
$ docker run \
    -e AWS_ACCESS_KEY_ID="admin" \
    -e AWS_SECRET_ACCESS_KEY="password" \
    -e RESTIC_REPOSITORY="s3:http://minio:9000/bucket1" \
    -e RESTIC_PASSWORD="secret" \
    -e RESTIC_HOST=db-test \
    -e MONGO_USERNAME="mongo" \
    -e MONGO_PASSWORD="password" \
    -e MONGO_HOST="mongo" \
    -e MONGO_DATABASES="mongo" \
    itsalex/restic-mongo:latest
```

Or add it to a `docker-compose.yml`:

```yaml
restic-pg-dump:
  image: itsalex/restic-mongo:latest
  environment:
    AWS_ACCESS_KEY_ID: "admin"
    AWS_SECRET_ACCESS_KEY: "password"
    RESTIC_REPOSITORY: "s3:http://minio:9000/bucket1"
    RESTIC_PASSWORD: secret
    RESTIC_HOST: db-test
    MONGO_USERNAME: mongo
    MONGO_PASSWORD: password
    MONGO_HOST: mongo
    MONGO_DATABASES: mongo
```

## Configuration

- Configure the mongodump command to backup with this variable environments:
  - `MONGO_USERNAME`;
  - `MONGO_PASSWORD`;
  - `MONGO_HOST`;
  - `MONGO_PORT` (default: `27017`).
- `RESTIC_PASSWORD` to [encrypte your backup](https://restic.readthedocs.io/en/latest/faq.html#how-can-i-specify-encryption-passwords-automatically) (empty by default, i.e. no encrypted).
- `RESTIC_DOCKER_BACKUP_CRON_SCHEDULE` (default `0 * * * *` hourly).
- `RESTIC_DOCKER_SNAPSHOT_ID` (default to `latest`)
- Configure [`restic forget`](https://restic.readthedocs.io/en/latest/060_forget.html#) (which allows removing old snapshots) with this variable environments:
  - `RESTIC_KEEP_HOURLY` (default: `24`);
  - `RESTIC_KEEP_DAILY` (default: `7`);
  - `RESTIC_KEEP_WEEKLY`  (default: `4`);
  - `RESTIC_KEEP_MONTHLY` (default: `12`).
  - Set `RESTIC_DOCKER_IS_FORGET_DISABLED=1` to disable [`restic forget`](https://restic.readthedocs.io/en/latest/060_forget.html).

You can configure many target storage. For instance:

- Store your backup to S3 like Object Storage:
  - `AWS_ACCESS_KEY_ID`;
  - `AWS_SECRET_ACCESS_KEY`;
  - `RESTIC_REPOSITORY` : `s3:http://minio:9000/bucket1`.
- Store your backup to ftp:
  - `RESTIC_REPOSITORY`: `rclone:ftpd_server:backup`.

More options, see [Restic environment variables documentation](https://restic.readthedocs.io/en/stable/040_backup.html#environment-variables).

## License

Restic mongo docker is licensed under [BSD 2-Clause License](https://opensource.org/licenses/BSD-2-Clause). You can find the
complete text in [`LICENSE`](LICENSE).