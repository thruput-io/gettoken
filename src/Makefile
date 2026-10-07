prefix = /usr/local
exec_prefix = $(prefix)
libdir = $(exec_prefix)/lib
datarootdir = $(prefix)/share
datadir = $(datarootdir)

naming_an_installation_directory = \
  tools/gettoken/bin/gettoken \
  components/exchanger/exchanger \
  components/contract/contract.go

.PHONY: all configured contract clean

all: configured contract

configured: build/configured

build/configured: $(naming_an_installation_directory)
	set -e; for named in $(naming_an_installation_directory); do \
	  sed -e 's|@libdir@|$(libdir)|g' -e 's|@datadir@|$(datadir)|g' "$$named" > "$$named.configured"; \
	  cat "$$named.configured" > "$$named"; \
	  rm "$$named.configured"; \
	done
	mkdir -p build
	touch $@

contract: build/configured
	./components/contract/build.sh build/bin

clean:
	rm -rf build
