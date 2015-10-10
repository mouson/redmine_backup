#!/usr/bin/env bash

BACKUP_PATH="/home/backup/redmine"

cd $BACKUP_PATH
for i in `ls`; do
    tar -xf $i
done

for i in `ls *.sha256sum`; do
    if [ `sha265sum -c $i |  awk '{print($2)}'` == "FAILED"]; then
        rm $i
        rm redmine.tar*
    fi
done

exit 0