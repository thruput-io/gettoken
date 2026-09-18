.DELETE_ON_ERROR:

include config.sh
-include config.local.sh

.PHONY: setup unit build test contract signing-key \
        lint check-readme bash-unit-test bash-coverage go-unit-test go-coverage \
        package archive publish unpublish \
        integration-test readme clean

setup:            build/setup.txt
unit:             build/unit.txt
build:            build/publish.txt
test:             build/integration-test.tap
contract:         build/bin/parse build/bin/format
signing-key:      build/signing-key.asc
lint:             build/lint.checked
no-branching:     build/no-branching.checked
check-readme:     build/check-readme.txt
bash-unit-test:   build/bash-unit-test.checked
bash-coverage:    build/bash-coverage.checked
go-unit-test:     build/go-unit-test.json
go-coverage:      build/go-coverage.checked
package:          build/package.txt
package-brew:     build/dist/brew/gettoken.rb
archive:          build/archive.txt
publish:          build/publish.txt
integration-test: build/integration-test.tap

FORCE:

build/sources: FORCE
	@mkdir -p $(@D)
	@find src scripts -type f -exec sha256sum {} + | sort -k 2 > $@.new
	@cmp -s $@.new $@ && rm $@.new || mv $@.new $@

build/go-sources: FORCE
	@mkdir -p $(@D)
	@find src/components/contract -type f \( -name '*.go' -o -name 'go.mod' -o -name 'go.sum' \) \
	  -exec sha256sum {} + | sort -k 2 > $@.new
	@cmp -s $@.new $@ && rm $@.new || mv $@.new $@

build/config-sources: FORCE
	@mkdir -p $(@D)
	@sha256sum config.sh > $@.new
	@cmp -s $@.new $@ && rm $@.new || mv $@.new $@

build/setup.txt: build/config-sources
	@mkdir -p $(@D)
	sh -ec "$$INSTALL_COMMAND $$BUILD_DEPS"
	echo "$$BUILD_DEPS" > $@

build/signing-key.asc: build/setup.txt
	scripts/signing-key.sh $@

build/bin/parse build/bin/format: build/go-sources build/setup.txt
	src/components/contract/build.sh build/bin

build/lint.xml: build/sources build/setup.txt
	@mkdir -p $(@D)
	scripts/lint.sh . --format=checkstyle > $@

build/check-readme.txt: build/sources README.md build/setup.txt
	@mkdir -p $(@D)
	scripts/readme.sh . --check > $@

build/bash-unit-test.tap: build/sources build/bin/parse build/bin/format build/setup.txt
	@mkdir -p $(@D)
	set +e; PATH="$$PWD/build/bin:$$PATH" \
	  bats --recursive --timing --print-output-on-failure \
	  --formatter tap13 --report-formatter tap13 --output build \
	  src scripts > /dev/null; said=$$?; set -e; \
	  mv build/report.tap $@; test "$$said" -le 1

build/bash-coverage.json: build/sources build/bin/parse build/bin/format build/setup.txt
	@mkdir -p $(@D)
	PATH="$$PWD/build/bin:$$PATH" \
	  kcov --include-path=src,scripts \
	  --bash-parse-files-in-dir=src,scripts \
	  --exclude-pattern=.bats \
	  build/kcov bats --recursive src scripts > /dev/null
	jq '{percent: (.percent_covered | tonumber)}' \
	  build/kcov/bats/coverage.json > $@

build/go-unit-test.json: build/go-sources build/setup.txt
	@mkdir -p $(@D)
	go test -C src/components/contract -json -mod=vendor \
	  -coverprofile=$$PWD/build/go.coverprofile ./... > $@

build/go-coverage.json: build/go-unit-test.json
	go -C src/components/contract tool cover \
	  -func=$$PWD/build/go.coverprofile > build/go-coverage.txt
	awk 'END { sub(/%/, "", $$3); printf "{\"percent\":%s}\n", $$3 }' \
	  build/go-coverage.txt > $@

build/lint.checked: build/lint.xml thresholds.json
	scripts/check-lint.sh $< thresholds.json > $@

build/no-branching.checked: build/sources build/config-sources thresholds.json build/setup.txt
	scripts/check-branching.sh . thresholds.json > $@

build/bash-unit-test.checked: build/bash-unit-test.tap
	prove --exec cat $< > $@

build/bash-coverage.checked: build/bash-coverage.json thresholds.json
	scripts/check-coverage.sh $< thresholds.json bash-coverage > $@

build/go-coverage.checked: build/go-coverage.json thresholds.json
	scripts/check-coverage.sh $< thresholds.json go-coverage > $@

build/unit.txt: build/check-readme.txt build/lint.checked build/no-branching.checked \
                build/bash-unit-test.checked build/bash-coverage.checked \
                build/go-unit-test.json build/go-coverage.checked
	cat build/check-readme.txt build/lint.checked build/no-branching.checked \
	    build/bash-unit-test.checked \
	    build/bash-coverage.checked build/go-coverage.checked > $@
	cat $@

build/dist/deb/packages: build/unit.txt src/debian src/contracts
	scripts/deliver-deb.sh build/dist/deb
	@touch $@

build/dist/brew/gettoken.rb: build/unit.txt src/debian/changelog
	scripts/deliver-brew.sh build/dist/brew

build/archive.txt: build/dist/deb/packages build/signing-key.asc
	scripts/archive.sh build/dist/deb build/site/apt "$$BRANCH" build/signing-key.asc > $@
	scripts/sources.sh build/site/apt "$$BRANCH" "$$SITE_URL/apt" >> $@

build/package.txt: build/archive.txt
	cat $^ > $@
	cat $@

build/publish.txt: build/package.txt
	scripts/publish.sh build/site/apt "$$BRANCH" "$$SITE_URL" > $@
	cat $@

build/integration-test.tap: build/config-sources
	@mkdir -p $(@D)
	src/integration-test/test.sh "$$INSTALL_COMMAND" > $@
	prove --exec cat $@

readme:
	scripts/readme.sh . --write

clean:
	rm -rf build
