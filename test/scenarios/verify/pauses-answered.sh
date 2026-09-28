#!/usr/bin/env bash
# Scenario: assert a terminal run answered at least one sudo pause, and print
# the per-invocation counts the driver recorded.
# Requires: $TERMINAL_RUN_DIR.
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/vm.sh"

: "${TERMINAL_RUN_DIR:?TERMINAL_RUN_DIR not set}"

log "asserting: the terminal run answered sudo pauses"
[[ -s "$TERMINAL_RUN_DIR/results" ]] || die "the driver recorded no invocation"
grep -q '^fail' "$TERMINAL_RUN_DIR/results" && die "an invocation failed its checks"
total=0
while IFS= read -r line; do
  log "  invocation: $line"
  n=${line#*pauses=}
  total=$(( total + ${n%% *} ))
done < "$TERMINAL_RUN_DIR/results"
(( total > 0 )) || die "no sudo pause was answered in the whole playbook"
log "  → $total pauses answered"
