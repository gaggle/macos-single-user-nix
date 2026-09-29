#!/usr/bin/env bash
# Playbook: happy-path install with zsh as the login shell, then a second reboot
# to prove the LaunchDaemon re-mounts /nix at boot.
# Sourced by bin/nix-test-vm with IP, VM_NAME, etc. exported.
set -euo pipefail

scenario verify/guest-version.sh

scenario install/upload.sh
scenario install/phase1.sh
IP=$(scenario install/reboot.sh)
export IP
scenario install/phase2-3.sh
scenario verify/mount.sh
scenario verify/launchdaemon.sh
SHELL_UNDER_TEST=zsh scenario verify/nix-works.sh
scenario verify/sudo-commands.sh exact

# Reboot once more to prove the LaunchDaemon re-mounts /nix at boot.
IP=$(scenario install/reboot.sh)
export IP
scenario verify/mount.sh
SHELL_UNDER_TEST=zsh scenario verify/nix-works.sh
