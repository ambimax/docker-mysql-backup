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
      - EXCLUDED_DATABASES=(sample|Database|information_schema|performance_schema|mysql|sys|innodb)
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

## Settings

### Access Credentials

```
# root user
MYSQL_USER=root
MYSQL_PASSWORD=root

# normal user
MYSQL_USER=username
MYSQL_PASSWORD=strongPassword
```

### Backup all databases

```
MYSQLDUMP_DATABASE=--all-databases
```

### Backup specific databases

Define databases in environment variable

```
# One database:
MYSQLDUMP_DATABASE=test

# Multiple databases:
MYSQLDUMP_DATABASE=test,backup_test
```

### Exclude (not yet implemented)

Exclude databases from backup

```
EXCLUDED_DATABASES=(Database|information_schema|performance_schema|mysql|sys|innodb)
```

_When not specified the variable is set as above_

### S3 Settings

For uploading the following settings are required

```
S3_BUCKET=s3://bucket/backup/path/
S3_ACCESS_KEY_ID=***********
S3_SECRET_ACCESS_KEY=**************
```

### Secrets (docker swarm)

For secret usage all variables can be appended with _FILE and a stored value will be used:

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
    secrets:
      - aws-access-key
      - aws-secred-access-key
    image: ambimax/mysql-backup:latest
    environment:
      - S3_ACCESS_KEY_ID_FILE=/run/secrets/aws-access-key
      - S3_SECRET_ACCESS_KEY_FILE=/run/secrets/aws-secred-access-key
    networks:
      - backend

secrets:
  aws-access-key:
    external: true
  aws-secred-access-key:
    external: true
    
volumes:
  db-data:

networks:
  backend:
    
```