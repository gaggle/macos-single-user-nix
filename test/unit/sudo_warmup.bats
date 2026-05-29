#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load test_helper

setup() {
  load_libs
  # Disable real sudo — the predicate overrides below decide each branch.
  export _SUN_SUDO=""
  source_install_sh
}

@test "sudo_warmup: NOPASSWD short-circuits — no TTY check, no prompt" {
  _sudo_passwordless()    { return 0; }
  _have_controlling_tty() { return 1; }  # would fail if reached

  run sudo_warmup
  assert_success
}

@test "sudo_warmup: no NOPASSWD + no TTY → dies with clear message" {
  _sudo_passwordless()    { return 1; }
  _have_controlling_tty() { return 1; }

  run sudo_warmup
  assert_failure
  assert_output --partial "no controlling terminal"
}

@test "sudo_warmup: no NOPASSWD + TTY available → falls through to sudo -v" {
  _sudo_passwordless()    { return 1; }
  _have_controlling_tty() { return 0; }
  # _SUN_SUDO is empty, so the final `$_SUN_SUDO -v` becomes `-v`, which is
  # not a command — exit 127. That's the signal we reached the fallback;
  # we don't want the test to actually invoke real sudo.
  run -127 sudo_warmup
  refute_output --partial "no controlling terminal"
}
