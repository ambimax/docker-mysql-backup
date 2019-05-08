# Build
FROM golang:1.9 as builder

RUN go get -d -v github.com/odise/go-cron
WORKDIR /go/src/github.com/odise/go-cron
RUN CGO_ENABLED=0 GOOS=linux go build -o go-cron bin/go-cron.go


# Container
FROM alpine:latest

LABEL maintainer="Tobias Schifftner <ts@ambimax.de>"

RUN apk update; apk add \
	mysql-client \
	python \
	py-pip \
	curl \
	&&  pip install awscli \
	&& apk del py-pip \
	&& rm -rf /var/cache/apk/* \
	&& mkdir -p /var/backup

COPY --from=builder /go/src/github.com/odise/go-cron/go-cron /usr/local/bin

ENV MYSQLDUMP_OPTIONS --quote-names --quick --add-drop-table --add-locks --allow-keywords --disable-keys --extended-insert --single-transaction --create-options --comments --net_buffer_length=16384
ENV MYSQLDUMP_DATABASE --all-databases
ENV MYSQL_HOST db
ENV MYSQL_PORT 3306
ENV MYSQL_USER root
ENV MYSQL_PASSWORD root

ENV S3_ACCESS_KEY_ID ""
ENV S3_SECRET_ACCESS_KEY ""
ENV S3_BUCKET ""
ENV S3_REGION eu-central-1

ENV MYSQLDUMP_DATABASE ""
ENV EXCLUDED_DATABASES information_schema
ENV COMPRESSION gzip
ENV BACKUPDIR /var/backup

ENV CRON_SCHEDULE ""

COPY automysqlbackup.sh /usr/local/bin/automysqlbackup
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/go-cron \
	/usr/local/bin/entrypoint.sh \
	/usr/local/bin/automysqlbackup

CMD ["sh", "/usr/local/bin/entrypoint.sh"]
