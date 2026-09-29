#!/usr/bin/env bash
# Single-user Nix installer for macOS.
#
# Resumable: detects which phase has already completed and picks up where the
# previous run left off. Designed to be run twice — once before reboot (to
# declare /nix in synthetic.conf), once after.
#
# Usage:
#   ./install.sh                       # detect latest Nix
#   NIX_VERSION=2.34.6 ./install.sh    # pin a specific version
#
# Phases:
#   1. /etc/synthetic.conf declares /nix   → reboot required
#   2. APFS "Nix Store" volume + fstab + LaunchDaemon (org.nixos.darwin-store)
#   3. Nix binaries + nix.conf + shell profile         (no sudo in this phase)
set -euo pipefail

# Status glyphs.
G_DONE="[✓]"
G_TODO="[ ]"
G_NOW="[→]"
G_SKIP="[-]"

# Cross-phase state (mutated by the phase functions, read by print_summary).
SUDO_USES=0
PERFORMED=()

# Test seam: BATS unit tests override this to inject a mock or disable sudo
# entirely. Real runs use the default. Underscore + project prefix marks it
# as internal — do not set this in normal usage.
: "${_SUN_SUDO=sudo}"

# ─── Output helpers ──────────────────────────────────────────────────────────

log()  { echo "$*" >&2; }
warn() { echo "warning: $*" >&2; }
die()  { echo "ERROR: $*" >&2; exit 1; }

# ─── Sudo discipline ─────────────────────────────────────────────────────────
# Every sudo invocation goes through sudo_run / sudo_write, which echo the
# reason and the exact command (and, for writes, the content) before running.
# The user can audit every privileged action in their terminal scrollback —
# no hidden chains, no opaque mutations.

# Whether the installer was started from a terminal, decided once here. It
# cannot be asked later: sudo_write reads its content from a pipe, so stdin is
# no longer the terminal by the time it pauses. BATS tests override it.
if [[ -z "${_SUN_INTERACTIVE:-}" ]]; then
  if [[ -t 0 ]]; then _SUN_INTERACTIVE=1; else _SUN_INTERACTIVE=0; fi
fi

# Test seam: where the pause reads Enter from.
: "${_SUN_TTY=/dev/tty}"

sudo_confirm() {
  # Pause so the user can read the upcoming sudo call and abort if unexpected.
  # Skipped in non-interactive contexts (piped input, CI, SSH without -t).
  [[ "$_SUN_INTERACTIVE" == 1 ]] || return 0
  printf '%s' "  [sudo] Press Enter to run, or Ctrl-C to abort..." >&2
  read -r -s < "$_SUN_TTY"
  echo ""
}

# Predicates split out so BATS tests can override them.
_sudo_passwordless()    { $_SUN_SUDO -n true 2>/dev/null; }
_have_controlling_tty() { true </dev/tty 2>/dev/null; }

# Ensure sudo will work for the rest of the run, or fail loudly now.
#   1. NOPASSWD already covers us (test VMs, CI) → done, no prompt needed.
#   2. We have /dev/tty → sudo can prompt. Warm the credential cache.
#   3. Neither → fail. sudo would otherwise hang or fail cryptically halfway
#      through. This is the curl|bash-under-nohup / ssh-without-pty case.
sudo_warmup() {
  _sudo_passwordless && return 0
  _have_controlling_tty || die "sudo needs a password but there is no controlling terminal.
       Re-run from an interactive shell, or configure passwordless sudo
       for this user (NOPASSWD in /etc/sudoers.d/)."
  $_SUN_SUDO -v
}

sudo_run() {
  local reason="$1"; shift
  echo "  [sudo] $reason"
  echo "  [sudo]   \$ sudo $*"
  sudo_confirm
  $_SUN_SUDO "$@"
  SUDO_USES=$(( SUDO_USES + 1 ))
}

