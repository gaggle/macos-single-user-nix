#!/usr/bin/env bash
# Scenario: run install.sh, which should detect a fresh system and stop
# after phase 1 with a reboot notice.
# Requires: $IP.
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/vm.sh"

: "${IP:?IP not set}"

log "running install.sh (phase 1) on $IP"
# Warm sudo, then run installer non-interactively (no stdin → confirm prompts skipped).
# vm_ssh_tty (ssh -tt) is required: install.sh's `sudo -S -v` warm-up fails
# without a tty under some shells even though NOPASSWD is configured. Root
# cause is not understood — see PLAN.md "Open question #1". The workaround
# is deliberate; do not switch back to vm_ssh.
vm_ssh_tty "$IP" "echo '$VM_PASS' | sudo -S -v && ~/install.sh < /dev/null"
