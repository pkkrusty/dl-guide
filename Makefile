BIN ?= dl-tv-guide
PREFIX ?= /usr/local
VERSION = $(shell git describe --tags --exact-match 2>/dev/null || git rev-parse HEAD)

install:
	@echo 'Installing jellyfin-tv-guide.'
	cat './dl-tv-guide.sh' | sed 's_kj4ezj/jellyfin-tv-guide_kj4ezj/jellyfin-tv-guide/tree/$(VERSION)_' > '$(PREFIX)/bin/$(BIN)'
	chmod +x '$(PREFIX)/bin/$(BIN)'
	@echo 'Done installing jellyfin-tv-guide as "$(PREFIX)/bin/$(BIN)".'

uninstall:
	@echo 'Uninstalling jellyfin-tv-guide.'
	rm -f '$(PREFIX)/bin/$(BIN)'
	@echo 'Done uninstalling jellyfin-tv-guide.'

.PHONY: install uninstall
