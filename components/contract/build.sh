#!/bin/sh
set -eu

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

# -buildmode=pie so the binary is position-independent, which is what the
# archive expects of anything it ships and what dh_auto_build would have
# arranged had the build gone through it. GOFLAGS carries whatever the
# packaging adds on top.
go build -mod=vendor -trimpath -buildmode=pie -o "$into/parse" ./cmd/parse
go build -mod=vendor -trimpath -buildmode=pie -o "$into/format" ./cmd/format
