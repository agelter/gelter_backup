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
oldtimers=$(systemctl --no-legend list-timers hourly-backup* | \
    awk 'start=index($0,"hourly") { print substr($0, start, index($0,"timer") - start + length("timer")) }')
for timer in $oldtimers; do
    systemctl stop "${timer}"
    systemctl disable "${timer}"
done

# remove the associated services as well
running_jobs=$(systemctl --no-legend list-units run-backup* | \
    awk 'start=index($0,"run") { print substr($0, start, index($0,"service") - start + length("service")) }')
for job in $running_jobs; do
    systemctl stop "${job}"
done

# copy over systemd files
for file in ./systemd/*; do
    sed "s/_USER_/$(logname)/" "$file" > /etc/systemd/system/"${file##*/}"
done

for config_file in *.env; do
    # copy all env files
    cp "${config_file}" /root/bin

    tmp=${config_file%.env}
    service_name=${tmp##*/}
    systemctl start hourly-backup@"${service_name}".timer
    systemctl enable hourly-backup@"${service_name}".timer
    systemctl start hourly-backup-clean@"${service_name}".timer
    systemctl enable hourly-backup-clean@"${service_name}".timer
done

# reload systemd
systemctl daemon-reload
