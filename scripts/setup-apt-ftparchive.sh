#!/usr/bin/env bash
set -euo pipefail

outdir=${1:?setup-apt-ftparchive.sh: name the directory to install into}

if command -v apt-ftparchive > /dev/null; then
  exit 0
fi

mkdir -p "$outdir/bin"
cat << 'EOF' > "$outdir/bin/apt-ftparchive"
#!/bin/bash
set -euo pipefail

origin=""
label=""
suite=""
codename=""
archs=""
comps=""
desc=""

while [ $# -gt 0 ]; do
  case "$1" in
    -o)
      opt="$2"
      shift 2
      key=$(echo "$opt" | cut -d= -f1)
      val=$(echo "$opt" | cut -d= -f2-)
      case "$key" in
        "APT::FTPArchive::Release::Origin") origin="$val" ;;
        "APT::FTPArchive::Release::Label") label="$val" ;;
        "APT::FTPArchive::Release::Suite") suite="$val" ;;
        "APT::FTPArchive::Release::Codename") codename="$val" ;;
        "APT::FTPArchive::Release::Architectures") archs="$val" ;;
        "APT::FTPArchive::Release::Components") comps="$val" ;;
        "APT::FTPArchive::Release::Description") desc="$val" ;;
      esac
      ;;
    packages)
      pool_dir="$2"
      shift 2
      find "$pool_dir" -type f -name '*.deb' | sort | while read -r deb; do
        dpkg-deb -f "$deb"
        echo "Filename: $deb"
        size=$(wc -c < "$deb" | tr -d ' ')
        echo "Size: $size"
        if command -v sha256sum > /dev/null; then
          sha=$(sha256sum "$deb" | cut -d' ' -f1)
        else
          sha=$(shasum -a 256 "$deb" | cut -d' ' -f1)
        fi
        echo "SHA256: $sha"
        echo
      done
      exit 0
      ;;
    release)
      dist_dir="$2"
      shift 2
      [ -n "$origin" ] && echo "Origin: $origin"
      [ -n "$label" ] && echo "Label: $label"
      [ -n "$suite" ] && echo "Suite: $suite"
      [ -n "$codename" ] && echo "Codename: $codename"
      echo "Date: $(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S UTC')"
      [ -n "$archs" ] && echo "Architectures: $archs"
      [ -n "$comps" ] && echo "Components: $comps"
      [ -n "$desc" ] && echo "Description: $desc"
      echo "SHA256:"
      (cd "$dist_dir" && find . -type f ! -name 'Release*' ! -name 'InRelease*' | sort) | while read -r rel_file; do
        rel_path="${rel_file#./}"
        abs_file="$dist_dir/$rel_path"
        size=$(wc -c < "$abs_file" | tr -d ' ')
        if command -v sha256sum > /dev/null; then
          sha=$(sha256sum "$abs_file" | cut -d' ' -f1)
        else
          sha=$(shasum -a 256 "$abs_file" | cut -d' ' -f1)
        fi
        printf ' %s %16d %s\n' "$sha" "$size" "$rel_path"
      done
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done
EOF

chmod 755 "$outdir/bin/apt-ftparchive"
