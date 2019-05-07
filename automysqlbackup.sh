#!/bin/sh

set -e

PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/mysql/bin
DATE=`date +%Y-%m-%d_%Hh%Mm`	# Datestamp e.g 2002-09-21
LOGFILE=/dev/stdout				# Logfile Name
LOGERR=/dev/stderr				# Logfile Name

# IO redirection for logging.
exec 6>&1           # Link file descriptor #6 with stdout.
                    # Saves stdout.
exec > $LOGFILE     # stdout replaced with file $LOGFILE.
exec 7>&2           # Link file descriptor #7 with stderr.
                    # Saves stderr.
exec 2> $LOGERR     # stderr replaced with file $LOGERR.

copy_s3 () {
  SRC_FILE=$1
  DEST_FILE=$2

  if [ -z "$S3_BUCKET" ]; then
	echo "No parameters for uploading set..."
	return 0
  fi

  export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
  export AWS_DEFAULT_REGION=$S3_REGION

  aws s3 cp $1 ${S3_BUCKET}${1##*/}

  if [ $? != 0 ]; then
    >&2 echo "Error uploading ${DEST_FILE} on S3"
  fi

  rm $SRC_FILE
}


MYSQL_HOST_OPTS="-h $MYSQL_HOST -P $MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASSWORD"

if [ -z "${MYSQLDUMP_DATABASE}" ]; then
	DATABASES=`mysql $MYSQL_HOST_OPTS -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql|sys|innodb)"`
else
	DATABASES=$MYSQLDUMP_DATABASE
fi

for DB in $DATABASES; do
	echo "Creating individual dump of ${DB} from ${MYSQL_HOST}..."

	DUMP_FILE="/tmp/${DB}.sql.gz"

	mysqldump $MYSQL_HOST_OPTS $MYSQLDUMP_OPTIONS --databases $DB | gzip > $DUMP_FILE

	if [ $? != 0 ]; then
		>&2 echo "Error creating dump of ${DB}"
	fi

	copy_s3 $DUMP_FILE $S3_FILE
done

#Clean up IO redirection
exec 1>&6 6>&-      # Restore stdout and close file descriptor #6.
exec 1>&7 7>&-      # Restore stdout and close file descriptor #7.