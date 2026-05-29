#!/usr/bin/env bash
# Scenario: chsh the VM user to bash so the next install.sh run takes the
# bash branch in configure_shell. macOS ships /bin/bash (3.2) which is enough
# to source nix.sh in a login shell.
# Requires: $IP.
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/vm.sh"

: "${IP:?IP not set}"

log "switching login shell of $VM_USER to /bin/bash"
vm_sudo "$IP" "chsh -s /bin/bash $VM_USER"
# Confirm a fresh login shell now reports bash.
got=$(vm_ssh "$IP" "bash -l -c 'echo \$0'" || true)
log "  → fresh login \$0 = $got"
