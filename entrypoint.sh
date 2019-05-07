#!/bin/sh

set -e

# wait until MySQL is really available
maxcounter=45

counter=1
while ! mysql --protocol TCP -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "show databases;" > /dev/null 2>&1; do
    sleep 1
    counter=`expr $counter + 1`
    if [ $counter -gt $maxcounter ]; then
        >&2 echo "We have been waiting for MySQL too long already; failing."
        exit 1
    fi;
done

if [ "${CRON_SCHEDULE}" ]; then
    exec /usr/local/bin/go-cron -s "${CRON_SCHEDULE}" -- /usr/local/bin/automysqlbackup
else
    exec /usr/local/bin/automysqlbackup
fi