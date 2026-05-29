#!/usr/bin/env bash
# Scenario: re-run install.sh after the post-phase-1 reboot. Should detect
# phase 1 done, run phases 2 and 3, end with a working Nix.
# Requires: $IP.
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/vm.sh"

: "${IP:?IP not set}"

log "running install.sh (phases 2 + 3) on $IP"
# vm_ssh_tty required for install.sh's `sudo -S -v` warm-up; see PLAN.md OQ#1.
vm_ssh_tty "$IP" "echo '$VM_PASS' | sudo -S -v && ~/install.sh < /dev/null"
