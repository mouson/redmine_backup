Redmine BackUp Srcipt
===
modify from https://github.com/KsenZ/redmine_backup

# Usage

1) git clone git@github.com:mouson/redmine_backup.git
2) Copy conf.sh.sample to conf.sh

~~~sh
cp conf.sh.sample conf.sh
~~~

3) modify config file "conf.sh"
4) testing

~~~sh
cd redmine_backup
./redmine_backup.sh
./redmine_backup.sh d
~~~

5) add cron job

~~~sh
5 3 * * * /home/backup/redmine_backup/redmine_backup.cron > /dev/null 2>&1
~~~

