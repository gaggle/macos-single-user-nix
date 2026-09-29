#!/usr/bin/env bash
# Scenario: assert the sudo commands the installer printed match
# test/expected-sudo-commands.txt, with temporary paths, the disk container and
# the user name normalized.
#
#   sudo-commands.sh exact  [first [last]]   the commands equal the list
#   sudo-commands.sh prefix [first [last]]   the commands equal the list up to
#                                            where the playbook stopped
#
# first and last select installer invocations (counting from 1) whose commands
# are joined; the default is all of them. A playbook that starts the installer
# over from a fresh state checks that invocation on its own.
# Requires: $TERMINAL_RUN_DIR. Optional: $EXPECTED_SUDO_COMMANDS.
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"

mode="${1:?usage: sudo-commands.sh exact|prefix [first [last]]}"
first="${2:-1}"
last="${3:-999999}"
: "${TERMINAL_RUN_DIR:?TERMINAL_RUN_DIR not set}"
expected_file="${EXPECTED_SUDO_COMMANDS:-$(repo_root)/test/expected-sudo-commands.txt}"

log "asserting: the sudo commands printed match the expected list ($mode, invocations $first-$last)"
[[ -f "$TERMINAL_RUN_DIR/sudo-commands" ]] || die "the driver recorded no sudo commands"

actual=$(awk -v first="$first" -v last="$last" '
  $0 == "--" { n++; next }
  n >= first && n <= last { print }
' "$TERMINAL_RUN_DIR/sudo-commands" \
  | sed -E -e 's#/var/folders/[^ ]*#<tmp>#g' -e 's#disk[0-9]+#<container>#g' -e 's#[^ ]+:staff#<user>:staff#g')

count=0
[[ -z "$actual" ]] || count=$(printf '%s\n' "$actual" | wc -l | tr -d ' ')
(( count > 0 )) || die "no sudo commands were printed in invocations $first-$last"

case "$mode" in
  exact)  want=$(cat "$expected_file") ;;
  prefix) want=$(head -n "$count" "$expected_file") ;;
  *) die "unknown mode: $mode" ;;
esac

if [[ "$actual" != "$want" ]]; then
  diff <(printf '%s\n' "$want") <(printf '%s\n' "$actual") >&2 || true
  die "the sudo commands printed differ from ${expected_file##*/} (< expected, > printed)"
fi
log "  → $count sudo commands match"
