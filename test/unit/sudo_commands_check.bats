#!/usr/bin/env bats

load test_helper

setup() {
  load_libs
  SCRIPT="${REPO_ROOT}/test/scenarios/verify/sudo-commands.sh"
  export TERMINAL_RUN_DIR="${BATS_TEST_TMPDIR}"
  export EXPECTED_SUDO_COMMANDS="${BATS_TEST_TMPDIR}/expected"
  printf '%s\n' \
    'sudo tee > /etc/synthetic.conf' \
    'sudo chmod 644 /etc/synthetic.conf' \
    'sudo diskutil apfs addVolume <container> APFS Nix -mountpoint /nix' \
    'sudo chown -R <user>:staff /nix' \
    'sudo cp <tmp> /Library/x.plist' > "$EXPECTED_SUDO_COMMANDS"
}

# record <line>...: one invocation's commands, as the driver writes them.
record() {
  { echo "--"; printf '%s\n' "$@"; } >> "${TERMINAL_RUN_DIR}/sudo-commands"
}

@test "exact: passes when the printed commands equal the list after normalizing" {
  record 'sudo tee > /etc/synthetic.conf' 'sudo chmod 644 /etc/synthetic.conf'
  record 'sudo diskutil apfs addVolume disk3 APFS Nix -mountpoint /nix' \
    'sudo chown -R admin:staff /nix' \
    'sudo cp /var/folders/ab/cd/T/tmp.X1y2 /Library/x.plist'
  run "$SCRIPT" exact
  assert_success
  assert_output --partial "5 sudo commands match"
}

@test "exact: fails when the list is cut short" {
  record 'sudo tee > /etc/synthetic.conf' 'sudo chmod 644 /etc/synthetic.conf'
  run "$SCRIPT" exact
  assert_failure
  assert_output --partial "differ"
}

@test "exact: fails when a command differs" {
  record 'sudo tee > /etc/synthetic.conf' 'sudo chmod 600 /etc/synthetic.conf' \
    'sudo diskutil apfs addVolume disk3 APFS Nix -mountpoint /nix' \
    'sudo chown -R admin:staff /nix' 'sudo cp /var/folders/a/tmp.X /Library/x.plist'
  run "$SCRIPT" exact
  assert_failure
  assert_output --partial "chmod 600"
}

@test "prefix: passes for the list's first commands" {
  record 'sudo tee > /etc/synthetic.conf' 'sudo chmod 644 /etc/synthetic.conf'
  record
  run "$SCRIPT" prefix
  assert_success
}

@test "prefix: fails when the commands are out of order" {
  record 'sudo chmod 644 /etc/synthetic.conf' 'sudo tee > /etc/synthetic.conf'
  run "$SCRIPT" prefix
  assert_failure
}

@test "prefix: fails when the commands run past the list" {
  record 'sudo tee > /etc/synthetic.conf' 'sudo chmod 644 /etc/synthetic.conf' \
    'sudo diskutil apfs addVolume disk3 APFS Nix -mountpoint /nix' \
    'sudo chown -R admin:staff /nix' 'sudo cp /var/folders/a/tmp.X /Library/x.plist' \
    'sudo one-more'
  run "$SCRIPT" prefix
  assert_failure
}

@test "prefix: an invocation that starts over is checked alone" {
  record 'sudo tee > /etc/synthetic.conf' 'sudo chmod 644 /etc/synthetic.conf'
  record 'sudo tee > /etc/synthetic.conf' 'sudo chmod 644 /etc/synthetic.conf'
  run "$SCRIPT" prefix
  assert_failure
  run "$SCRIPT" prefix 1 1
  assert_success
  run "$SCRIPT" prefix 2 2
  assert_success
}

@test "fails when no command was printed" {
  record
  run "$SCRIPT" prefix
  assert_failure
  assert_output --partial "no sudo commands"
}
