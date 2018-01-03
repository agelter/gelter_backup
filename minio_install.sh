#!/usr/bin/env bash

# Install and set up Minio

# We want the script to be robust, so error-out whenever we try to use an
# uninitialized variable, or when a sub-command returns an error.
set -o nounset
set -o errexit
set -o pipefail

# echo progress
set -x

BACKUP_DIR="/minio"
CONFIG_DIR="/etc/minio"
SERVER_IP="localhost"
SERVER_PORT=9000


if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

# Download latest
wget https://dl.minio.io/server/minio/release/linux-amd64/minio
chmod +x minio
mv minio /usr/local/bin

# create user if needed
if ! id minio-user > /dev/null 2>&1; then
    useradd -r minio-user -s /sbin/nologin
fi

chown minio-user:minio-user /usr/local/bin/minio

# configure backup directory
if [ ! -d ${BACKUP_DIR} ]; then
    mkdir ${BACKUP_DIR}
fi
chown minio-user:minio-user ${BACKUP_DIR}

# configure config directory
if [ ! -d ${CONFIG_DIR} ]; then
    mkdir ${CONFIG_DIR}
fi
chown minio-user:minio-user ${CONFIG_DIR}

# Create environment file
echo "MINIO_VOLUMES=\"${BACKUP_DIR}\"" > /etc/default/minio
echo "MINIO_OPTS=\"-C ${CONFIG_DIR} --address ${SERVER_IP}:${SERVER_PORT}\"" >> /etc/default/minio

# Copy SystemD script
cp ./minio.service /etc/systemd/systemd


# Enable and start the server
systemctl daemon-reload
systemctl enable minio

systemctl start minio