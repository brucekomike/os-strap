#!/bin/sh
# Configure apt mirror and/or HTTP proxy (LAN, http only) on Ubuntu.
# Usage: sudo ./apt-setup.sh [-m MIRROR_URL] [-p http://HOST:PORT]
#   e.g. -m http://mirrors.example.lan/ubuntu -p http://192.168.1.10:7890
set -eu

MIRROR=""
PROXY=""
while getopts "m:p:h" o; do
  case $o in
    m) MIRROR=$OPTARG ;;
    p) PROXY=$OPTARG ;;
    *) sed -n '2,4p' "$0"; exit 1 ;;
  esac
done
[ "$(id -u)" -eq 0 ] || { echo "run as root" >&2; exit 1; }
case "$MIRROR$PROXY" in "") echo "nothing to do: give -m and/or -p" >&2; exit 1 ;; esac
case "$MIRROR" in ""|http://*) ;; *) echo "mirror must be http://" >&2; exit 1 ;; esac
case "$PROXY" in ""|http://*) ;; *) echo "proxy must be http://" >&2; exit 1 ;; esac

if [ -n "$PROXY" ]; then
  printf 'Acquire::http::Proxy "%s";\n' "$PROXY" > /etc/apt/apt.conf.d/95proxy
fi

if [ -n "$MIRROR" ]; then
  MIRROR=${MIRROR%/}
  . /etc/os-release
  CODENAME=${VERSION_CODENAME:-}
  if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
    cp -n /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.bak
    sed -i -E "s#^URIs:.*#URIs: $MIRROR#" /etc/apt/sources.list.d/ubuntu.sources
  else
    cp -n /etc/apt/sources.list /etc/apt/sources.list.bak 2>/dev/null || true
    cat > /etc/apt/sources.list <<EOL
deb $MIRROR $CODENAME main restricted universe multiverse
deb $MIRROR $CODENAME-updates main restricted universe multiverse
deb $MIRROR $CODENAME-backports main restricted universe multiverse
deb $MIRROR $CODENAME-security main restricted universe multiverse
EOL
  fi
fi
echo "done; run: apt update"
