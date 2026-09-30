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
  # Otherwise install.sh reads the terminal the tests run from, and every
  # sudo call waits for an Enter nobody presses. sudo_confirm.bats sets it
  # per test.
  _SUN_INTERACTIVE=0
  # shellcheck source=/dev/null
  source "${REPO_ROOT}/install.sh"
}
