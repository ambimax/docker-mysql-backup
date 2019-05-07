NAME	= ambimax/mysql-backup
TAG		= $(shell git rev-parse --short HEAD)
IMG		= ${NAME}:${TAG}
LATEST	= ${NAME}:latest


build: build-image tag-latest

build-image:
	@docker build --pull --cache-from "${NAME}" -t "${IMG}" .

tag-latest:
	docker tag ${IMG} ${LATEST}

start:
	(cd tests && docker-compose up)

stop:
	(cd tests && docker-compose down -v)

push:
	@docker push ${NAME}

login:
	echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
