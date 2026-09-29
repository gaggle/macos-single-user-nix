#!/usr/bin/env bats

load test_helper

setup() {
  load_libs
  export _SUN_SUDO=""
  source_install_sh
  TARGET="${BATS_TEST_TMPDIR}/out"
}

@test "sudo_write: counts the write in the calling shell" {
  SUDO_USES=0
  sudo_write "write nix line" "$TARGET" ">" <<< "nix"
  [ "$SUDO_USES" -eq 1 ]
}

# write_fstab_entry and write_synthetic_conf must not hand their content to
# sudo_write through a pipe, or the increment happens in a subshell and the
# summary reports one call too few.
@test "write_fstab_entry: its sudo write is counted" {
  SUDO_USES=0
  sudo_write() { SUDO_USES=$(( SUDO_USES + 1 )); cat >/dev/null; }
  write_fstab_entry "00000000-0000-0000-0000-000000000000"
  [ "$SUDO_USES" -eq 1 ]
}

@test "write_synthetic_conf: its sudo writes and chmod are all counted" {
  SUDO_USES=0
  sudo_write() { SUDO_USES=$(( SUDO_USES + 1 )); cat >/dev/null; }
  sudo_run() { SUDO_USES=$(( SUDO_USES + 1 )); }
  write_synthetic_conf
  [ "$SUDO_USES" -eq 2 ]
}
