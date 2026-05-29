#!/usr/bin/env bats

load test_helper

setup() {
  load_libs
  source_install_sh
  FIXTURE="${BATS_TEST_TMPDIR}/synthetic.conf"
}

@test "phase1_done: true for 'nix\\n'" {
  printf 'nix\n' >"$FIXTURE"
  run phase1_done "$FIXTURE"
  assert_success
}

@test "phase1_done: true for tab-form 'nix\\tfoo\\n'" {
  printf 'nix\tfoo\n' >"$FIXTURE"
  run phase1_done "$FIXTURE"
  assert_success
}

@test "phase1_done: false for prefix-only 'nixos\\n' (no false match)" {
  printf 'nixos\n' >"$FIXTURE"
  run phase1_done "$FIXTURE"
  assert_failure
}

@test "phase1_done: false when file is missing" {
  run phase1_done "${BATS_TEST_TMPDIR}/does-not-exist"
  assert_failure
}
