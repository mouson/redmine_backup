#!/usr/bin/env bash

BACKUP_PATH="/home/backup/redmine"

cd ${BACKUP_PATH} || exit 1
for i in *.tgz
do
    tar -xf "$i"
    if [ -f "redmine.tar.gz.sha256sum" ]; then
        SUM=$(sha256sum -c redmine.tar.gz.sha256sum |  awk '{print($2)}')
        if [ "$SUM" == "OK" ]; then
            exit 0
        else
            rm "$i"
            exit 1
        fi
    fi
done
