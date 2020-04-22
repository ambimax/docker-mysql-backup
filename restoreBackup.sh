#!/bin/sh

set -e

PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/mysql/bin
DATE=`date +%Y-%m-%d_%Hh%Mm`	# Datestamp e.g 2002-09-21

copy_from_s3 () {
  SRC_FILE=$1
  DEST_FILE=$2

  if [ -z "$S3_BUCKET" ]; then
	echo "No parameters for uploading set..."
	return 0
  fi

  export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
  export AWS_DEFAULT_REGION=$S3_REGION

  aws s3 cp ${S3_BUCKET}${1##*/} $2

  if [ $? != 0 ]; then
    >&2 echo "Error downloading ${SRC_FILE} from S3"
  fi
}


MYSQL_HOST_OPTS="-h $MYSQL_HOST -P $MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASSWORD"

SRC_FILE="${MYSQL_DATABASE}.sql.gz"
DEST_FILE="/tmp/${SRC_FILE}"
copy_s3 ${SRC_FILE} ${DEST_FILE}

gunzip < ${DEST_FILE} | mysql ${MYSQL_HOST_OPTS}