# For shell-redirected writes (cannot be done as `sudo cmd`).
sudo_write() {
  local reason="$1" path="$2" mode="$3"  # mode: > or >>
  local content
  content=$(cat)
  echo "  [sudo] $reason"
  echo "  [sudo]   \$ sudo tee $mode $path"
  echo "  [sudo]   ─── content ───"
  printf '%s' "$content" | sed "s#^#  [sudo]   │ #"
  echo "  [sudo]   ─── end ───"
  sudo_confirm
  # `$(cat)` strips trailing newlines; restore one so files like
  # /etc/synthetic.conf (whose parser requires newline-terminated lines)
  # don't end up truncated.
  if [[ "$mode" == ">>" ]]; then
    printf '%s\n' "$content" | $_SUN_SUDO tee -a "$path" >/dev/null
  else
    printf '%s\n' "$content" | $_SUN_SUDO tee "$path" >/dev/null
  fi
  SUDO_USES=$(( SUDO_USES + 1 ))
}

# ─── Preconditions ───────────────────────────────────────────────────────────

preflight() {
  [[ "$(uname -s)" == "Darwin" ]] || die "macOS only (uname -s = $(uname -s))"
  [[ $EUID -ne 0 ]]                || die "do not run as root — script will sudo when needed"
  command -v curl     >/dev/null   || die "curl is required"
  command -v diskutil >/dev/null   || die "diskutil is required (you're not on macOS?)"
}

# ─── Nix version resolution ──────────────────────────────────────────────────

detect_latest_nix() {
  # Query the S3 bucket directly (releases.nixos.org is a jQuery browser app
  # that returns HTML, not the raw bucket listing we need).
  curl -fsSL 'https://nix-releases.s3.amazonaws.com/?prefix=nix/&delimiter=/' 2>/dev/null \
    | grep -oE 'nix/nix-[0-9]+\.[0-9]+\.[0-9]+/' \
    | sed 's|nix/nix-||;s|/$||' \
    | sort -V \
    | tail -1
}

resolve_nix_version() {
  if [[ -n "${NIX_VERSION:-}" ]]; then
    NIX_VERSION_SOURCE="pinned via NIX_VERSION env var"
    return
  fi
  log "detecting latest Nix release…"
  NIX_VERSION=$(detect_latest_nix || true)
  if [[ -z "$NIX_VERSION" ]]; then
    die "could not detect latest Nix release from releases.nixos.org.
       Check your network, or pin a version explicitly:
         NIX_VERSION=2.34.6 bash install.sh"
  fi
  NIX_VERSION_SOURCE="latest from releases.nixos.org"
}

# ─── State detection ─────────────────────────────────────────────────────────
# These predicates are pure: they only inspect the system. They drive both
# the resumability logic and the status banner — one source of truth.

phase1_done()     { local f="${1:-/etc/synthetic.conf}"; [[ -f "$f" ]] && grep -qE '^nix([[:space:]]|$)' "$f"; }
nix_dir_present() { [[ -d /nix ]]; }
phase2_done()     { diskutil info "Nix Store" >/dev/null 2>&1 && mount | grep -qE ' /nix '; }
phase3_done()     { [[ -x "$HOME/.nix-profile/bin/nix" ]]; }

phase_glyph() {
  case "$1" in
    1) phase1_done && echo "$G_DONE" || echo "$G_TODO" ;;
    2) phase2_done && echo "$G_DONE" || echo "$G_TODO" ;;
    3) phase3_done && echo "$G_DONE" || echo "$G_TODO" ;;
  esac
}

print_status() {
  echo ""
  echo "This installer runs in 3 phases:"
  echo "  $(phase_glyph 1) Phase 1: declare /nix  (requires sudo + reboot)"
  echo "  $(phase_glyph 2) Phase 2: mount \"Nix Store\" volume via LaunchDaemon  (requires sudo)"
  echo "  $(phase_glyph 3) Phase 3: install Nix $NIX_VERSION to ~/.nix-profile"
  echo ""
}

print_sudo_prompt() {
  echo "Every sudo is echoed and then paused, so you can confirm to continue — no hidden privileges"
  echo ""
  echo "Next, you'll be prompted for your password once  (sudo -v warm-up)"
}

