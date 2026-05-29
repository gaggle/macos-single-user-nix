#!/usr/bin/env bash
# Playbook (negative): after a clean full install, blow away the LaunchDaemon
# and unmount /nix, then reboot. /nix must come back unmounted (proving the
# LaunchDaemon is what mounts it) and nix --version must fail in a fresh shell.
#
# This is the regression test the inline-verify in install.sh used to attempt
# (with two extra sudo unmount + kickstart calls) — moved here where it belongs.
set -euo pipefail

scenario install/upload.sh
scenario install/phase1.sh
IP=$(scenario install/reboot.sh)
export IP
scenario install/phase2-3.sh

# Confirm the system is healthy before we break it.
scenario verify/mount.sh
scenario verify/launchdaemon.sh

# Now sabotage the daemon and reboot.
scenario corrupt/remove-launchdaemon.sh
IP=$(scenario install/reboot.sh)
export IP

# /nix should NOT be mounted now.
if vm_ssh "$IP" "mount | grep -qE ' /nix '"; then
  die "expected /nix to be unmounted after the LaunchDaemon was removed"
fi
log "  → /nix correctly unmounted after LaunchDaemon removal"

# nix --version should NOT work in a fresh shell (binary's still on disk but
# the store is unmounted; nix needs /nix/store).
if vm_ssh "$IP" "zsh -l -c 'nix --version >/dev/null 2>&1'"; then
  die "expected nix --version to fail without /nix mounted"
fi
log "  → nix correctly unavailable when /nix is unmounted"
