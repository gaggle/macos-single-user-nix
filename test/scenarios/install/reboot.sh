#!/usr/bin/env bash
# Scenario: reboot the VM and wait for SSH again. Updates $IP via stdout.
# Requires: $IP, $VM_NAME. Echoes new IP (use: IP=$(... reboot.sh)).
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/vm.sh"

: "${IP:?IP not set}"
: "${VM_NAME:?VM_NAME not set}"

vm_reboot "$IP" "$VM_NAME"
