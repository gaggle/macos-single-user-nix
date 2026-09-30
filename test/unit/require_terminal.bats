#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load test_helper

setup() {
  load_libs
  export _SUN_SUDO=""
  source_install_sh
}

@test "require_terminal: passes when the terminal opens" {
  run require_terminal
  assert_success
}

@test "require_terminal: dies saying how to run it when there is no terminal" {
  _SUN_TTY="${BATS_TEST_TMPDIR}/no-such-terminal"
  run require_terminal
  assert_failure
  assert_output --partial "install.sh needs a terminal"
  assert_output --partial "| bash"
}

@test "main: refuses before it prints anything else when there is no terminal" {
  _SUN_TTY="${BATS_TEST_TMPDIR}/no-such-terminal"
  preflight() { echo "PREFLIGHT"; }
  run main
  assert_failure
  refute_output --partial "PREFLIGHT"
}
