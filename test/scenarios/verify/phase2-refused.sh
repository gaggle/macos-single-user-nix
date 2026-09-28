#!/usr/bin/env bash
# Scenario: assert that running install.sh without phase 1 effects (no /nix dir,
# no reboot) refuses to start phase 2 with a clear error rather than silently
# making a mess.
#
# Drives the predicate: install.sh phase 2's first check is `nix_dir_present`
# which dies with "did you reboot since editing /etc/synthetic.conf?"
#
# Requires: $IP.
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/vm.sh"

: "${IP:?IP not set}"

log "asserting: install.sh refuses to enter phase 2 when /nix is absent"
if terminal_mode; then
  # The installer must exit 1 in the terminal, still after answering the
  # password prompt once.
  drive_installer "$IP" 1
  out=$(tr -d '\r' < "$TERMINAL_RUN_DIR/transcript")
else
  # NOPASSWD is baked into the paved VM, so install.sh's sudo_warmup
  # short-circuits on `sudo -n true` — no TTY needed, plain vm_ssh is fine.
  out=$(vm_ssh "$IP" "~/install.sh < /dev/null 2>&1" 2>&1 | tr -d '\r' || true)
fi
echo "$out" | grep -qE "does not exist|reboot" \
  || die "expected reboot/nix-missing error from installer, got:
$out"
# And /nix must still be absent — phase 2 must not have created an APFS volume.
vm_ssh "$IP" "mount | grep -qE ' /nix '" \
  && die "phase 2 proceeded despite phase 1 not being effective" || true
log "  → installer refused as expected"
