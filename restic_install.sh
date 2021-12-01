#!/usr/bin/env bash

# Simple script to install files to the correct locations and enable the systemd timers

# We want the script to be robust, so error-out whenever we try to use an
# uninitialized variable, or when a sub-command returns an error.
set -o nounset
set -o errexit
set -o pipefail

# echo progress
set -x

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

if [ ! -d "/root/bin" ]; then
    mkdir /root/bin
fi

# copy base script over first
cp ./call_restic /root/bin

# remove old timers
oldtimers=$(systemctl --no-legend list-timers -- *-backup* | sed -e 's/.*\(\(hourly\|daily\|weekly\|monthly\).*timer\).*/\1/')
for timer in $oldtimers; do
    systemctl stop "${timer}" || true
    systemctl disable "${timer}"
done

# remove the associated services as well
running_jobs=$(systemctl --no-legend list-units run-backup* | sed -e 's/.*\(run.*service\).*/\1/')
for job in $running_jobs; do
    systemctl stop "${job}" || true
done

# copy over systemd files
for file in ./systemd/*; do
    sed "s/_USER_/$(whoami)/" "$file" > "/etc/systemd/system/${file##*/}"
done

for config_file in *.env; do
    # copy all env files
    cp "${config_file}" /root/bin

    # Unlock restic in case it was in the middle of something
    /root/bin/call_restic "${config_file}" unlock

    service_name=$(basename "${config_file}" .env)

    for timer_name in ./systemd/*.timer; do
        timer_prefix=$(basename "${timer_name}" @.timer)
        systemctl start "${timer_prefix}"@"${service_name}".timer
        systemctl enable "${timer_prefix}"@"${service_name}".timer
    done
done

# reload systemd
systemctl daemon-reload
