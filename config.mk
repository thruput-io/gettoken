BRANCH = $(shell git rev-parse --abbrev-ref HEAD)

ifneq ($(CI),true)
  -include localenv.sh
endif

-include config.$(shell uname -s | tr '[:upper:]' '[:lower:]').mk
-include config.local.mk
