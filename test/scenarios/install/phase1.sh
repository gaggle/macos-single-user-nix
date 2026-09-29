#!/usr/bin/env bash
# Scenario: run install.sh from a fresh state in a terminal. It must finish
# phase 1 and ask for a reboot.
# Requires: $IP, $TERMINAL_RUN_DIR.
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/vm.sh"

: "${IP:?IP not set}"

log "running install.sh (phase 1) on $IP"
drive_installer "$IP"
