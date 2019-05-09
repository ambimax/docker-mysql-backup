#!/bin/sh

set -e

PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/mysql/bin
DATE=`date +%Y-%m-%d_%Hh%Mm`	# Datestamp e.g 2002-09-21

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
	MYSQLDUMP_DATABASE=`mysql $MYSQL_HOST_OPTS -e "SHOW DATABASES;" | grep -Ev "${EXCLUDED_DATABASES}"`
	echo "List of database - $EXCLUDED_DATABASES:"
	echo "$MYSQLDUMP_DATABASE"
fi


for DB in $MYSQLDUMP_DATABASE; do
	echo "Creating individual dump of ${DB} from ${MYSQL_HOST}..."

	DUMP_FILE="/tmp/${DB:-full}.sql.gz"

	mysqldump $MYSQL_HOST_OPTS $MYSQLDUMP_OPTIONS --databases $DB | gzip > $DUMP_FILE

	if [ $? != 0 ]; then
		>&2 echo "Error creating dump of ${DB}"
	fi

	copy_s3 $DUMP_FILE $S3_FILE
done
