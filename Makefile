.DELETE_ON_ERROR:

CONFIG = . ./config.sh &&

PACKAGE_FORMATS = $(shell $(CONFIG) echo $$PACKAGE_FORMATS)

BASH_FLOOR = 22
GO_FLOOR   = 44

SUITE  = $(shell find src scripts -type f)
GO_SRC = $(shell find src/components/contract -type f -name '*.go') \
         src/components/contract/go.mod src/components/contract/go.sum

.PHONY: setup unit test lint check-readme contract unit-test coverage go-coverage \
        signing-key package package-deb package-brew sign packaging-check \
        publish integration-test readme clean

setup:            build/reports/setup
unit:             build/reports/unit
test:             build/reports/integration-test
lint:             build/reports/lint
check-readme:     build/reports/check-readme
unit-test:        build/reports/unit-test
coverage:         build/reports/coverage
go-coverage:      build/reports/go-coverage
contract:         build/bin/parse build/bin/format
signing-key:      build/signing/pubkey.gpg
package:          build/reports/package
package-deb:      build/reports/package-deb
package-brew:     build/reports/package-brew
sign:             build/dist/deb/InRelease
packaging-check:  build/reports/packaging-check
publish:          build/reports/publish
integration-test: build/reports/integration-test

readme:
	scripts/readme.sh . --write

clean:
	rm -rf build

build/reports/setup: config.sh
	@mkdir -p $(@D)
	$(CONFIG) $$INSTALL_COMMAND $$BUILD_DEPS
	$(CONFIG) echo "installed $$BUILD_DEPS" > $@

build/signing/pubkey.gpg:
	scripts/signing-key.sh build/signing

build/bin/parse build/bin/format: $(GO_SRC)
	src/components/contract/build.sh build/bin

build/reports/lint: $(SUITE)
	@mkdir -p $(@D)
	scripts/lint.sh . > $@ 2>&1
	test "$$(sed -n 's/^ok: shellcheck read \([0-9]*\) files.*/\1/p' $@)" -ge 1

build/reports/check-readme: $(SUITE) README.md
	@mkdir -p $(@D)
	scripts/readme.sh . > $@ 2>&1
	grep -q '^ok: ' $@

build/reports/unit-test: $(SUITE) build/bin/parse build/bin/format
	@mkdir -p $(@D)
	PATH="build/bin:$$PATH" \
	  bats --recursive src scripts > $@
	! grep -q '^not ok' $@
	test "$$(grep -c '^ok ' $@)" -eq "$$(sed -n 's/^1\.\.//p' $@)"

build/reports/coverage: $(SUITE) build/bin/parse build/bin/format
	@mkdir -p $(@D)
	PATH="build/bin:$$PATH" \
	  kcov --include-path=src,scripts \
	  --bash-parse-files-in-dir=src,scripts \
	  --exclude-pattern=.bats \
	  build/kcov bats --recursive src scripts
	jq -r '.percent_covered' build/kcov/bats/coverage.json > $@
	test "$$(sed 's/\..*//' $@)" -ge $(BASH_FLOOR)

build/reports/go-coverage: $(GO_SRC)
	@mkdir -p $(@D) build/kcov
	cd src/components/contract && go test -mod=vendor \
	  -coverprofile=../../../build/kcov/go.out ./...
	cd src/components/contract && go tool cover \
	  -func=../../../build/kcov/go.out > ../../../build/reports/go.func
	awk 'END { sub(/%/, "", $$3); print $$3 }' build/reports/go.func > $@
	test "$$(sed 's/\..*//' $@)" -ge $(GO_FLOOR)

build/reports/unit: build/reports/lint \
                            build/reports/check-readme \
                            build/reports/unit-test \
                            build/reports/coverage \
                            build/reports/go-coverage
	{ cat build/reports/lint build/reports/check-readme; \
	  echo "$$(grep -c '^ok ' build/reports/unit-test) tests, all ok"; \
	  echo "bash $$(cat build/reports/coverage)% covered, floor $(BASH_FLOOR)"; \
	  echo "go $$(cat build/reports/go-coverage)% covered, floor $(GO_FLOOR)"; } > $@
	cat $@

build/dist/deb/Packages: build/reports/unit src/debian src/contracts
	scripts/deliver-deb.sh build/dist/deb

build/dist/brew/gettoken.rb: build/reports/unit src/debian/changelog
	scripts/deliver-brew.sh build/dist/brew

build/dist/deb/InRelease: build/dist/deb/Packages build/signing/pubkey.gpg
	scripts/sign.sh build/dist/deb build/signing

build/reports/package: $(PACKAGE_FORMATS:%=build/reports/package-%)
	cat $^ > $@
	cat $@

build/reports/package-deb: build/dist/deb/InRelease
	@mkdir -p $(@D)
	echo "deb: $$(find build/dist/deb -name '*.deb' | wc -l | tr -d ' ') packages, signed" > $@

build/reports/package-brew: build/dist/brew/gettoken.rb
	@mkdir -p $(@D)
	echo "brew: $$(basename $<)" > $@

build/reports/packaging-check: build/dist/deb/InRelease
	@mkdir -p $(@D)
	scripts/packaging-check.sh build/dist/deb \
	  build/signing/pubkey.gpg > $@

build/reports/publish: build/reports/package build/reports/packaging-check
	$(CONFIG) for dist in build/dist/*/; do \
	  format=$$(basename "$$dist"); \
	  eval "publish=\$$PUBLISH_$$(echo $$format | tr a-z A-Z)_COMMAND"; \
	  $$publish "$$dist"; \
	done > $@
	cat $@

build/reports/integration-test: build/reports/publish
	@mkdir -p $(@D)
	$(CONFIG) src/integration-test/test.sh \
	  "$$INSTALL_COMMAND" "$$UNPRIVILEGED_USER" > $@
	cat $@

build/reports/diagrams: README.md scripts/mermaid.sh
	@mkdir -p $(@D)
	scripts/mermaid.sh > $@ 2>&1
