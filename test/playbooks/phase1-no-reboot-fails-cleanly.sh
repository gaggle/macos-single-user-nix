#!/usr/bin/env bash
# Playbook (negative): phase 1 wrote synthetic.conf but the user skipped the
# reboot. Re-running install.sh must refuse phase 2 with a clear error rather
# than silently barreling on.
set -euo pipefail

scenario verify/guest-version.sh

scenario install/upload.sh
scenario install/phase1.sh
# Deliberately skip install/reboot.sh — /nix does not exist yet.
scenario verify/phase2-refused.sh
scenario verify/sudo-commands.sh prefix
