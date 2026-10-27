#!/bin/sh
# Batch download latest GitHub release packages for configured apps, for both
# amd64 and arm64: .deb .rpm .exe .msi .dmg .pkg (host is not detected).
# Usage: ./github-dl.sh [-d DEST_DIR] [-c CONFIG] [app ...]
# Files go to DEST_DIR/<app>/ (default DEST_DIR: common/download).
# Config lines: name owner/repo   (see apps.conf)
set -eu

DIR=$(cd "$(dirname "$0")" && pwd)
DEST=$DIR/download
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

PKG='\.(deb|rpm|exe|msi|dmg|pkg)$'
ARCH='(x86_64|amd64|x64|aarch64|arm64)'
# Variants never wanted
EXCLUDE='sciter|suse|fixed_webview2|signed'

fetch() {
  name=$1; repo=$2
  api="https://api.github.com/repos/$repo/releases/latest"
  hdr="Accept: application/vnd.github+json"
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    set -- -H "$hdr" -H "Authorization: Bearer $GITHUB_TOKEN"
  else
    set -- -H "$hdr"
  fi
  urls=$(curl -fsSL "$@" "$api" \
    | grep -o '"browser_download_url": *"[^"]*"' | sed 's/.*: *"//; s/"$//' \
    | grep -E -- "$PKG" | grep -E -- "$ARCH" | grep -Ev -- "$EXCLUDE" || true)
  [ -n "$urls" ] || { echo "$name: no matching assets" >&2; return 1; }
  for url in $urls; do
    file=$(basename "$url" | sed 's/%20/ /g')
    mkdir -p "$DEST/$name"
    if [ -s "$DEST/$name/$file" ]; then
      echo "$name: $file (exists, skipped)"
      continue
    fi
    echo "$name: $file"
    curl -fL --progress-bar -o "$DEST/$name/$file.part" "$url"
    mv "$DEST/$name/$file.part" "$DEST/$name/$file"
  done
}

while read -r name repo _; do
  case "$name" in ""|\#*) continue ;; esac
  if [ $# -gt 0 ]; then
    case " $* " in *" $name "*) ;; *) continue ;; esac
  fi
  fetch "$name" "$repo"
done < "$CONF"
