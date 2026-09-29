#!/usr/bin/env bash
# Scenario: take passwordless sudo away from this test clone, so the installer
# meets sudo the way a person does. The paved image keeps it; only the clone
# loses it. The harness's own steps keep working through `sudo -S`.
# Requires: $IP.
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/vm.sh"

: "${IP:?IP not set}"

log "removing every passwordless sudoers entry from this clone"
# Whichever file grants it (ours from pave, or the base image's own) goes.
# shellcheck disable=SC2016  # the guest expands $f
vm_sudo_sh "$IP" 'grep -lE "^[^#]*NOPASSWD" /etc/sudoers.d/* 2>/dev/null | while read -r f; do rm -f "$f"; done; true'
# Prove it: with the timestamp dropped, sudo must want a password.
if vm_ssh "$IP" "sudo -k; sudo -n true" 2>/dev/null; then
  die "sudo still works without a password in the clone"
fi
log "  → sudo now needs a password"
