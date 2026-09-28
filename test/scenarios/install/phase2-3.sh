#!/usr/bin/env bash
# Scenario: re-run install.sh after the post-phase-1 reboot. Should detect
# phase 1 done, run phases 2 and 3, end with a working Nix.
# Requires: $IP.
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/vm.sh"

: "${IP:?IP not set}"

log "running install.sh (phases 2 + 3) on $IP"
if terminal_mode; then
  # No passwordless sudo here: the installer runs in a terminal and is answered
  # at every prompt it prints.
  drive_installer "$IP"
else
  # NOPASSWD is baked into the paved VM, so install.sh's sudo_warmup
  # short-circuits on `sudo -n true` — no TTY needed, plain vm_ssh is fine.
  vm_ssh "$IP" "~/install.sh < /dev/null"
fi
