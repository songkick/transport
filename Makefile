.PHONY: test

# get last git commit hash
REVISION=$(shell git rev-parse --verify HEAD)

ifndef VERSION
VERSION=$(REVISION)
endif

ifndef ENVIRONMENT
ENVIRONMENT=development
endif

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

pull_songkick_ruby:
	docker pull eu.gcr.io/soundbadger-management/songkick-ruby:2.6

build: ## build locally
	rm -fr .bundle
	make pull_songkick_ruby
	docker-compose build

test: ## run the tests locally
	docker-compose build app_test
	docker-compose run --name songkick_transport_app_test_$(VERSION) \
		app_test \
		sh -c "rspec" \
		|| (ret=$$?; docker rm --force songkick_transport_app_test_$(VERSION) && exit $$ret)
	docker rm --force songkick_transport_app_test_$(VERSION)

console_test:  ## get a bash shell in test env
	docker-compose build app_test
	docker-compose run --rm app_test bash

console:  ## get a bash shell in dev env
	docker-compose build app_dev
	docker-compose run --rm app_dev bash

build_gem:
	gem build songkick-transport.gemspec
