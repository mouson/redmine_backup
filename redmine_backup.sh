#!/usr/bin/env bash

DAY=`date +"%Y%m%d"`
HOUR=`date +"%H%M"`
RHOST="1.1.1.1"
SSH_KEY="/home/dssupport/.ssh/id_rsa"
SSH_USR="user"
SSH="ssh -o BatchMode=yes -i ${SSH_KEY}"
SCP="scp -r -i ${SSH_KEY}"
SSH_TEST_FILE="ssh_test.txt"
BACKUP_PATH="/backup/path"
REDMINE_HOME="/var/www/redmine"
REMOTE_BACKUP_PATH="/home/backup/redmine"
REDMINE_DB_NAME="redmine"
REDMINE_DB_USER="user"
REDMINE_DB_PASS="password"
REDMINE_DB_BACKUP="$REDMINE_HOME/redmine_mysql_db.sql"
REDMINE_BACKUP_NAME="redmine.tar.gz"
REDMINE_BACKUP_DIR_NAME_DAY="redmine_"$DAY"_"$HOUR"_day"
REDMINE_BACKUP_DIR_NAME_WEEK="redmine_"$DAY"_"$HOUR"_week"
REDMINE_BACKUP_DIR_NAME_MONTH="redmine_"$DAY"_"$HOUR"_month"
REDMINE_BACKUP_SHASUM_NAME="redmine.tar.gz.sha256sum"
REDMINE_BACKUP_LIVE_DAY=1
REDMINE_BACKUP_LIVE_WEEK=14
REDMINE_BACKUP_LIVE_MONTH=60
MODEL_BKP_DAY="redmine_*_day.tar.gz"
MODEL_BKP_WEEK="redmine_*_week.tar.gz"
MODEL_BKP_MONTH="redmine_*_month.tar.gz"
COUNT = 0

use_message ()
{
	echo "USAGE: $0 [OPTIONS]"
	echo "OPTIONS:"
	echo "d Daily backup"
	echo "w Weekly backup"
	echo "m Monthly backup"
	exit 1
}

mysql_backup ()
{
	echo "Snapshot backuping Redmine's MySQL db into Redmine instance..."
	mysqldump --user=$REDMINE_DB_USER --password=$REDMINE_DB_PASS $REDMINE_DB_NAME > $REDMINE_DB_BACKUP
	echo "($REDMINE_DB_BACKUP) done."
	echo
}

backup ()
{
	TYPE = $1
    echo "Daily backuping Redmine's directory before sending it to a remote place..."
	mkdir -p $BACKUP_PATH/$REDMINE_BACKUP_DIR_NAME_${TYPE}
    cd $BACKUP_PATH/$REDMINE_BACKUP_DIR_NAME_${TYPE}
	tar -czf $REDMINE_BACKUP_NAME $REDMINE_HOME
	tar -ztf $REDMINE_BACKUP_NAME
	sha256sum $REDMINE_BACKUP_NAME > $REDMINE_BACKUP_SHASUM_NAME
	tar -czvf ../$REDMINE_BACKUP_DIR_NAME_${TYPE}.tar.gz redmine*
    cd $BACKUP_PATH
	$SCP $REDMINE_BACKUP_DIR_NAME_${TYPE}.tar.gz $SSH_USR@$RHOST:/$REMOTE_BACKUP_PATH
    $SCP current_sum.sh $SSH_USR@$RHOST:/$REMOTE_BACKUP_PATH
	CMD = sh $REMOTE_BACKUP_PATH/current_sum.sh
    $SSH $SSH_USR@$RHOST $CMD
	if [ $? -eq 0 ]; then
        CMD = rm $REMOTE_BACKUP_PATH/current_sum.sh
        $SSH $SSH_USR@$RHOST $CMD
        rm -rf $REDMINE_BACKUP_DIR_NAME_${TYPE}
        echo "Check current archive chechsum done"
	else
        echo "Check current archive chechsum filed"
		while [ $COUNT -ne 3 ]; do
			CMD = rm $REMOTE_BACKUP_PATH/$REDMINE_BACKUP_DIR_NAME_${TYPE}.tar.gz
			$SSH $SSH_USR@$RHOST $CMD
			rm -rf $REDMINE_BACKUP_DIR_NAME_${TYPE}
			COUNT = `expr $COUNT + 1`
			backup
		done
    echo "($REDMINE_BACKUP_NAME_DAY) done."
}

remove_old ()
{
	TYPE = $1
	$SSH $SSH_USR@$RHOST "find $REMOTE_BACKUP_PATH/$MODEL_BKP_${TYPE} -mtime +$REDMINE_BACKUP_LIVE_${TYPE} -exec rm {} \;"
}

check_ssh ()
{
	$SSH $SSH_USR@$RHOST "touch $SSH_TEST_FILE && rm -f $SSH_TEST_FILE"
	if [[ $? != 0 ]]; then
		echo " Can not access to remote server !"
		echo " Check: hostname, remore user, ssh-keys, directory permissions !"
	exit 1
fi

}

check_remote_sums ()
{
    $SCP checksum.sh $SSH_USR@$RHOST:/$REMOTE_BACKUP_PATH   
	CMD = sh $REMOTE_BACKUP_PATH/checksum.sh
	$SSH $SSH_USR@$RHOST $CMD
    if [ $? -eq 0 ]; then
        CMD = rm $REMOTE_BACKUP_PATH/checksum.sh
        $SSH $SSH_USR@$RHOST $CMD
        echo "Check remote sums done"
    else
        echo "Check remote sums failed."
}

if [ $# -ne 1 ]; then
	use_message
else
	if [ $1 == d ]; then
		TYPE = DAY
	elif [ $1 == w ]; then
		TYPE = WEEK
	elif [ $1 == m ]; then
		TYPE = MONTH
	fi
	check_ssh
	remove_old $TYPE
	check_remote_sums
	mysql_backup
	backup $TYPE
fi

exit 0