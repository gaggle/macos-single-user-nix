#!/usr/bin/env bats

load test_helper

bats_require_minimum_version 1.5.0

PAUSE_TEXT="[sudo] Press Enter to run, or Ctrl-C to abort..."

setup() {
  load_libs
  export _SUN_SUDO=""
  source_install_sh
  TARGET="${BATS_TEST_TMPDIR}/out"
}

# sudo_write gets its content on a pipe, so stdin is not a terminal inside it.
# The pause must still happen.
@test "sudo_write: pauses before it writes" {
  run --separate-stderr sudo_write "write nix line" "$TARGET" ">" <<< "nix"
  assert_success
  [[ "$stderr" == *"$PAUSE_TEXT"* ]]
  run cat "$TARGET"
  assert_output "nix"
}

@test "sudo_run: pauses before it runs" {
  run --separate-stderr sudo_run "print hello" echo hello
  assert_success
  [[ "$stderr" == *"$PAUSE_TEXT"* ]]
}

