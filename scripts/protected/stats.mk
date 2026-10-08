.PHONY: FORCE
FORCE:

build/inventory-report.tsv: FORCE
	@mkdir -p $(@D)
	bash scripts/protected/reporters/inventory.sh . $@

build/sources: build/inventory-report.tsv FORCE
	bash scripts/protected/reporters/sources.sh $< $@

build/stats.txt: build/inventory-report.tsv
	bash scripts/protected/reporters/stats.sh $< > $@
