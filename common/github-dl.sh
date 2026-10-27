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

ARCH=$(uname -m); OS=$(uname -s)
export ARCH OS

fetch() {
  name=$1; repo=$2; pat=$3
  # expand $ARCH/$OS placeholders in pattern
  pat=$(printf '%s' "$pat" | sed "s/@ARCH@/$ARCH/g; s/@OS@/$OS/g")
  api="https://api.github.com/repos/$repo/releases/latest"
  auth=""
  [ -n "${GITHUB_TOKEN:-}" ] && auth="Authorization: Bearer $GITHUB_TOKEN"
  url=$(curl -fsSL ${auth:+-H "$auth"} "$api" \
    | grep -o '"browser_download_url": *"[^"]*"' | sed 's/.*: *"//; s/"$//' \
    | grep -E -- "$pat" | head -n1)
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