# Pause for the user to read what's about to happen.
# Skipped automatically in non-interactive contexts (piped input, CI, SSH
# without -t) — stdin not being a TTY is the signal.
wait_for_confirmation() {
  [[ -t 0 ]] || return 0
  read -r -s -p "Press Enter to continue, or Ctrl-C to abort..." < /dev/tty
  echo ""
}

# ─── Phase 1 ─────────────────────────────────────────────────────────────────

write_synthetic_conf() {
  if [[ -f /etc/synthetic.conf ]]; then
    sudo_write "append 'nix' to existing /etc/synthetic.conf" /etc/synthetic.conf '>>' <<< "nix"
  else
    sudo_write "create /etc/synthetic.conf with 'nix' entry" /etc/synthetic.conf '>' <<< "nix"
  fi
  sudo_run "ensure /etc/synthetic.conf is world-readable" chmod 644 /etc/synthetic.conf
}

phase1_reboot_notice() {
  cat <<EOF

Phase 1 complete.

  REBOOT REQUIRED.

  macOS only reads /etc/synthetic.conf at boot, so /nix will not exist
  until you reboot. After rebooting, run this script again to continue
  with phase 2.

      sudo reboot
      # then, after login, re-run the same command you used to start —
      # e.g. either of:
      bash install.sh
      curl -fsSL https://raw.githubusercontent.com/gaggle/macos-single-user-nix/main/install.sh | bash

EOF
}

do_phase1() {
  if phase1_done; then
    log "$G_SKIP Phase 1/3: /etc/synthetic.conf already declares /nix — skipping"
    return
  fi
  echo ""
  log "$G_NOW Phase 1/3: declaring /nix in /etc/synthetic.conf"
  write_synthetic_conf
  PERFORMED+=("Phase 1: synthetic.conf written")
  phase1_reboot_notice
  exit 0
}

# ─── Phase 2 ─────────────────────────────────────────────────────────────────

find_apfs_container() {
  local container
  container=$(diskutil list | awk '/Apple_APFS Container/ { for (i = 1; i <= NF; i++) if ($i == "Container") { print $(i + 1); exit } }')
  [[ -n "$container" ]] || { diskutil list >&2; die "could not find APFS container"; }
  echo "$container"
}

nix_volume_uuid() {
  local uuid
  uuid=$(diskutil info "Nix Store" | awk '/Volume UUID/{print $3}')
  [[ -n "$uuid" ]] || { diskutil info "Nix Store" >&2; die "could not determine Nix Store UUID"; }
  echo "$uuid"
}

create_nix_volume() {
  local container="$1"
  if diskutil info "Nix Store" >/dev/null 2>&1; then
    log "  $G_SKIP volume \"Nix Store\" already exists — skipping create"
    return
  fi
  sudo_run "create APFS volume \"Nix Store\" on $container, mount at /nix" \
    diskutil apfs addVolume "$container" "Case-sensitive APFS" "Nix Store" -mountpoint /nix
}

take_nix_ownership() {
  sudo_run "give your user ownership of /nix (single-user mode)" \
    chown -R "$USER:staff" /nix
  log "  creating Nix directory structure under /nix"
  mkdir -p /nix/store /nix/var/nix/db
  mkdir -p /nix/var/nix/profiles/per-user/"$USER"
  mkdir -p /nix/var/nix/gcroots/per-user/"$USER"
}

write_fstab_entry() {
  local uuid="$1"
  if grep -q "Nix Store\|$uuid" /etc/fstab 2>/dev/null; then
    log "  $G_SKIP /etc/fstab already has a Nix Store entry — skipping"
    return
  fi
  # Content comes by here-string, not a pipe: the last stage of a pipeline runs
  # in a subshell, which would lose the SUDO_USES increment.
  sudo_write "record Nix Store in /etc/fstab (noauto: LaunchDaemon will mount it)" /etc/fstab '>>' \
    <<< "UUID=$uuid /nix apfs rw,noauto,nobrowse,nosuid,noatime,owners"
}

