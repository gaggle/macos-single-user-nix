#!/usr/bin/env bash
# Scenario: assert that running install.sh after /etc/synthetic.conf was wiped
# redoes phase 1: it writes the 'nix' entry again, prints the reboot notice,
# exits 0, and creates no APFS volume.
# Requires: $IP.
set -euo pipefail
# shellcheck source=../../lib/vm.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/vm.sh"

: "${IP:?IP not set}"

log "asserting: install.sh redoes phase 1 when synthetic.conf was wiped"
vm_ssh "$IP" "test ! -e /etc/synthetic.conf || ! grep -qE '^nix([[:space:]]|\$)' /etc/synthetic.conf" \
  || die "precondition failed: /etc/synthetic.conf still declares /nix"

if terminal_mode; then
  drive_installer "$IP" 0
  out=$(tr -d '\r' < "$TERMINAL_RUN_DIR/transcript")
else
  # NOPASSWD is baked into the paved VM, so plain vm_ssh is fine.
  rc=0
  out=$(vm_ssh "$IP" "\$HOME/install.sh < /dev/null 2>&1" 2>&1 | tr -d '\r') || rc=$?
  (( rc == 0 )) || die "installer exited $rc, expected 0:
$out"
fi

echo "$out" | grep -q "declaring /nix in /etc/synthetic.conf" \
  || die "installer did not redo phase 1:
$out"
echo "$out" | grep -q "REBOOT REQUIRED" \
  || die "installer did not print the reboot notice:
$out"
vm_ssh "$IP" "grep -qE '^nix([[:space:]]|\$)' /etc/synthetic.conf" \
  || die "installer did not write the 'nix' entry to /etc/synthetic.conf"
if vm_ssh "$IP" "diskutil list | grep -q 'Nix Store'"; then
  die "installer created a Nix Store volume"
fi
if vm_ssh "$IP" "mount | grep -qE ' /nix '"; then
  die "installer mounted a volume on /nix"
fi
log "  → installer redid phase 1, printed the reboot notice, exited 0, made no volume"
