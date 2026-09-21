BRANCH = $(shell git rev-parse --abbrev-ref HEAD)

-include config.$(shell uname -s | tr '[:upper:]' '[:lower:]').mk
-include config.local.mk