# Where the named mount helper lives. It CANNOT live in the user's home or in
# /nix (both user-writable in single-user mode): a root LaunchDaemon that execs
# a user-writable script is a local privilege-escalation hole. /usr/local/libexec
# is root-owned on Apple Silicon and created root-owned here if missing.
NIX_STORE_MOUNTER=/usr/local/libexec/mount-nix-store

install_launchdaemon() {
  local uuid="$1"
  local tmp

  # 1. Giving the daemon a real named executable in the plist is what
  #    makes System Settings > Login Items show a legible "mount-nix-store"
  #    instead of a bare, anonymous "sh".
  sudo_run "create $(dirname "$NIX_STORE_MOUNTER") for the Nix mount helper" \
    mkdir -p "$(dirname "$NIX_STORE_MOUNTER")"
  sudo_write "install named Nix Store mount helper (legible Login Items name)" "$NIX_STORE_MOUNTER" '>' <<EOF
#!/bin/sh
# Mounts the "Nix Store" APFS volume at /nix. Installed by macos-single-user-nix.
/bin/wait4path /nix && /usr/sbin/diskutil mount $uuid
EOF
  sudo_run "set mount helper ownership to root:wheel" \
    chown root:wheel "$NIX_STORE_MOUNTER"
  sudo_run "make mount helper executable (0755)" \
    chmod 755 "$NIX_STORE_MOUNTER"

  # 2. LaunchDaemon plist that points at the named helper.
  tmp=$(mktemp)
  cat > "$tmp" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>org.nixos.darwin-store</string>
  <key>RunAtLoad</key>
  <true/>
  <key>ProgramArguments</key>
  <array>
    <string>$NIX_STORE_MOUNTER</string>
  </array>
  <key>StandardOutPath</key>
  <string>/var/log/org.nixos.darwin-store.log</string>
  <key>StandardErrorPath</key>
  <string>/var/log/org.nixos.darwin-store.log</string>
</dict>
</plist>
EOF
  sudo_run "install LaunchDaemon plist (mounts /nix at every boot)" \
    cp "$tmp" /Library/LaunchDaemons/org.nixos.darwin-store.plist
  rm "$tmp"
  sudo_run "set LaunchDaemon plist ownership to root:wheel" \
    chown root:wheel /Library/LaunchDaemons/org.nixos.darwin-store.plist
  sudo_run "set LaunchDaemon plist mode to 0644" \
    chmod 644 /Library/LaunchDaemons/org.nixos.darwin-store.plist
  sudo_run "load the LaunchDaemon" \
    launchctl load -w /Library/LaunchDaemons/org.nixos.darwin-store.plist || true
}

# Phase 2 needs /nix, which macOS creates at boot once synthetic.conf declares
# it. Called before the password is asked, so a skipped reboot is reported first.
refuse_phase2_without_nix_dir() {
  nix_dir_present || die "/nix does not exist even though synthetic.conf declares it.
       Did you reboot since editing /etc/synthetic.conf? If so, check:
         cat /etc/synthetic.conf
       and reboot once more."
}

do_phase2() {
  if phase2_done; then
    log "$G_SKIP Phase 2/3: APFS volume already created and mounted — skipping"
    return
  fi
  refuse_phase2_without_nix_dir

  echo ""
  log "$G_NOW Phase 2/3: creating APFS Nix Store volume + LaunchDaemon"

  local container uuid
  container=$(find_apfs_container)
  log "  using APFS container: $container"
  create_nix_volume "$container"
  take_nix_ownership
  uuid=$(nix_volume_uuid)
  log "  Nix Store UUID: $uuid"
  write_fstab_entry "$uuid"
  install_launchdaemon "$uuid"

  PERFORMED+=("Phase 2: APFS volume + LaunchDaemon configured")
}

# ─── Phase 3 ─────────────────────────────────────────────────────────────────
# No sudo in this phase — Nix is owned by the user in single-user mode.

