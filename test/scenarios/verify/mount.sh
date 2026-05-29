#!/usr/bin/env bash
# Scenario: assert /nix is mounted.
# Requires: $IP.
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/vm.sh"

: "${IP:?IP not set}"

log "asserting: /nix is mounted"
# After a fresh boot, sshd comes up before the LaunchDaemon finishes
# (wait4path /nix && diskutil mount). Poll up to 60s.
for _ in $(seq 1 30); do
  if vm_ssh "$IP" "mount | grep -qE ' /nix '" 2>/dev/null; then
    exit 0
  fi
  sleep 2
done
die "/nix is not mounted (after 60s)"
