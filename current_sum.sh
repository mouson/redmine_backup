#!/usr/bin/env bash

DAY=`date +"%Y%m%d"`
BACKUP_PATH="/home/backup/redmine"

cd $BACKUP_PATH && tar -xf redmine_${DAY}_*_day.tar.gz
CMD = `sha265sum -c ls *.sha256sum |  awk '{print($2)}'`
if [ $CMD == "FAILED"]; then
    rm redmine.tar*
    exit 1
else
    exit 0