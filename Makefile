# Builds the dependencies packaged as a docker image. Assumes docker is
# installed. If not, go to: https://www.docker.com/products/overview

#                         #
# * * * environment * * * #
#                         #

DOCKER  := $(shell command -v docker 2> /dev/null)
VERSION := $(shell git rev-parse HEAD | tr -d '\n'; git diff-index -w --quiet HEAD -- || echo "")

DOCKER_REGISTRY   := dockerhub
DOCKER_REPO       := dmeyerson
DOCKER_NAME       := anbox
TAG		  		  := base_anbox
DOCKER_TAG_HASH   := $(DOCKER_REGISTRY)/$(DOCKER_REPO)/$(DOCKER_NAME):$(VERSION)
DOCKER_TAG_LATEST := $(DOCKER_REGISTRY)/$(DOCKER_REPO)/$(DOCKER_NAME):latest
DOCKER_TAG  	  := $(DOCKER_REGISTRY)/$(DOCKER_REPO)/$(DOCKER_NAME):$(TAG)

ANDROID_IMAGED_DIR := /mnt/store/android_images
USER_NAME := scraper
AWS_PROFILE := default
# TODO: respect pre-existing env vars

.PHONY: deps
deps:
ifndef DOCKER
	$(error 'docker' binary is not found; please install Docker, as the app is containerized for portability)
endif

.PHONY: envvars
envvars:
ifndef DOCKER_NAME
	$(error 'DOCKER_NAME' environment variable is undefined)
endif
ifndef DOCKER_REGISTRY
	$(error 'DOCKER_REGISTRY' environment variable is undefined)
endif
ifndef DOCKER_REPO
	$(error 'DOCKER_REPO' environment variable is undefined)
endif
ifndef VERSION
	$(error 'VERSION' environment variable is undefined)
endif

#                  #
# * * * help * * * #
#                  #

.PHONY: help
help:
	@echo
	@echo '  make build    - build the docker image tagged with the latest commit hash and "latest"'
	@echo '  make notebook - start jupyter notebook server'
	@echo '  make docs     - generate documentation in the container locally'
	@echo '  make shell    - open a shell in the container locally'
	@echo '  make push     - push the built image with git commit hash tag and "latest" to docker repo'
	@echo '  make stop     - stop and remove the local running app container'
	@echo '  make test     - run python tests'
	@echo

#                     #
# * * * targets * * * #
#                     #

.PHONY: build
build: deps envvars
	docker build \
		-t $(DOCKER_TAG_HASH) \
		-t $(DOCKER_TAG_LATEST) \
		-t $(DOCKER_TAG) \
		-f Dockerfile .

.PHONY: push
push: push_git push_latest

.PHONY: push_git
push_git: build
	until docker push $(DOCKER_TAG_HASH); do docker login $(DOCKER_REGISTRY); done

.PHONY: push_latest
push_latest: build
	until docker push $(DOCKER_TAG_LATEST); do docker login $(DOCKER_REGISTRY); done

.PHONY: shell
shell: deps envvars stop build
	docker run \
		-it $(DOCKER_TAG_LATEST) \
		--net=host --env="DISPLAY" \
		--volume="$HOME/.Xauthority:/root/.Xauthority:rw"  \
		-v $(ANDROID_IMAGE_DIR):/var/lib/anbox/ \
		--privileged \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		/bin/bash

.PHONY: test
test: build stop
	docker run -it $(DOCKER_TAG_HASH) pytest --disable-warnings -vv --pyargs src

.PHONY: stop
stop: deps envvars
	docker stop $(DOCKER_NAME) 2> /dev/null || true
	docker rm   $(DOCKER_NAME) 2> /dev/null || true