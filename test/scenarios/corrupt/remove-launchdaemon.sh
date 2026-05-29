#!/usr/bin/env bash
# Scenario: unload + remove the org.nixos.darwin-store LaunchDaemon plist and
# unmount /nix. Simulates "phase 2's daemon broke after install" — used to
# verify that a subsequent reboot leaves /nix unmounted (proving the daemon is
# what mounts it) and that nix --version then fails.
# Requires: $IP.
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/vm.sh"

: "${IP:?IP not set}"

log "corrupting state: unloading + removing org.nixos.darwin-store"
vm_sudo_sh "$IP" "launchctl unload /Library/LaunchDaemons/org.nixos.darwin-store.plist 2>/dev/null || true"
vm_sudo "$IP" "rm -f /Library/LaunchDaemons/org.nixos.darwin-store.plist"
log "  unmounting /nix"
vm_sudo_sh "$IP" "diskutil unmount force /nix 2>/dev/null || true"
