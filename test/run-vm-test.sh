#!/usr/bin/env bash
# Run every playbook under test/playbooks/ in sequence.
#
# Each playbook gets a fresh clone of the paved VM. A single failure does not
# stop the run — we collect results and report a summary at the end, exiting
# non-zero if any playbook failed.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
RUNNER="$HERE/bin/nix-test-vm"

shopt -s nullglob
playbooks=("$HERE/playbooks/"*.sh)
if (( ${#playbooks[@]} == 0 )); then
  echo "no playbooks found in $HERE/playbooks/" >&2
  exit 1
fi

passed=()
failed=()
for path in "${playbooks[@]}"; do
  name="$(basename "$path" .sh)"
  echo
  echo "=============================================================="
  echo "  playbook: $name"
  echo "=============================================================="
  if "$RUNNER" playbook "$name" "$@"; then
    passed+=("$name")
  else
    failed+=("$name")
  fi
done

echo
echo "=============================================================="
echo "  summary: ${#passed[@]} passed, ${#failed[@]} failed"
echo "=============================================================="
for n in "${passed[@]}"; do echo "  PASS  $n"; done
for n in "${failed[@]}"; do echo "  FAIL  $n"; done

(( ${#failed[@]} == 0 ))
