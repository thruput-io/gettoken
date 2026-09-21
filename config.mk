-include config.env

BRANCH = $(shell git rev-parse --abbrev-ref HEAD)
SITE_URL = $(subst ",,$(PROD_SITE_URL))

-include config.$(shell uname -s | tr '[:upper:]' '[:lower:]').mk
-include config.local.mk
