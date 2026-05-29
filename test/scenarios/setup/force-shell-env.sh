#!/usr/bin/env bash
# Scenario: re-run install.sh phase 3 with $SHELL overridden so the
# configure_shell dispatcher writes the rc file for $SHELL_UNDER_TEST.
# This is the in-VM equivalent of "test the bash branch without chsh".
# Requires: $IP, $SHELL_UNDER_TEST.
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/vm.sh"

: "${IP:?IP not set}"
: "${SHELL_UNDER_TEST:?SHELL_UNDER_TEST not set (zsh|bash)}"

case "$SHELL_UNDER_TEST" in
  zsh)  shell_path="/bin/zsh"  ;;
  bash) shell_path="/bin/bash" ;;
  *) die "unsupported SHELL_UNDER_TEST=$SHELL_UNDER_TEST" ;;
esac

log "re-running install.sh with SHELL=$shell_path (exercises $SHELL_UNDER_TEST branch)"
vm_ssh "$IP" "SHELL=$shell_path ~/install.sh < /dev/null"
