# Configuration of Restic and Minio services

## Config Files

Use config.env.template as a starting point for creating config files.

1. Copy it to a file called \<backup-name\>.env
2. Edit it to supply the needed values.

Each *.env file found in the root directory will be used to create a systemd job
that will run the backup as specified.

## Restic Installation Script

Whenever you make edits to any of the files in this repository, run
  
    sudo restic_install.sh
    
to copy files to the needed locations and to reload systemd.

## Minio Installation Script

To get the latest version of Minio and install it as a service, run

    sudo minio_install.sh
