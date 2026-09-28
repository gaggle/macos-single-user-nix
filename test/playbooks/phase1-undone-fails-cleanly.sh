#!/usr/bin/env bash
# Playbook (negative): phase 1 ran, user rebooted, /nix appeared — but then
# someone wiped /etc/synthetic.conf. After the *next* reboot /nix vanishes,
# and install.sh must once again refuse phase 2 with a clear error.
#
# This protects against silently re-treating a partially-reverted system as
# resumable.
set -euo pipefail

scenario verify/guest-version.sh

scenario install/upload.sh
scenario install/phase1.sh
IP=$(scenario install/reboot.sh)
export IP

# /nix exists as an empty synthetic mount point after the phase-1 reboot, but
# it is not an APFS volume yet — phase 2 hasn't run. Undo phase 1, reboot
# again, and /nix should not even reappear.

scenario corrupt/delete-synthetic-conf.sh
IP=$(scenario install/reboot.sh)
export IP
scenario verify/phase2-refused.sh
