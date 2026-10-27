# os-strap
scripts to quick setup various systems.

## Contents
- `ubuntu/apt-setup.sh`, `debian/apt-setup.sh`: set apt mirror (`-m`) and LAN http proxy (`-p`).
- `macos/allow.sh PATH`: remove the quarantine attribute (`xattr -r -d com.apple.quarantine`).
- `common/github-dl.sh [-d DIR] [-c CONF] [app...]`: download latest GitHub release assets listed in `common/apps.conf` (clash-verge-rev, rustdesk; add more lines).
