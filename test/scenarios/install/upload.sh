#!/usr/bin/env bash
# Scenario: upload install.sh into the VM and mark it executable.
# Requires: $IP (set by the playbook).
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/vm.sh"

: "${IP:?IP not set}"
REPO_ROOT="$(repo_root)"

log "uploading install.sh → $VM_USER@$IP:~/install.sh"
vm_scp_to "$REPO_ROOT/install.sh" "$IP" "/Users/$VM_USER/install.sh"
vm_ssh "$IP" "chmod +x ~/install.sh"
