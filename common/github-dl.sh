#!/bin/sh
# Download latest GitHub release assets for configured apps.
# Usage: ./github-dl.sh [-d DEST_DIR] [-c CONFIG] [app ...]
# Config lines: name owner/repo asset-regex   (see apps.conf)
set -eu

DIR=$(cd "$(dirname "$0")" && pwd)
DEST=.
CONF=$DIR/apps.conf
while getopts "d:c:" o; do
  case $o in
    d) DEST=$OPTARG ;;
    c) CONF=$OPTARG ;;
    *) exit 1 ;;
  esac
done
shift $((OPTIND - 1))
mkdir -p "$DEST"

# Normalize to regex alternations matching asset naming conventions
case $(uname -m) in
  x86_64|amd64) ARCH='(x86_64|amd64|x64)' ;;
  aarch64|arm64) ARCH='(aarch64|arm64)' ;;
  *) ARCH=$(uname -m) ;;
esac
# Package format by platform: deb/rpm (Linux), dmg/pkg (macOS), exe/msi (Windows)
case $(uname -s) in
  Darwin) OS=macos; PKG='(dmg|pkg)' ;;
  MINGW*|MSYS*|CYGWIN*) OS=windows; PKG='(exe|msi)' ;;
  *)
    OS=linux
    if command -v dpkg >/dev/null 2>&1; then PKG=deb
    elif command -v rpm >/dev/null 2>&1; then PKG=rpm
    else PKG='(deb|rpm)'; fi ;;
esac
# Assets never wanted (signatures, variants)
EXCLUDE='\.sig$|sciter|suse|fixed_webview2|signed'

fetch() {
  name=$1; repo=$2; pat=$3
  # expand $ARCH/$OS placeholders in pattern
  pat=$(printf '%s' "$pat" | sed "s/@ARCH@/$ARCH/g; s/@OS@/$OS/g; s/@PKG@/$PKG/g")
  api="https://api.github.com/repos/$repo/releases/latest"
  auth=""
  [ -n "${GITHUB_TOKEN:-}" ] && auth="Authorization: Bearer $GITHUB_TOKEN"
  url=$(curl -fsSL ${auth:+-H "$auth"} "$api" \
    | grep -o '"browser_download_url": *"[^"]*"' | sed 's/.*: *"//; s/"$//' \
    | grep -Ev -- "$EXCLUDE" | grep -E -- "$pat" | head -n1)
  [ -n "$url" ] || { echo "$name: no asset matches $pat" >&2; return 1; }
  echo "$name: $url"
  curl -fL --progress-bar -o "$DEST/$(basename "$url")" "$url"
}

while read -r name repo pat; do
  case "$name" in ""|\#*) continue ;; esac
  if [ $# -gt 0 ]; then
    case " $* " in *" $name "*) ;; *) continue ;; esac
  fi
  fetch "$name" "$repo" "$pat"
done < "$CONF"
