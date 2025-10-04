DOCKER_REPO ?= docker.windix.au/docker-for-unraid
DOCKER_TAG ?= $(shell date +%Y%m%d)

build:
	docker build -t ${DOCKER_REPO}:${DOCKER_TAG} -t ${DOCKER_REPO}:latest .

push:
	docker push ${DOCKER_REPO}:${DOCKER_TAG}
	docker push ${DOCKER_REPO}:latest

run:
	docker run -it --rm -e SSH_PASSWORD=password -p 2222:22 ${DOCKER_REPO}:${DOCKER_TAG}
