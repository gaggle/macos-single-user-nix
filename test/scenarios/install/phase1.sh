#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/vm.sh"

: "${IP:?IP not set}"

log "running install.sh (phase 1) on $IP"
# NOPASSWD is baked into the paved VM, so install.sh's sudo_warmup
# short-circuits on `sudo -n true` — no TTY needed, plain vm_ssh is fine.
vm_ssh "$IP" "~/install.sh < /dev/null"
