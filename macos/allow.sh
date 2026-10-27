#!/bin/sh
# Remove the quarantine attribute from an app/file. Usage: ./allow.sh /Applications/Foo.app
set -eu
[ $# -eq 1 ] || { echo "usage: $0 PATH" >&2; exit 1; }
xattr -r -d com.apple.quarantine "$1"
