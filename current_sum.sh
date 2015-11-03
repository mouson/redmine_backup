#!/usr/bin/env bash

DAY=$(date +"%Y%m%d")
BACKUP_PATH="/home/backup/redmine"

cd ${BACKUP_PATH} && find . -name "redmine_${DAY}_*_day.tgz" -exec tar -xf {} \; 
SUM=$(sha256sum -c redmine.tar.gz.sha256sum | awk '{print($2)}')
if [ "$SUM" == "OK" ]; then
    exit 0
else
    exit 1
fi
