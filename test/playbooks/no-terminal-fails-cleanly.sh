#!/usr/bin/env bash
# Playbook (negative): install.sh is piped into bash with no terminal. It must
# refuse before any sudo command. The same machine then installs phase 1 at a
# terminal, so the refusal left nothing in the way.
set -euo pipefail

scenario verify/guest-version.sh

scenario install/upload.sh
scenario verify/no-terminal-refused.sh
scenario install/phase1.sh
scenario verify/sudo-commands.sh prefix
