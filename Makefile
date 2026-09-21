.DELETE_ON_ERROR:

-include build/config.mk

diagrams:          build/diagrams.txt

config:           build/config.mk
setup:            build/setup.txt
unit:             build/unit.txt
build:            build/publish.txt
test:             build/integration-test.checked
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
publish:          build/publish.txt
integration-test: build/integration-test.checked


build/config.mk: dynamic.sh constants.env
	@mkdir -p $(@D)
	bash dynamic.sh > $@

build/sources:
	@mkdir -p $(@D)
	@find src scripts -type f -exec sha256sum {} + | sort -k 2 > $@.new
	@cmp -s $@.new $@ && rm $@.new || mv $@.new $@

build/go-sources:
	@mkdir -p $(@D)
	@find src/components/contract -type f \( -name '*.go' -o -name 'go.mod' -o -name 'go.sum' \) \
	  -exec sha256sum {} + | sort -k 2 > $@.new
	@cmp -s $@.new $@ && rm $@.new || mv $@.new $@

build/setup.txt: build/config.mk
	@mkdir -p $(@D)
	bash -ec "$(INSTALL_COMMAND) $(BUILD_DEPS)"
	echo "$(BUILD_DEPS)" > $@

build/signing-key.asc: build/setup.txt
	bash scripts/signing-key.sh $@

build/bin/parse build/bin/format: build/go-sources build/setup.txt
	bash src/components/contract/build.sh build/bin

build/lint.xml: build/sources build/setup.txt
	@mkdir -p $(@D)
	bash scripts/lint.sh . --format=checkstyle > $@

build/check-readme.txt: build/sources README.md build/setup.txt
	@mkdir -p $(@D)
	bash scripts/readme.sh . --check > $@

build/bash-unit-test.tap: build/sources build/bin/parse build/bin/format build/setup.txt
	@mkdir -p $(@D)
	set +e; PATH="build/bin:$$PATH" \
	  bats --recursive --timing --print-output-on-failure \
	  --formatter tap13 --report-formatter tap13 --output build \
	  src scripts > /dev/null; said=$$?; set -e; \
	  mv build/report.tap $@; test "$$said" -le 1

build/bash-coverage.json: build/sources build/bin/parse build/bin/format build/setup.txt
	@mkdir -p $(@D)
	PATH="build/bin:$$PATH" \
	  kcov --include-path=src,scripts \
	  --bash-parse-files-in-dir=src,scripts \
	  --exclude-pattern=.bats \
	  build/kcov bats --recursive src scripts > /dev/null
	jq '{percent: (.percent_covered | tonumber)}' \
	  build/kcov/bats/coverage.json > $@

build/go-unit-test.json: build/go-sources build/setup.txt
	@mkdir -p $(@D)
	go test -C src/components/contract -json -mod=vendor \
	  -coverprofile=../../../build/go.coverprofile ./... > $@

build/go-coverage.json: build/go-unit-test.json
	go -C src/components/contract tool cover \
	  -func=../../../build/go.coverprofile > build/go-coverage.txt
	awk 'END { sub(/%/, "", $$3); printf "{\"percent\":%s}\n", $$3 }' \
	  build/go-coverage.txt > $@

build/lint.checked: build/lint.xml thresholds.json
	bash scripts/check-lint.sh $< thresholds.json > $@

build/no-branching.checked: build/sources build/config.mk thresholds.json build/setup.txt
	bash scripts/check-branching.sh . thresholds.json > $@

build/bash-unit-test.checked: build/bash-unit-test.tap
	prove --exec cat $< > $@

build/bash-coverage.checked: build/bash-coverage.json thresholds.json
	bash scripts/check-coverage.sh $< thresholds.json bash-coverage > $@

build/go-coverage.checked: build/go-coverage.json thresholds.json
	bash scripts/check-coverage.sh $< thresholds.json go-coverage > $@

build/unit.txt: build/check-readme.txt build/lint.checked build/no-branching.checked \
                build/bash-unit-test.checked build/bash-coverage.checked \
                build/go-unit-test.json build/go-coverage.checked
	cat build/check-readme.txt build/lint.checked build/no-branching.checked \
	    build/bash-unit-test.checked \
	    build/bash-coverage.checked build/go-coverage.checked > $@
	cat $@

build/dist/deb/packages: build/unit.txt src/debian src/contracts
	bash scripts/deliver-deb.sh build/dist/deb
	@touch $@

build/dist/brew/gettoken.rb: build/unit.txt src/debian/changelog
	bash scripts/deliver-brew.sh build/dist/brew

build/archive.txt: build/dist/deb/packages build/signing-key.asc
	bash scripts/archive.sh build/dist/deb build/site/apt "$(BRANCH)" build/signing-key.asc > $@
	bash scripts/sources.sh build/site/apt "$(BRANCH)" "$(SITE_URL)/apt" >> $@

build/package.txt: build/archive.txt build/dist/brew/gettoken.rb
	cat $^ > $@
	cat $@

build/publish.txt: build/package.txt
	bash scripts/publish.sh build/site/apt "$(BRANCH)" "$(SITE_URL)" > $@
	cat $@

build/integration-test.checked: build/config.mk
	@mkdir -p $(@D)
	bash src/integration-test/test.sh > $@

build/diagrams.txt: build/sources README.md scripts/mermaid.sh
	@mkdir -p $(@D)
	scripts/mermaid.sh > $@
	cat $@

readme:
	scripts/readme.sh . --write

clean:
	rm -rf build
