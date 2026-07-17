#!/usr/bin/env bats

load test_helper

setup() {
  load_libs
  source_install_sh
  RC="${BATS_TEST_TMPDIR}/rc"
}

@test "rc_already_sources: false when rc file is missing" {
  run rc_already_sources "$RC" "$NIX_SH_SOURCE_PATH"
  assert_failure
}

@test "rc_already_sources: false when rc exists but does not contain the needle" {
  echo "export PATH=/usr/local/bin:\$PATH" >"$RC"
  run rc_already_sources "$RC" "$NIX_SH_SOURCE_PATH"
  assert_failure
}

@test "rc_already_sources: true for our own appended block" {
  cat >"$RC" <<'EOF'
# Nix (single-user install)
if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi
EOF
  run rc_already_sources "$RC" "$NIX_SH_SOURCE_PATH"
  assert_success
}

@test "rc_already_sources: true for a third-party / hand-rolled source line" {
  # e.g. dotfiles or a previous installer wrote a different syntax.
  echo 'source "$HOME/.nix-profile/etc/profile.d/nix.sh"' >"$RC"
  run rc_already_sources "$RC" "$NIX_SH_SOURCE_PATH"
  assert_success
}
