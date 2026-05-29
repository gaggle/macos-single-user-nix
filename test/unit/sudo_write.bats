#!/usr/bin/env bats

load test_helper

setup() {
  load_libs
  # Disable sudo so `$_SUN_SUDO tee` becomes just `tee`. The test's $HOME for
  # destination paths is BATS_TEST_TMPDIR — no real filesystem writes outside
  # the temp dir.
  export _SUN_SUDO=""
  source_install_sh
  TARGET="${BATS_TEST_TMPDIR}/out"
}

# Regression for bug #6 (the boot-breaker): writing /etc/synthetic.conf without
# a trailing newline silently breaks the next boot. The fix in sudo_write is
# `printf '%s\n'` instead of `printf '%s'`.
@test "sudo_write: piped content ends in exactly one newline (bug #6 regression)" {
  echo -n "nix" | sudo_write "write nix line" "$TARGET" ">"

  # Last byte must be 0x0a.
  run xxd -s -1 -l 1 -p "$TARGET"
  assert_output "0a"
}

@test "sudo_write: empty input → file ends in exactly one newline" {
  printf '' | sudo_write "empty write" "$TARGET" ">"

  # File should be a single '\n'.
  run wc -c <"$TARGET"
  assert_output --regexp '^[[:space:]]*1$'
}

@test "sudo_write: content with trailing newline → no double newline" {
  printf 'nix\n' | sudo_write "newline-terminated write" "$TARGET" ">"

  # \$(cat) in sudo_write strips trailing newlines, then printf adds one back.
  # Result: exactly one trailing newline, total 4 bytes.
  run wc -c <"$TARGET"
  assert_output --regexp '^[[:space:]]*4$'
}

@test "sudo_write: mode '>' creates/overwrites" {
  echo "first" >"$TARGET"
  echo -n "second" | sudo_write "overwrite" "$TARGET" ">"

  run cat "$TARGET"
  assert_output "second"
}

@test "sudo_write: mode '>>' appends" {
  printf 'first\n' >"$TARGET"
  echo -n "second" | sudo_write "append" "$TARGET" ">>"

  run cat "$TARGET"
  assert_line --index 0 "first"
  assert_line --index 1 "second"
}
