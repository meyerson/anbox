# Builds the dependencies packaged as a docker image. Assumes docker is
# installed. If not, go to: https://www.docker.com/products/overview

#                         #
# * * * environment * * * #
#                         #

DOCKER  := $(shell command -v docker 2> /dev/null)
VERSION := $(shell git rev-parse HEAD | tr -d '\n'; git diff-index -w --quiet HEAD -- || echo "")

DOCKER_REGISTRY   := registry.hub.docker.com
DOCKER_REPO       := dmeyerson
DOCKER_NAME       := anbox
WORKER_NAME		  := anbox_worker

DOCKER_BASE_HASH   := $(DOCKER_REGISTRY)/$(DOCKER_REPO)/$(DOCKER_NAME):$(VERSION)
DOCKER_BASE_LATEST := $(DOCKER_REGISTRY)/$(DOCKER_REPO)/$(DOCKER_NAME):latest

DOCKER_WORK_HASH   := $(DOCKER_REGISTRY)/$(DOCKER_REPO)/$(WORKER_NAME):$(VERSION)
DOCKER_WORK_LATEST := $(DOCKER_REGISTRY)/$(DOCKER_REPO)/$(WORKER_NAME):latest


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
	@echo '  make push_docker     - push the built image with git commit hash tag and "latest" to docker repo'
	@echo '  make stop     - stop and remove the local running app container'
	@echo '  make test     - run python tests'
	@echo

#                     #
# * * * targets * * * #
#                     #

# white space changes will trigger partial rebuilds
.PHONY: build_base
build_base: deps envvars
	docker build \
		-t $(DOCKER_BASE_HASH) \
		-t $(DOCKER_BASE_LATEST) \
		-f Dockerfile .

.PHONY: build_worker
build_worker: deps envvars build_base
	docker build \
		-t $(DOCKER_WORK_HASH) \
		-t $(DOCKER_WORK_LATEST) \
		-f Dockerfile_worker .

.PHONY: push_docker
push_docker:
	until docker push $(DOCKER_WORK_LATEST); do docker login $(DOCKER_REGISTRY); done
	until docker push $(DOCKER_BASE_LATEST); do docker login $(DOCKER_REGISTRY); done


.PHONY: prep_host
prep_host: 
	pacaur -Sy aur/anbox-modules-dkms-git
	sudo modprobe ashmem_linux
	sudo modprobe binder_linux
	# TODO - grab android img as needed

.PHONY: run
run: deps envvars stop build_worker
	docker run -it \
		--net=host \
		--env="DISPLAY" \
		--volume=$(HOME)/.Xauthority:/root/.Xauthority:rw  \
		-v /mnt/store/android_images:/var/lib/anbox/ \
		--privileged  \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		$(DOCKER_WORK_LATEST) \
		/bin/bash  # really hacky :(

.PHONY: shell
shell: deps envvars stop build_worker
	docker run -it \
		--net=host \
		--env="DISPLAY" \
		--volume=$(HOME)/.Xauthority:/root/.Xauthority:rw  \
		-v /mnt/store/android_images:/var/lib/anbox/ \
		--privileged  \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		$(DOCKER_WORK_LATEST) \
		/bin/bash


.PHONY: viz_confirm
viz_confirm: deps envvars stop
	docker run -it \
		--net=host \
		--env="DISPLAY" \
		--volume=$(HOME)/.Xauthority:/root/.Xauthority:rw  \
		--privileged  \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		$(DOCKER_WORK_LATEST) \
		xeyes

.PHONY: test
test: build stop
	docker run -it $(DOCKER_TAG_HASH) pytest --disable-warnings -vv --pyargs src

.PHONY: stop
stop: deps envvars
	docker stop $(DOCKER_NAME) 2> /dev/null || true
	docker rm   $(DOCKER_NAME) 2> /dev/null || true