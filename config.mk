BRANCH = $(shell git rev-parse --abbrev-ref HEAD)
SITE_URL = https://thruput.se/gettoken

-include config.$(shell uname -s | tr '[:upper:]' '[:lower:]').mk
-include config.local.mk
