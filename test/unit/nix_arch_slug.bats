#!/usr/bin/env bats

load test_helper

setup() {
  load_libs
  source_install_sh
}

@test "nix_arch_slug: arm64 → aarch64-darwin" {
  uname() { [[ "$1" == "-m" ]] && echo "arm64" || command uname "$@"; }
  export -f uname
  run nix_arch_slug
  assert_success
  assert_output "aarch64-darwin"
}

@test "nix_arch_slug: x86_64 → x86_64-darwin" {
  uname() { [[ "$1" == "-m" ]] && echo "x86_64" || command uname "$@"; }
  export -f uname
  run nix_arch_slug
  assert_success
  assert_output "x86_64-darwin"
}

@test "nix_arch_slug: anything not arm64 → x86_64-darwin (fallback)" {
  uname() { [[ "$1" == "-m" ]] && echo "i386" || command uname "$@"; }
  export -f uname
  run nix_arch_slug
  assert_success
  assert_output "x86_64-darwin"
}
