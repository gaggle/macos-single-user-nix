#!/usr/bin/env bash
# Scenario: assert the guest is running macOS 26.
# Requires: $IP.
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/vm.sh"

: "${IP:?IP not set}"

log "asserting: guest macOS build starts with 26"
build=$(vm_ssh "$IP" "sw_vers -productVersion") || die "could not read sw_vers -productVersion"
log "  → macOS $build"
case "$build" in
  26*) ;;
  *) die "expected guest macOS 26.x, got $build" ;;
esac
