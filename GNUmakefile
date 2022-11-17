# This makefile is provided to simplify building multiplatform images since
#  the command can get quite complex
# Usage:
# $ make        - Build for the current platform (only supports amd64, armv7 and arm64 on linux)
# $ make buildx - Build multiplatform images
# $ make push   - Push multiplatform images to the registry

LABEL=outlyernet/losslesscut
TAG:=latest

# Platform using docker naming scheme: amd64, arm/v7, arm64 (with "linux/" as prefix)
#  derived from the uname
# See https://hub.docker.com/r/jlesage/baseimage-gui/tags
platform:=$(shell test `uname -m` = 'x86_64' && echo 'amd64' ; \
	 test `uname -m` = 'aarch64' && echo 'arm64' ; \
	 test `uname -m` = 'armv7l' && echo 'arm/v7' ; \
	 )

APP_VERSION:=$(shell grep '^ARG app_version=' Dockerfile | awk '{print $$2}' | cut -d= -f2)
IMAGE_REVISION:=$(shell grep '^ARG image_revision=' Dockerfile | awk '{print $$2}' | cut -d= -f2)

REV_SUFFIX:=-v$(IMAGE_REVISION)

MAJOR:=$(shell echo $(APP_VERSION) | cut -d. -f1)
MAJOR_MINOR:=$(shell echo $(APP_VERSION) | cut -d. -f1-2)

# Simple build on the given architecture
# Tagged with :latest, LosslessCut's version and optionally LosslessCut's version + image revision
# Don't add the docker image version unless it's bigger than 1
build:
	docker build -t $(LABEL):$(TAG) \
		-t $(LABEL):$(APP_VERSION) \
		-t $(LABEL):$(MAJOR_MINOR) \
		-t $(LABEL):$(MAJOR) \
		$(shell test $(IMAGE_REVISION) -le 1 || echo -t $(LABEL):$(APP_VERSION)$(REV_SUFFIX)) \
		$(shell test $(IMAGE_REVISION) -le 1 || echo -t $(LABEL):$(MAJOR_MINOR)$(REV_SUFFIX)) \
		$(shell test $(IMAGE_REVISION) -le 1 || echo -t $(LABEL):$(MAJOR)$(REV_SUFFIX)) \
		--build-arg=TARGETPLATFORM=linux/$(platform) .

# Common buildx command template, build---something will pass --something to the command
buildx-%:
	docker buildx build \
		$* \
		-t $(LABEL):$(TAG) \
		-t $(LABEL):$(APP_VERSION) \
		-t $(LABEL):$(MAJOR_MINOR) \
		-t $(LABEL):$(MAJOR) \
		$(shell test $(IMAGE_REVISION) -le 1 || echo -t $(LABEL):$(APP_VERSION)$(REV_SUFFIX)) \
		$(shell test $(IMAGE_REVISION) -le 1 || echo -t $(LABEL):$(MAJOR_MINOR)$(REV_SUFFIX)) \
		$(shell test $(IMAGE_REVISION) -le 1 || echo -t $(LABEL):$(MAJOR)$(REV_SUFFIX)) \
		--platform=linux/amd64,linux/arm/v7,linux/arm64 .

# NOTE: The "buildx-\ " dependency is a way of passing no extra arguments to buildx-%
buildx: buildx-\ 

push: buildx---push

# Importing/exporting multiplatform images doesn't work (yet?)
#load: buildx---load
