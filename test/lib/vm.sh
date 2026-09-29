#!/usr/bin/env bash
# tart wrappers + SSH helpers for the VM test harness.
# Sourced by bin/nix-test-vm and by scenarios. Do not execute.
#
# Conventions:
#   - VM_NAME is the tart VM to act on (set by the caller).
#   - VM_USER / VM_PASS default to Cirrus vanilla creds (admin/admin).
#   - SSH key auth is used when SSH_KEY is set, otherwise sshpass + password.
#     The paved snapshot installs ~/.ssh/authorized_keys so downstream clones
#     can drop sshpass.

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

VM_USER="${VM_USER:-admin}"
VM_PASS="${VM_PASS:-admin}"
SSH_KEY="${SSH_KEY:-}"
SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR)

# --- preconditions ----------------------------------------------------------

require_tart() {
  command -v tart >/dev/null || die "tart not on PATH — brew install cirruslabs/cli/tart"
}

require_sshpass() {
  command -v sshpass >/dev/null || die "sshpass not on PATH — brew install hudochenkov/sshpass/sshpass"
}

# --- ssh / scp transport ----------------------------------------------------

_ssh_cmd() {
  if [[ -n "$SSH_KEY" ]]; then
    ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "${SSH_OPTS[@]}" "$@"
  else
    require_sshpass
    sshpass -p "$VM_PASS" ssh "${SSH_OPTS[@]}" "$@"
  fi
}

_scp_cmd() {
  if [[ -n "$SSH_KEY" ]]; then
    scp -i "$SSH_KEY" -o IdentitiesOnly=yes "${SSH_OPTS[@]}" "$@"
  else
    require_sshpass
    sshpass -p "$VM_PASS" scp "${SSH_OPTS[@]}" "$@"
  fi
}

# vm_ssh <ip> <command...>
vm_ssh() {
  local ip="$1"; shift
  _ssh_cmd "$VM_USER@$ip" "$@"
}

# vm_scp_to <src> <ip> <dst>
vm_scp_to() {
  local src="$1" ip="$2" dst="$3"
  _scp_cmd "$src" "$VM_USER@$ip:$dst"
}

# vm_sudo <ip> <command...>
# Echoes the VM password into sudo -S so non-interactive runs work whether
# or not passwordless sudo is configured.
#
# Note: the command runs as `sudo -S <first-word> <rest...>`, so only the
# first word is elevated. Any shell metacharacters in the argument (||, &&,
# ;, pipes) are interpreted by the remote shell BEFORE sudo runs — meaning
# a `vm_sudo "cmd1 || cmd2"` runs cmd2 unprivileged when cmd1 fails. Use
# vm_sudo_sh for that shape.
vm_sudo() {
  local ip="$1"; shift
  vm_ssh "$ip" "echo '$VM_PASS' | sudo -S $*"
}

# vm_sudo_sh <ip> <shell-snippet>
# Runs the entire snippet under `sudo sh -c`, so shell operators (||, &&, ;,
# pipes, redirections) all execute with elevated privileges. Use when chaining
# privileged commands or when the snippet contains shell control flow.
vm_sudo_sh() {
  local ip="$1"; shift
  local script="$*"
  local escaped=${script//\'/\'\\\'\'}
  vm_ssh "$ip" "echo '$VM_PASS' | sudo -S sh -c '$escaped'"
}

# --- tart lifecycle ---------------------------------------------------------

vm_ip() {
  tart ip "$1" 2>/dev/null
}

# vm_clone <base> <name>
vm_clone() {
  local base="$1" name="$2"
  log "cloning $base → $name"
  tart clone "$base" "$name"
}

# vm_start <name>   (headless, backgrounded, disowned)
vm_start() {
  local name="$1"
  log "starting VM $name (headless)"
  tart run --no-graphics "$name" >/dev/null 2>&1 &
  disown
}

# vm_stop <name>
vm_stop() {
  local name="$1"
  tart stop "$name" >/dev/null 2>&1 || true
}

# vm_delete <name>
vm_delete() {
  local name="$1"
  tart delete "$name" >/dev/null 2>&1 || true
}

# vm_exists <name>
vm_exists() {
  tart list --format json 2>/dev/null | grep -Eq "\"Name\"[[:space:]]*:[[:space:]]*\"$1\""
}

# vm_wait_ssh <name> [timeout_seconds]
# Echoes the IP on success.
vm_wait_ssh() {
  local name="$1" timeout="${2:-240}" elapsed=0 ip=""
  while (( elapsed < timeout )); do
    ip=$(vm_ip "$name" || true)
    if [[ -n "$ip" ]] && _ssh_cmd -o ConnectTimeout=3 "$VM_USER@$ip" true 2>/dev/null; then
      echo "$ip"
      return 0
    fi
    sleep 3
    elapsed=$(( elapsed + 3 ))
  done
  die "timed out waiting for SSH on $name (${timeout}s)"
}

# scenario <path-relative-to-test-dir>
# Runs a scenario script with the current env (IP, VM_NAME, etc). Scenarios
# inherit set -euo pipefail individually; we just exec them.
scenario() {
  local rel="$1"; shift || true
  local path="${TEST_DIR:?TEST_DIR not exported}/scenarios/$rel"
  [[ -f "$path" ]] || die "scenario not found: $rel"
  log "── scenario: $rel"
  bash "$path" "$@"
}

# vm_reboot <ip> <name>
# Triggers reboot, waits for SSH to come back. Echoes the new IP.
vm_reboot() {
  local ip="$1" name="$2"
  log "rebooting $name"
  vm_sudo "$ip" reboot || true
  sleep 10
  vm_wait_ssh "$name" 300
}

# drive_installer <ip> [expected-exit]
# Runs ~/install.sh in a terminal inside the guest via test/lib/drive-installer.exp,
# which answers only what it has matched and checks the sudo counts. Appends
# the invocation's counts to $TERMINAL_RUN_DIR/results, its sudo commands to
# $TERMINAL_RUN_DIR/sudo-commands and its screen output to
# $TERMINAL_RUN_DIR/transcript.
drive_installer() {
  local ip="$1" expected_exit="${2:-0}"
  : "${TERMINAL_RUN_DIR:?TERMINAL_RUN_DIR not set}"
  [[ -n "$SSH_KEY" ]] || die "the installer terminal needs SSH_KEY"
  command -v expect >/dev/null || die "expect not on PATH — run inside devenv shell"
  : > "$TERMINAL_RUN_DIR/transcript"
  VM_USER="$VM_USER" VM_PASS="$VM_PASS" SSH_KEY="$SSH_KEY" \
    expect -f "$(repo_root)/test/lib/drive-installer.exp" -- \
      "$ip" "$expected_exit" "$TERMINAL_RUN_DIR/transcript" "$TERMINAL_RUN_DIR/results" \
      "$TERMINAL_RUN_DIR/sudo-commands" \
      "${SSH_OPTS[@]}"
}
