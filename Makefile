BIN ?= dl-guide
BRANCH = $(shell git branch --show-current)
ORIGIN = $(shell git remote get-url origin)
PREFIX ?= /usr/local
VERSION = $(shell git describe --tags --exact-match 2>/dev/null || git rev-parse HEAD)

install:
	@echo 'Installing jellyfin-tv-guide.'
	cat './dl-guide.sh' | sed "s/GIT_BRANCH=''/GIT_BRANCH='$(BRANCH)'/g" | sed "s/GIT_ORIGIN=''/GIT_ORIGIN='$(ORIGIN)'/g" | sed "s/GIT_VERSION=''/GIT_VERSION='$(VERSION)'/g" > '$(PREFIX)/bin/$(BIN)'
	chmod +x '$(PREFIX)/bin/$(BIN)'
	@echo 'Done installing jellyfin-tv-guide as "$(PREFIX)/bin/$(BIN)".'

uninstall:
	@echo 'Uninstalling jellyfin-tv-guide.'
	rm -f '$(PREFIX)/bin/$(BIN)'
	@echo 'Done uninstalling jellyfin-tv-guide.'

.PHONY: install uninstall
