#!/usr/bin/env bats

load test_helper

setup() {
  load_libs
  source_install_sh
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "$HOME"
}

# ─── configure_shell_zsh ─────────────────────────────────────────────────────

@test "configure_shell_zsh: appends to a fresh rc with preamble + source block" {
  local rc="$HOME/.zshenv"
  run configure_shell_zsh "$rc"
  assert_success
  [[ -f "$rc" ]]
  run cat "$rc"
  assert_output --partial "# Nix (single-user install)"
  assert_output --partial '.nix-profile/etc/profile.d/nix.sh'
  assert_output --partial 'if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then'
}

@test "configure_shell_zsh: idempotent — second run does not re-append" {
  local rc="$HOME/.zshenv"
  configure_shell_zsh "$rc"
  local first
  first=$(wc -l <"$rc")
  run configure_shell_zsh "$rc"
  assert_success
  assert_output --partial "already sources nix.sh"
  local second
  second=$(wc -l <"$rc")
  [[ "$first" == "$second" ]]
}

@test "configure_shell_zsh: leaves existing user content intact" {
  local rc="$HOME/.zshenv"
  printf '# user content\nexport FOO=bar\n' >"$rc"
  configure_shell_zsh "$rc"
  run cat "$rc"
  assert_output --partial "export FOO=bar"
  assert_output --partial '.nix-profile/etc/profile.d/nix.sh'
}

@test "configure_shell_zsh: creates parent directory if missing" {
  local rc="$HOME/nested/dir/.zshenv"
  run configure_shell_zsh "$rc"
  assert_success
  [[ -f "$rc" ]]
}

# ─── configure_shell_bash ────────────────────────────────────────────────────

@test "configure_shell_bash: appends to ~/.bash_profile by default" {
  run configure_shell_bash
  assert_success
  [[ -f "$HOME/.bash_profile" ]]
  run cat "$HOME/.bash_profile"
  assert_output --partial '.nix-profile/etc/profile.d/nix.sh'
}

@test "configure_shell_bash: skips when rc already sources nix.sh" {
  local rc="$HOME/.bash_profile"
  echo '. "$HOME/.nix-profile/etc/profile.d/nix.sh"' >"$rc"
  run configure_shell_bash "$rc"
  assert_success
  assert_output --partial "already sources nix.sh"
  # Should not have been modified.
  run cat "$rc"
  refute_output --partial "# Nix (single-user install)"
}

# ─── configure_shell dispatch ────────────────────────────────────────────────

@test "configure_shell: SHELL=zsh dispatches to configure_shell_zsh" {
  SHELL=/bin/zsh
  configure_shell_zsh() { echo "zsh-called rc=${1:-default}"; }
  configure_shell_bash() { echo "bash-called"; }
  run configure_shell
  assert_success
  assert_output --partial "zsh-called"
  refute_output --partial "bash-called"
}

@test "configure_shell: SHELL=bash dispatches to configure_shell_bash" {
  SHELL=/bin/bash
  configure_shell_zsh() { echo "zsh-called"; }
  configure_shell_bash() { echo "bash-called"; }
  run configure_shell
  assert_success
  assert_output --partial "bash-called"
  refute_output --partial "zsh-called"
}

@test "configure_shell: unknown shell warns and falls back to zsh" {
  SHELL=/usr/bin/fish
  configure_shell_zsh() { echo "zsh-called"; }
  configure_shell_bash() { echo "bash-called"; }
  run configure_shell
  assert_success
  assert_output --partial "unknown shell 'fish'"
  assert_output --partial "zsh-called"
}
