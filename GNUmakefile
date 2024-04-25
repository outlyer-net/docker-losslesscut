# This makefile is provided to simplify building multiplatform images since
#  the command can get quite complex
# Usage:
# $ make        - Build for the current platform (only supports amd64, armv7 and arm64 on linux)
# $ make buildx - Build multiplatform images
# $ make push   - Push multiplatform images to the registry

IMAGE_NAME=outlyernet/losslesscut
TAG:=latest
REGISTRY:=docker.io
# Additional tags (passed verbatim to docker build), separated by spaces
ADD_TAGS:=

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

LABEL=$(REGISTRY)/$(IMAGE_NAME)

ALL_TAGS=$(LABEL):$(TAG) \
	        $(LABEL):$(APP_VERSION) \
	        $(LABEL):$(MAJOR_MINOR) \
	        $(LABEL):$(MAJOR) \
	        $(LABEL):$(APP_VERSION)$(REV_SUFFIX) \
	        $(LABEL):$(MAJOR_MINOR)$(REV_SUFFIX) \
	        $(LABEL):$(MAJOR)$(REV_SUFFIX) \
			$(ADD_TAGS)
# prepend -t to each tag
ALL_TAGS_PARAM=$(foreach tag,$(ALL_TAGS),-t $(tag))

# Simple build on the given architecture
# Tagged with :latest, LosslessCut's version and LosslessCut's version + image revision
build:
	docker build \
		$(ALL_TAGS_PARAM) \
		--build-arg=TARGETPLATFORM=linux/$(platform) .

# Common buildx command template, build---something will pass --something to the command
buildx-%:
	docker buildx build \
		$(subst noop,,$*) \
		$(ALL_TAGS_PARAM) \
	 	--platform=linux/amd64,linux/arm/v7,linux/arm64 .

# Prints the list of tags to be used by build/push 
print-tags:
	@echo $(ALL_TAGS)

# NOTE: The "buildx-noop" dependency is a way of passing no extra arguments to buildx-%
buildx: buildx-noop

push: buildx---push

# A new builder is required to build multiarch images
multiarch-builder:
	docker buildx create --name multiarch --use

# Importing/exporting multiplatform images doesn't work (yet?)
#load: buildx---load

.PHONY: build buildx push # DO NOT mark as phony buildx-* rules
