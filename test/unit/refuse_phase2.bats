#!/usr/bin/env bats

load test_helper

setup() {
  load_libs
  source_install_sh
}

@test "refuse_phase2_without_nix_dir: dies with the reboot advice when /nix is absent" {
  nix_dir_present() { return 1; }

  run refuse_phase2_without_nix_dir
  assert_failure
  assert_output --partial "/nix does not exist"
  assert_output --partial "Did you reboot"
}

@test "refuse_phase2_without_nix_dir: passes when /nix is present" {
  nix_dir_present() { return 0; }

  run refuse_phase2_without_nix_dir
  assert_success
}

@test "main: a skipped reboot is refused before the password is asked" {
  preflight()            { :; }
  resolve_nix_version()  { NIX_VERSION=0; NIX_VERSION_SOURCE=test; }
  print_status()         { :; }
  phase1_done()          { return 0; }
  phase2_done()          { return 1; }
  phase3_done()          { return 1; }
  nix_dir_present()      { return 1; }
  print_sudo_prompt()    { echo "PROMPTED"; }
  sudo_warmup()          { echo "WARMED"; }

  run main
  assert_failure
  assert_output --partial "/nix does not exist"
  refute_output --partial "PROMPTED"
  refute_output --partial "WARMED"
}
