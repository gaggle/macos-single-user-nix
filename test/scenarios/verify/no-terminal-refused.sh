#!/usr/bin/env bash
# Scenario: run install.sh the README's way, piped into bash, over ssh with no
# terminal. It must refuse with exit 1 and name the problem, before it runs any
# sudo command or changes the machine.
# Requires: $IP.
set -euo pipefail
# shellcheck source=../../lib/vm.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/vm.sh"

: "${IP:?IP not set}"

log "asserting: install.sh refuses to run without a terminal"
# ssh without -t allocates no terminal, so /dev/tty must not open.
if vm_ssh "$IP" "true </dev/tty" 2>/dev/null; then
  die "precondition failed: the guest gave the installer a terminal"
fi

status=0
out=$(vm_ssh "$IP" "cat ~/install.sh | bash" 2>&1) || status=$?
log "$out"
(( status == 1 )) || die "installer exited $status, expected 1"
echo "$out" | grep -q "install.sh needs a terminal" \
  || die "installer did not say it needs a terminal"
if echo "$out" | grep -qF '[sudo]'; then
  die "installer printed a sudo command before refusing"
fi
if vm_ssh "$IP" "test -e /etc/synthetic.conf && grep -qE '^nix([[:space:]]|\$)' /etc/synthetic.conf"; then
  die "installer declared /nix in /etc/synthetic.conf"
fi
log "  → installer refused before any sudo command and changed nothing"
