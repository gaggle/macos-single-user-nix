#!/usr/bin/env bash
# Scenario: undo phase 1's effect by removing the 'nix' line from
# /etc/synthetic.conf (and the file if that leaves it empty). Used to simulate
# "phase 1 didn't survive" — followed by a reboot, /nix should not appear.
# Requires: $IP.
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/vm.sh"

: "${IP:?IP not set}"

log "corrupting state: removing 'nix' from /etc/synthetic.conf"
vm_sudo_sh "$IP" "sed -i '' '/^nix\$/d' /etc/synthetic.conf 2>/dev/null || true"
vm_sudo_sh "$IP" "[ -s /etc/synthetic.conf ] || rm -f /etc/synthetic.conf"
