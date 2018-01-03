# Configuration of Restic and Minio services

## Config files

Use config.env.template as a starting point for creating config files.

1. Copy it to a file called <backup-name>.env
2. Edit it to supply the needed values.

Each *.env file found in the root directory will be used to create a systemd job
that will run the backup as specified.

## Installation script

Whenever you make edits to any of the files in this repository, run
'sudo install.sh' to copy files to the needed locations and to reload systemd.