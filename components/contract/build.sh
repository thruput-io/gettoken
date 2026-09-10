#!/bin/bash
set -euo pipefail

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

go build -mod=vendor -buildvcs=false -o "$into/parse" ./cmd/parse
go build -mod=vendor -buildvcs=false -o "$into/format" ./cmd/format
