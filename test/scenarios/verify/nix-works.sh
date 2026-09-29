#!/usr/bin/env bash
# Scenario: assert `nix --version` works in a fresh login shell of $SHELL_UNDER_TEST
# (default: zsh) and that nix can reach the public cache.
# Requires: $IP. Optional: $SHELL_UNDER_TEST (zsh|bash).
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/vm.sh"

: "${IP:?IP not set}"
shell_name="${SHELL_UNDER_TEST:-zsh}"

log "asserting: nix --version works in a fresh $shell_name login shell"
nix_ver=$(vm_ssh "$IP" "$shell_name -l -c 'nix --version'") \
  || die "nix not on PATH in fresh $shell_name shell"
log "  → $nix_ver"

log "asserting: nix can reach the public binary cache"
vm_ssh "$IP" "$shell_name -l -c 'nix store info --store https://cache.nixos.org'" \
  || die "nix store info failed"
