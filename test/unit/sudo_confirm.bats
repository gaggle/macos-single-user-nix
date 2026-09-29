#!/usr/bin/env bats

load test_helper

bats_require_minimum_version 1.5.0

PAUSE_TEXT="[sudo] Press Enter to run, or Ctrl-C to abort..."

setup() {
  load_libs
  export _SUN_SUDO=""
  # The pause reads its Enter from here instead of the terminal.
  _SUN_TTY="${BATS_TEST_TMPDIR}/enter"
  printf '\n\n\n' > "$_SUN_TTY"
  export _SUN_TTY
  source_install_sh
  TARGET="${BATS_TEST_TMPDIR}/out"
}

# sudo_write gets its content on a pipe, so stdin is not a terminal inside it.
# The pause must still happen when the installer itself was started from one.
@test "sudo_write: pauses when the installer was started from a terminal" {
  _SUN_INTERACTIVE=1
  run --separate-stderr sudo_write "write nix line" "$TARGET" ">" <<< "nix"
  assert_success
  [[ "$stderr" == *"$PAUSE_TEXT"* ]]
  run cat "$TARGET"
  assert_output "nix"
}

@test "sudo_write: does not pause when the installer was not started from a terminal" {
  _SUN_INTERACTIVE=0
  run --separate-stderr sudo_write "write nix line" "$TARGET" ">" <<< "nix"
  assert_success
  [[ "$stderr" != *"$PAUSE_TEXT"* ]]
}

@test "sudo_run: pauses when the installer was started from a terminal" {
  _SUN_INTERACTIVE=1
  run --separate-stderr sudo_run "print hello" echo hello
  assert_success
  [[ "$stderr" == *"$PAUSE_TEXT"* ]]
}

@test "sudo_run: does not pause when the installer was not started from a terminal" {
  _SUN_INTERACTIVE=0
  run --separate-stderr sudo_run "print hello" echo hello
  assert_success
  [[ "$stderr" != *"$PAUSE_TEXT"* ]]
}
