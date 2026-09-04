.PHONY: test diagrams

test:
	sh integration/integration.sh

diagrams:
	sh integration/mermaid.sh
