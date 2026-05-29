#!/usr/bin/env bash
# Playbook: happy-path install on the VM's default shell (zsh).
# Sourced by bin/nix-test-vm with IP, VM_NAME, etc. exported.
set -euo pipefail

scenario install/upload.sh
scenario install/phase1.sh
IP=$(scenario install/reboot.sh)
export IP
scenario install/phase2-3.sh
scenario verify/mount.sh
scenario verify/launchdaemon.sh
SHELL_UNDER_TEST=zsh scenario verify/nix-works.sh

# Reboot once more to prove the LaunchDaemon re-mounts /nix at boot.
IP=$(scenario install/reboot.sh)
export IP
scenario verify/mount.sh
SHELL_UNDER_TEST=zsh scenario verify/nix-works.sh