nix_arch_slug() {
  [[ "$(uname -m)" == "arm64" ]] && echo "aarch64-darwin" || echo "x86_64-darwin"
}

download_and_extract_nix() {
  local work="$1" arch="$2" tarball
  tarball="nix-${NIX_VERSION}-${arch}"
  log "  downloading $tarball.tar.xz from releases.nixos.org"
  (cd "$work" && curl -fLO "https://releases.nixos.org/nix/nix-${NIX_VERSION}/${tarball}.tar.xz")
  (cd "$work" && tar xf "${tarball}.tar.xz")
  local extracted="$work/$tarball"
  [[ -d "$extracted" ]] || die "extracted tarball not found at $extracted"
  echo "$extracted"
}

populate_nix_store() {
  local extracted="$1"
  log "  copying store paths into /nix/store"
  cp -a "$extracted/store/." /nix/store/
}

install_nix_to_profile() {
  local extracted="$1" nix_pkg
  log "  registering store paths in the Nix database"
  nix_pkg=$(find /nix/store -maxdepth 1 -name "*-nix-${NIX_VERSION}" -type d | head -1)
  [[ -n "$nix_pkg" ]] || die "nix-${NIX_VERSION} package not found in /nix/store after extraction"
  "$nix_pkg/bin/nix-store" --load-db < "$extracted/.reginfo"
  log "  installing Nix into your user profile (~/.nix-profile)"
  "$nix_pkg/bin/nix-env" -i "$nix_pkg"
}

write_nix_conf() {
  if [[ -f "$HOME/.config/nix/nix.conf" ]]; then
    log "  $G_SKIP ~/.config/nix/nix.conf already exists — leaving it alone"
    return
  fi
  log "  writing ~/.config/nix/nix.conf (experimental-features, accept-flake-config)"
  mkdir -p "$HOME/.config/nix"
  cat > "$HOME/.config/nix/nix.conf" <<'EOF'
experimental-features = nix-command flakes
accept-flake-config = true
ssl-cert-file = /etc/ssl/cert.pem
EOF
}

install_cacert() {
  log "  installing cacert (HTTPS certificates for Nix)"
  export NIX_SSL_CERT_FILE=/etc/ssl/cert.pem
  nix profile add nixpkgs#cacert
}

# ─── Shell profile dispatch ──────────────────────────────────────────────────
#
# Single-user Nix needs the user's interactive shells to source
# ~/.nix-profile/etc/profile.d/nix.sh — otherwise `nix` won't be on
# PATH in new shells.
#
# Each supported shell has a configure_shell_<name> function that knows (a)
# which rc file to append to and (b) what syntax to emit. configure_shell
# dispatches on the current login shell ($SHELL).
#
# Idempotency: we grep for the *functional* source path
# (NIX_SH_SOURCE_PATH) inside the target rc file. If
# the user already sources nix.sh — whether via our block, a previous
# install, a dotfiles repo, or oh-my-zsh — we leave them alone.
#
# Adding a shell: write a configure_shell_<name>, add a case arm.
#
# Testing: the VM harness exercises one shell at a time by setting $SHELL
# inside the VM and re-running install.sh. The unit-test angle (sourcing
# install.sh and calling configure_shell_* directly) is documented in
# test/README.md.

# What we look for to decide "this rc already sources Nix."
NIX_SH_SOURCE_PATH=".nix-profile/etc/profile.d/nix.sh"

# Provenance comment prepended to the block we write. Informational only.
SHELL_PREAMBLE='# Nix (single-user install)'

rc_already_sources() {
  local rc="$1" needle="$2"
  [[ -f "$rc" ]] && grep -qF "$needle" "$rc"
}

configure_shell_zsh() {
  local rc="${1:-$HOME/.zshenv}"
  if rc_already_sources "$rc" "$NIX_SH_SOURCE_PATH"; then
    log "  $G_SKIP $rc already sources nix.sh — leaving it alone"
    return
  fi
  log "  appending nix profile sourcing to $rc"
  mkdir -p "$(dirname "$rc")"
  {
    echo
    echo "$SHELL_PREAMBLE"
    cat <<'EOF'
if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi
EOF
  } >> "$rc"
}

