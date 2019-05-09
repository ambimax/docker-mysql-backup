#!/bin/sh

# Mysql settings
if [ ! -z $MYSQL_USER_FILE ]; then
	export MYSQL_USER=$(cat "${MYSQL_USER_FILE}")
fi

if [ ! -z $MYSQL_PASSWORD_FILE ]; then
	export MYSQL_PASSWORD=$(cat "${MYSQL_PASSWORD_FILE}")
fi

if [ ! -z $MYSQL_HOST_FILE ]; then
	export MYSQL_HOST=$(cat "${MYSQL_HOST_FILE}")
fi

if [ ! -z $MYSQL_PORT_FILE ]; then
	export MYSQL_PORT=$(cat "${MYSQL_PORT_FILE}")
fi

# AWS settings
if [ ! -z $S3_BUCKET_FILE ]; then
	export S3_BUCKET=$(cat "${S3_BUCKET_FILE}")
fi

if [ ! -z $S3_ACCESS_KEY_ID_FILE ]; then
	export S3_ACCESS_KEY_ID=$(cat "${S3_ACCESS_KEY_ID_FILE}")
fi

if [ ! -z $S3_SECRET_ACCESS_KEY_FILE ]; then
	export S3_SECRET_ACCESS_KEY=$(cat "${S3_SECRET_ACCESS_KEY_FILE}")
fi

if [ ! -z $S3_REGION_FILE ]; then
	export S3_REGION=$(cat "${S3_REGION_FILE}")
fi

# Backup settings
if [ ! -z $MYSQLDUMP_DATABASE_FILE ]; then
	export MYSQLDUMP_DATABASE=$(cat "${MYSQLDUMP_DATABASE_FILE}")
fi

if [ ! -z $EXCLUDED_DATABASES_FILE ]; then
	export EXCLUDED_DATABASES=$(cat "${EXCLUDED_DATABASES_FILE}")
fi

if [ ! -z $MYSQLDUMP_OPTIONS_FILE ]; then
	export MYSQLDUMP_OPTIONS=$(cat "${MYSQLDUMP_OPTIONS_FILE}")
fi

if [ ! -z $CRON_SCHEDULE_FILE ]; then
	export CRON_SCHEDULE=$(cat "${CRON_SCHEDULE_FILE}")
fi


if [ ! -z $SLEEP_ON_STARTUP ]; then
	echo "sleep $SLEEP_ON_STARTUP"
	sleep $SLEEP_ON_STARTUP
fi

set -e

# wait until MySQL is really available
maxcounter=45

counter=1
while ! mysql --protocol TCP -h $MYSQL_HOST -P $MYSQL_PORT -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "show databases;" > /dev/null 2>&1; do
    sleep 1
    counter=`expr $counter + 1`
    if [ $counter -gt $maxcounter ]; then
        >&2 echo "We have been waiting for MySQL too long already; failing."
        exit 1
    fi;
done

if [ "${CRON_SCHEDULE}" ]; then
    exec /usr/local/bin/go-cron -s "0 ${CRON_SCHEDULE}" -- /usr/local/bin/automysqlbackup
else
    exec /usr/local/bin/automysqlbackup
fi