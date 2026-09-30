#!/usr/bin/env bash
# Shared setup for BATS unit tests.
#
# Sources install.sh as a library: install.sh guards its main invocation with
# a BASH_SOURCE check, so sourcing loads the functions without running them.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

load_libs() {
  # bats-support and bats-assert come from nixpkgs (bats.withLibraries).
  bats_load_library bats-support
  bats_load_library bats-assert
  # bats-mock is vendored — not packaged in nixpkgs.
  # shellcheck source=/dev/null
  source "${REPO_ROOT}/test/unit/.bats_deps/bats-mock.bash"
}

source_install_sh() {
  # Every sudo pause reads its Enter from this file, not from the terminal the
  # tests run in, where it would wait for an Enter nobody presses.
  _SUN_TTY="${BATS_TEST_TMPDIR}/enter"
  printf '\n' > "$_SUN_TTY"
  # shellcheck source=/dev/null
  source "${REPO_ROOT}/install.sh"
}
