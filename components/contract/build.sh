#!/bin/sh
set -eu

# usage: build.sh DIRECTORY
#
# The build takes no view on how it should be built. Everything a packaging
# system has an opinion about — hardening, trimming, tags, linker flags —
# arrives in GOFLAGS, which go reads by itself, because each target has its own
# answer and its own reason. debian/rules asks for what the archive expects of
# anything it ships. A Homebrew formula asks for whatever std_go_args carries,
# which changes with Homebrew's build and security policy and is not ours to
# copy. Run from a checkout, GOFLAGS is empty and the defaults are the
# toolchain's own.
#
# Only two things are stated here, because neither is a policy: where the
# binaries go, and that the dependency tree vendored into this source is the one
# built against.
if [ $# -ne 1 ]; then
  echo "usage: build.sh DIRECTORY" >&2
  exit 1
fi

mkdir -p "$1"
into=$(CDPATH='' cd "$1" && pwd)

cd "$(dirname "$0")"

unformatted=$(find . -name '*.go' -not -path './vendor/*' -exec gofmt -l {} +)
if [ -n "$unformatted" ]; then
  echo "build.sh: these are not gofmt-clean: $unformatted" >&2
  exit 1
fi

go vet -mod=vendor ./...
go test -mod=vendor ./...

go build -mod=vendor -o "$into/parse" ./cmd/parse
go build -mod=vendor -o "$into/format" ./cmd/format
