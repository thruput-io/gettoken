.DELETE_ON_ERROR:

CONFIG = . ./config.sh &&

PACKAGE_FORMATS = $(shell $(CONFIG) echo $$PACKAGE_FORMATS)

SUITE  = build/sources $(shell find src scripts -type f)
GO_SRC = build/go-sources $(shell find src/components/contract -type f -name '*.go') \
         src/components/contract/go.mod src/components/contract/go.sum

.PHONY: setup unit test contract signing-key \
        lint check-readme bash-unit-test bash-coverage go-unit-test go-coverage \
        package package-deb package-brew sign packaging-check publish \
        integration-test readme clean

setup:            build/setup.txt
unit:             build/unit.txt
test:             build/integration-test.tap
contract:         build/bin/parse build/bin/format
signing-key:      build/signing/pubkey.gpg
lint:             build/lint.checked
check-readme:     build/check-readme.txt
bash-unit-test:   build/bash-unit-test.checked
bash-coverage:    build/bash-coverage.checked
go-unit-test:     build/go-unit-test.json
go-coverage:      build/go-coverage.checked
package:          build/package.txt
package-deb:      build/dist/deb/InRelease
package-brew:     build/dist/brew/gettoken.rb
sign:             build/dist/deb/InRelease
packaging-check:  build/packaging-check.txt
publish:          build/publish.txt
integration-test: build/integration-test.tap

FORCE:

build/sources: FORCE
	@mkdir -p $(@D)
	@find src scripts -type f | sort > $@.new
	@if cmp -s $@.new $@; then rm $@.new; else mv $@.new $@; fi

build/go-sources: FORCE
	@mkdir -p $(@D)
	@find src/components/contract -type f -name '*.go' | sort > $@.new
	@if cmp -s $@.new $@; then rm $@.new; else mv $@.new $@; fi

build/setup.txt: config.sh
	@mkdir -p $(@D)
	$(CONFIG) $$INSTALL_COMMAND $$BUILD_DEPS
	$(CONFIG) echo "$$BUILD_DEPS" > $@

build/signing/pubkey.gpg:
	scripts/signing-key.sh build/signing

build/bin/parse build/bin/format: $(GO_SRC)
	src/components/contract/build.sh build/bin

build/lint.xml: $(SUITE)
	@mkdir -p $(@D)
	scripts/lint.sh . --format=checkstyle > $@

build/check-readme.txt: $(SUITE) README.md
	@mkdir -p $(@D)
	scripts/readme.sh . > $@

build/bash-unit-test.tap: $(SUITE) build/bin/parse build/bin/format
	@mkdir -p $(@D)
	PATH="$$PWD/build/bin:$$PATH" \
	  bats --recursive --timing --print-output-on-failure \
	  --formatter tap13 --report-formatter tap13 --output build \
	  src scripts > /dev/null
	mv build/report.tap $@

build/bash-coverage.json: $(SUITE) build/bin/parse build/bin/format
	@mkdir -p $(@D)
	PATH="$$PWD/build/bin:$$PATH" \
	  kcov --include-path=src,scripts \
	  --bash-parse-files-in-dir=src,scripts \
	  --exclude-pattern=.bats \
	  build/kcov bats --recursive src scripts > /dev/null
	jq '{percent: (.percent_covered | tonumber)}' \
	  build/kcov/bats/coverage.json > $@

build/go-unit-test.json: $(GO_SRC)
	@mkdir -p $(@D)
	cd src/components/contract && go test -json -mod=vendor \
	  -coverprofile=../../../build/go.coverprofile ./... > ../../../$@

build/go-coverage.json: build/go-unit-test.json
	cd src/components/contract && go tool cover \
	  -func=../../../build/go.coverprofile > ../../../build/go-coverage.txt
	awk 'END { sub(/%/, "", $$3); printf "{\"percent\":%s}\n", $$3 }' \
	  build/go-coverage.txt > $@

build/lint.checked: build/lint.xml thresholds.json
	scripts/check-lint.sh $< thresholds.json > $@

build/bash-unit-test.checked: build/bash-unit-test.tap
	prove --exec cat $< > $@

build/bash-coverage.checked: build/bash-coverage.json thresholds.json
	scripts/check-coverage.sh $< thresholds.json bash-coverage > $@

build/go-coverage.checked: build/go-coverage.json thresholds.json
	scripts/check-coverage.sh $< thresholds.json go-coverage > $@

build/unit.txt: build/check-readme.txt build/lint.checked \
                build/bash-unit-test.checked build/bash-coverage.checked \
                build/go-unit-test.json build/go-coverage.checked
	cat build/check-readme.txt build/lint.checked build/bash-unit-test.checked \
	    build/bash-coverage.checked build/go-coverage.checked > $@
	cat $@

build/dist/deb/Packages: build/unit.txt src/debian src/contracts
	scripts/deliver-deb.sh build/dist/deb

build/dist/brew/gettoken.rb: build/unit.txt src/debian/changelog
	scripts/deliver-brew.sh build/dist/brew

build/dist/deb/InRelease: build/dist/deb/Packages build/signing/pubkey.gpg
	scripts/sign.sh build/dist/deb build/signing

build/package.txt: $(PACKAGE_FORMATS:%=build/package-%.txt)
	cat $^ > $@
	cat $@

build/package-deb.txt: build/dist/deb/InRelease
	@mkdir -p $(@D)
	echo "deb: $$(find build/dist/deb -name '*.deb' | wc -l | tr -d ' ') packages, signed" > $@

build/package-brew.txt: build/dist/brew/gettoken.rb
	@mkdir -p $(@D)
	echo "brew: $$(basename $<)" > $@

build/packaging-check.txt: build/dist/deb/InRelease
	@mkdir -p $(@D)
	scripts/packaging-check.sh build/dist/deb build/signing/pubkey.gpg > $@

build/publish.txt: build/package.txt build/packaging-check.txt
	$(CONFIG) for dist in build/dist/*/; do \
	  format=$$(basename "$$dist"); \
	  eval "publish=\$$PUBLISH_$$(echo $$format | tr a-z A-Z)_COMMAND"; \
	  $$publish "$$dist"; \
	done > $@
	cat $@

build/integration-test.tap: build/publish.txt
	@mkdir -p $(@D)
	$(CONFIG) src/integration-test/test.sh \
	  "$$INSTALL_COMMAND" "$$UNPRIVILEGED_USER" > $@
	prove --exec cat $@

readme:
	scripts/readme.sh . --write

clean:
	rm -rf build
