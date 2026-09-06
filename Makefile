.PHONY: test diagrams

test:
	sh tools/integration-test-tool/test/exit-status.sh
	sh integration/integration.sh

diagrams:
	sh integration/mermaid.sh
