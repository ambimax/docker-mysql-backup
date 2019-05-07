# Docker MySQL Backup

Container for periodic backups to s3 storage

## Usage

### docker-compose

```
version: '3.5'
services:

  db:
    image: mariadb:10.2
    ports:
      - "3306:3306"
    volumes:
      - db-data:/var/lib/mysql:delegated
      - "${PWD}/database.sql.gz:/docker-entrypoint-initdb.d/database.sql.gz:delegated"
    environment:
      - MYSQL_ROOT_PASSWORD=root
      - MYSQL_DATABASE=test
      - MYSQL_USER=test
      - MYSQL_PASSWORD=strongPassword
    networks:
      - backend

  mysql-backup:
    image: ambimax/mysql-backup:latest
    environment:
      - MYSQL_USER=root
      - MYSQL_PASSWORD=root
#      - MYSQLDUMP_DATABASE=test,backup_test
      - EXCLUDED_DATABASES=performance_schema,information_schema
      - S3_BUCKET=s3://bucket/backup/path/
      - S3_ACCESS_KEY_ID=***********
      - S3_SECRET_ACCESS_KEY=**************
    networks:
      - backend

volumes:
  db-data:

networks:
  backend:

```