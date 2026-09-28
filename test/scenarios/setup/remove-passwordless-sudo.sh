#!/usr/bin/env bash
# Scenario: take passwordless sudo away from this test clone, so the installer
# meets sudo the way a person does. The paved image keeps it; only the clone
# loses it. The harness's own steps keep working through `sudo -S`.
# Requires: $IP.
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/vm.sh"

: "${IP:?IP not set}"

log "removing passwordless sudo from this clone"
# Two files grant it: ours (written by pave) and the base image's own.
vm_sudo "$IP" "rm -f /etc/sudoers.d/mssun-test /etc/sudoers.d/admin-nopasswd"
# Prove it: with the timestamp dropped, sudo must want a password.
if vm_ssh "$IP" "sudo -k; sudo -n true" 2>/dev/null; then
  die "sudo still works without a password in the clone"
fi
log "  → sudo now needs a password"
