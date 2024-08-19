ARG DEBIAN_VERSION=12.6-slim

FROM debian:$DEBIAN_VERSION AS BASE

ARG RESTIC_VERSION=0.16.4
ARG RCLONE_VERSION=1.66.0
ARG SUPERCRONIC_VERSION=0.2.29

ARG MONGO_TOOLS_VERSION=100.10.0

RUN apt update && \
    apt install --no-install-recommends --no-install-suggests -y \
        zip curl ca-certificates wget bzip2 unzip \
    # Install restic
    && wget -O "/tmp/restic.bz2" https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic_${RESTIC_VERSION}_linux_amd64.bz2 \
        && bzip2 -d "/tmp/restic.bz2" \
    # Install rclone
    && wget -O "/tmp/rclone.zip" https://github.com/rclone/rclone/releases/download/v${RCLONE_VERSION}/rclone-v${RCLONE_VERSION}-linux-amd64.zip \
        && unzip -d "/tmp/" "/tmp/rclone.zip" \
        && mv "/tmp/rclone-v$RCLONE_VERSION-linux-amd64" "/tmp/rclone" \
    # Install supercronic
    && curl -fsSLO "https://github.com/aptible/supercronic/releases/download/v${SUPERCRONIC_VERSION}/supercronic-linux-amd64" \
        && mv "supercronic-linux-amd64" "/tmp/supercronic" \
    # Install pg_pack
    && wget -O "/tmp/mongo_tools.tar.gz" https://fastdl.mongodb.org/tools/db/mongodb-database-tools-debian12-x86_64-${MONGO_TOOLS_VERSION}.tgz \
        && tar xfz "/tmp/mongo_tools.tar.gz" -C /tmp/ \
        && mv /tmp/mongodb-database-tools-debian12-x86_64-${MONGO_TOOLS_VERSION} /tmp/mongodb-database-tools

FROM --platform=$BUILDPLATFORM debian:$DEBIAN_VERSION

RUN apt update && \
    apt install --no-install-recommends --no-install-suggests -y \
        bash \
        libc6 libgssapi-krb5-2 libkrb5-3 libk5crypto3 libcomerr2 libkrb5support0 libkeyutils1 # mongodb-database-tools-dependencies

COPY --from=BASE --chmod=0755 /tmp/restic /usr/local/bin/restic
COPY --from=BASE --chmod=0755 /tmp/rclone/rclone /usr/local/bin/rclone
COPY --from=BASE --chmod=0755 /tmp/supercronic /usr/local/bin/supercronic
COPY --from=BASE --chmod=0755 /tmp/mongodb-database-tools/bin/bsondump /usr/local/bin/bsondump
COPY --from=BASE --chmod=0755 /tmp/mongodb-database-tools/bin/mongodump /usr/local/bin/mongodump
COPY --from=BASE --chmod=0755 /tmp/mongodb-database-tools/bin/mongoexport /usr/local/bin/mongoexport
COPY --from=BASE --chmod=0755 /tmp/mongodb-database-tools/bin/mongofiles /usr/local/bin/mongofiles
COPY --from=BASE --chmod=0755 /tmp/mongodb-database-tools/bin/mongoimport /usr/local/bin/mongoimport
COPY --from=BASE --chmod=0755 /tmp/mongodb-database-tools/bin/mongorestore /usr/local/bin/mongorestore
COPY --from=BASE --chmod=0755 /tmp/mongodb-database-tools/bin/mongostat /usr/local/bin/mongostat
COPY --from=BASE --chmod=0755 /tmp/mongodb-database-tools/bin/mongotop /usr/local/bin/mongotop

COPY --chmod=0755 ./backup.sh /opt/restic/backup.sh
COPY --chmod=0755 ./entrypoint.sh /opt/restic/entrypoint.sh

ENV RESTIC_PASSWORD=""
ENV RESTIC_TAG=""

ENV RESTIC_DOCKER_BACKUP_CRON_SCHEDULE="0 * * * *"

ENV MONGO_AUTH_DISABLED=0
ENV MONGO_HOST=
ENV MONGO_PORT=
ENV MONGO_USERNAME=
ENV MONGO_PASSWORD=

ENTRYPOINT [ "/opt/restic/entrypoint.sh" ]