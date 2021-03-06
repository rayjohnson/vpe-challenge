# You can set REGISTRY to build images for a private docker registery - e.g. docker.yp.com/
# leave blank for hub.docker.com/
REGISTRY=
# Version is defined in the VERSION file.  Once you put into Jenkins CI have the version
# come from get describe.
# VERSION ?= $(shell git describe --tags --always --dirty --match=v* 2> /dev/null)
VERSION ?= $(shell cat $(CURDIR)/VERSION 2> /dev/null)

IMAGE_PATH=$(REGISTRY)rayjohnson/wp
IMAGE=$(IMAGE_PATH):$(VERSION)

.build: $(shell find app bin config db lib public config.ru Gemfile.lock Dockerfile -type f)
	docker build -t $(IMAGE) .
	@docker inspect -f '{{.Id}}' $(IMAGE) > .build

Gemfile.lock: Gemfile
	docker run --rm -v "${PWD}":/wp_app -w /wp_app ruby:2.4.1 bundle update

.PHONY: build
build: .build  ## Build our docker image

.PHONY: run
run: .build  ## Run container in detached mode
	docker run --rm -d --name ray-vpe --env-file prod.env -p 8080:8080 $(IMAGE)

.PHONY: shell
shell: .build  ## Run container interactively - with mounted source
	docker run --rm -it -v "${PWD}":/wp_app -e RAILS_ENV=test --env-file prod.env -p 8080:8080 $(IMAGE) bash

.PHONY: help
help:   ## Display this help message
	@grep -E '^[ a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

.PHONY: version
version:
	@echo $(VERSION)