configure_shell_bash() {
  # On macOS, Terminal.app launches bash as a login shell → ~/.bash_profile.
  local rc="${1:-$HOME/.bash_profile}"
  if rc_already_sources "$rc" "$NIX_SH_SOURCE_PATH"; then
    log "  $G_SKIP $rc already sources nix.sh — leaving it alone"
    return
  fi
  log "  appending nix profile sourcing to $rc"
  mkdir -p "$(dirname "$rc")"
  {
    echo
    echo "$SHELL_PREAMBLE"
    cat <<'EOF'
if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi
EOF
  } >> "$rc"
}

configure_shell() {
  local shell_name
  shell_name=$(basename "${SHELL:-/bin/zsh}")
  case "$shell_name" in
    zsh)  configure_shell_zsh  ;;
    bash) configure_shell_bash ;;
    *)
      warn "unknown shell '$shell_name' — falling back to zsh"
      warn "to configure another shell manually, source ~/.nix-profile/etc/profile.d/nix.sh from your rc"
      configure_shell_zsh
      ;;
  esac
}

do_phase3() {
  if phase3_done; then
    log "$G_SKIP Phase 3/3: Nix already installed at ~/.nix-profile/bin/nix — skipping"
    # shellcheck disable=SC1091
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
    return
  fi
  echo ""
  log "$G_NOW Phase 3/3: installing Nix $NIX_VERSION (no sudo from here)"

  local work arch extracted
  work=$(mktemp -d)
  # shellcheck disable=SC2064  # intentional: expand $work now so the path is baked in
  trap "rm -rf '$work'" EXIT
  arch=$(nix_arch_slug)
  extracted=$(download_and_extract_nix "$work" "$arch")
  populate_nix_store "$extracted"
  install_nix_to_profile "$extracted"

  # shellcheck disable=SC1091
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  log "  $G_DONE nix --version: $(nix --version)"

  write_nix_conf
  install_cacert
  configure_shell

  PERFORMED+=("Phase 3: Nix $NIX_VERSION installed for $(basename "${SHELL:-/bin/zsh}")")
}

# ─── Verification + summary ──────────────────────────────────────────────────

verify() {
  echo ""
  log "verification:"
  log "  nix --version: $(nix --version)"
  log "  /nix mount:    $(mount | grep -E ' /nix ' || echo MISSING)"
  log "  querying public binary cache:"
  nix store info --store https://cache.nixos.org
}

print_summary() {
  echo ""
  log "Final status:"
  print_status
  log "Operations performed this run:"
  if (( ${#PERFORMED[@]} == 0 )); then
    log "  (none — everything was already in place)"
  else
    local item
    for item in "${PERFORMED[@]}"; do
      log "  $G_DONE $item"
    done
  fi
  log "Privileged operations: $SUDO_USES sudo call(s) executed."
  log ""
  log "done — single-user Nix is installed."
  log "open a new shell (or re-source your shell rc) to pick up the PATH change."
}

# ─── main ────────────────────────────────────────────────────────────────────

main() {
  preflight
  echo "macos-single-user-nix installer"
  resolve_nix_version
  echo "Nix version: $NIX_VERSION  ($NIX_VERSION_SOURCE)"
  print_status

  if phase1_done && phase2_done && phase3_done; then
    echo "All phases already complete — nothing to do."
    echo "Open a new shell and try: nix --version"
    return 0
  fi

  if phase1_done && ! phase2_done; then
    refuse_phase2_without_nix_dir
  fi

  print_sudo_prompt
  echo ""
  sudo_warmup

  do_phase1   # may exit 0 with a reboot notice
  do_phase2
  do_phase3
  verify
  print_summary
}

# Run main only when executed directly. When sourced (e.g. by a unit-test
# harness that wants to call functions), the library functions are loaded
# but no work happens.
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
  main "$@"
fi
