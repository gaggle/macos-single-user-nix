#!/usr/bin/env bash
# Playbook: happy-path install with bash as the login shell.
# Sourced by bin/nix-test-vm with IP, VM_NAME, etc. exported.
set -euo pipefail

scenario verify/guest-version.sh

scenario setup/switch-to-bash.sh

scenario install/upload.sh
scenario install/phase1.sh
IP=$(scenario install/reboot.sh)
export IP
scenario install/phase2-3.sh
scenario verify/mount.sh
scenario verify/launchdaemon.sh
SHELL_UNDER_TEST=bash scenario verify/nix-works.sh
scenario verify/sudo-commands.sh exact
