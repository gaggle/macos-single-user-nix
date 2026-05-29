#!/usr/bin/env bash
# Shared logging/utility helpers for the VM test harness.
# Sourced — do not execute.

# shellcheck disable=SC2034  # consumed by callers
PREFIX="${PREFIX:-[vm-test]}"

log()  { echo "$PREFIX $*" >&2; }
warn() { echo "$PREFIX warning: $*" >&2; }
die()  { echo "$PREFIX ERROR: $*" >&2; exit 1; }

# Resolve the repo root from any script under test/.
repo_root() {
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  echo "$here"
}
