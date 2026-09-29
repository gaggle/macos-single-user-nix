#!/usr/bin/env bash
# Playbook (negative): phase 1 ran, the user rebooted and /nix appeared, then
# someone wiped /etc/synthetic.conf. Re-running install.sh must treat phase 1
# as not done: write the entry again, print the reboot notice, exit 0, and
# create no volume.
#
# This protects against silently treating a partially-reverted system as
# resumable.
set -euo pipefail

scenario verify/guest-version.sh

scenario install/upload.sh
scenario install/phase1.sh
IP=$(scenario install/reboot.sh)
export IP

scenario corrupt/delete-synthetic-conf.sh
scenario verify/phase1-redone.sh
# The second run starts over from a fresh state, so each run is checked alone.
scenario verify/sudo-commands.sh prefix 1 1
scenario verify/sudo-commands.sh prefix 2 2
