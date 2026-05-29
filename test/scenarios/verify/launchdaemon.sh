#!/usr/bin/env bash
# Scenario: assert the org.nixos.darwin-store LaunchDaemon is loaded.
# Requires: $IP.
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/vm.sh"

: "${IP:?IP not set}"

log "asserting: org.nixos.darwin-store LaunchDaemon is loaded"
vm_sudo "$IP" "launchctl print system/org.nixos.darwin-store >/dev/null" \
  || die "LaunchDaemon org.nixos.darwin-store not loaded"
