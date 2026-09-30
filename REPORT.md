# Run history

A passing run means: a fresh macOS VM, the installer run through its three phases across
a real reboot, answered as a person would. The password is typed at sudo's own prompt and
Enter is pressed at every pause the installer prints.

One row per macOS and Nix combination, showing its newest run, whether it passed or failed.

| Result | macOS | Nix | Commit | Date |
|---|---|---|---|---|
| ✅ pass | 26.6.2 | 2.35.2 | `4ffaa17` | 2026-09-30 |

To reproduce a run, see [test/README.md](test/README.md).
[`test/runs.jsonl`](test/runs.jsonl) is the source of the table; `test/bin/build-report` builds this page.

## Terminal output

### macOS 26.6.2, Nix 2.35.2, commit `4ffaa17`

<details>
<summary>happy-bash: pass</summary>

~~~text
[vm-test] playbook: happy-bash → nix-test-happy-bash-45782 (clone of nix-paved-tahoe)
[vm-test] cloning nix-paved-tahoe → nix-test-happy-bash-45782
[vm-test] starting VM nix-test-happy-bash-45782 (headless)
[vm-test] VM up at 192.168.64.106 — running playbook
[vm-test] ── scenario: setup/remove-passwordless-sudo.sh
[vm-test] removing every passwordless sudoers entry from this clone
[vm-test]   → sudo now needs a password
[vm-test] ── scenario: verify/guest-version.sh
[vm-test] asserting: guest macOS build starts with 26
[vm-test]   → macOS 26.6.2
[vm-test] ── scenario: setup/switch-to-bash.sh
[vm-test] switching login shell of admin to /bin/bash
Password:Changing shell for admin.
[vm-test]   → fresh login $0 = bash
[vm-test] ── scenario: install/upload.sh
[vm-test] uploading install.sh → admin@192.168.64.106:~/install.sh
[vm-test] ── scenario: install/phase1.sh
[vm-test] running install.sh (phase 1) on 192.168.64.106
TERMINAL:yes
macos-single-user-nix installer
detecting latest Nix release…
Nix version: 2.35.2  (latest from releases.nixos.org)

This installer runs in 3 phases:
  [ ] Phase 1: declare /nix  (requires sudo + reboot)
  [ ] Phase 2: mount "Nix Store" volume via LaunchDaemon  (requires sudo)
  [ ] Phase 3: install Nix 2.35.2 to ~/.nix-profile

Every sudo is echoed and then paused, so you can confirm to continue — no hidden privileges

Next, you'll be prompted for your password once  (sudo -v warm-up)

Password:

[→] Phase 1/3: declaring /nix in /etc/synthetic.conf
  [sudo] create /etc/synthetic.conf with 'nix' entry
  [sudo]   $ sudo tee > /etc/synthetic.conf
  [sudo]   ─── content ───
  [sudo]   │ nix  [sudo]   ─── end ───
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] ensure /etc/synthetic.conf is world-readable
  [sudo]   $ sudo chmod 644 /etc/synthetic.conf
  [sudo] Press Enter to run, or Ctrl-C to abort...

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


[driver] sudo_lines=2 pauses=2 reported=none password_prompts=1 exit=0 terminal=yes
[vm-test] ── scenario: install/reboot.sh
[vm-test] rebooting nix-test-happy-bash-45782
Password:Connection to 192.168.64.106 closed by remote host.
[vm-test] ── scenario: install/phase2-3.sh
[vm-test] running install.sh (phases 2 + 3) on 192.168.64.106
TERMINAL:yes
macos-single-user-nix installer
detecting latest Nix release…
Nix version: 2.35.2  (latest from releases.nixos.org)

This installer runs in 3 phases:
  [✓] Phase 1: declare /nix  (requires sudo + reboot)
  [ ] Phase 2: mount "Nix Store" volume via LaunchDaemon  (requires sudo)
  [ ] Phase 3: install Nix 2.35.2 to ~/.nix-profile

Every sudo is echoed and then paused, so you can confirm to continue — no hidden privileges

Next, you'll be prompted for your password once  (sudo -v warm-up)

Password:
[-] Phase 1/3: /etc/synthetic.conf already declares /nix — skipping

[→] Phase 2/3: creating APFS Nix Store volume + LaunchDaemon
  using APFS container: disk3
  [sudo] create APFS volume "Nix Store" on disk3, mount at /nix
  [sudo]   $ sudo diskutil apfs addVolume disk3 Case-sensitive APFS Nix Store -mountpoint /nix
  [sudo] Press Enter to run, or Ctrl-C to abort...
Will export new APFS (Case-sensitive) Volume "Nix Store" from APFS Container Reference disk3
Started APFS operation on disk3
Preparing to add APFS Volume to APFS Container disk3
Creating APFS Volume
Created new APFS Volume disk3s7
Mounting disk
Setting volume permissions
Disk from APFS operation: disk3s7
Finished APFS operation on disk3
  [sudo] give your user ownership of /nix (single-user mode)
  [sudo]   $ sudo chown -R admin:staff /nix
  [sudo] Press Enter to run, or Ctrl-C to abort...
  creating Nix directory structure under /nix
  Nix Store UUID: 8188B871-A175-4E8A-BD39-D44F15326DF3
  [sudo] record Nix Store in /etc/fstab (noauto: LaunchDaemon will mount it)
  [sudo]   $ sudo tee >> /etc/fstab
  [sudo]   ─── content ───
  [sudo]   │ UUID=8188B871-A175-4E8A-BD39-D44F15326DF3 /nix apfs rw,noauto,nobrowse,nosuid,noatime,owners  [sudo]   ─── end ───
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] create /usr/local/libexec for the Nix mount helper
  [sudo]   $ sudo mkdir -p /usr/local/libexec
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] install named Nix Store mount helper (legible Login Items name)
  [sudo]   $ sudo tee > /usr/local/libexec/mount-nix-store
  [sudo]   ─── content ───
  [sudo]   │ #!/bin/sh
  [sudo]   │ # Mounts the "Nix Store" APFS volume at /nix. Installed by macos-single-user-nix.
  [sudo]   │ /bin/wait4path /nix && /usr/sbin/diskutil mount 8188B871-A175-4E8A-BD39-D44F15326DF3  [sudo]   ─── end ───
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] set mount helper ownership to root:wheel
  [sudo]   $ sudo chown root:wheel /usr/local/libexec/mount-nix-store
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] make mount helper executable (0755)
  [sudo]   $ sudo chmod 755 /usr/local/libexec/mount-nix-store
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] install LaunchDaemon plist (mounts /nix at every boot)
  [sudo]   $ sudo cp /var/folders/p7/f_99nxmj7s16qrxbl0cbpz4r0000gn/T/tmp.M4JwefuO7R /Library/LaunchDaemons/org.nixos.darwin-store.plist
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] set LaunchDaemon plist ownership to root:wheel
  [sudo]   $ sudo chown root:wheel /Library/LaunchDaemons/org.nixos.darwin-store.plist
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] set LaunchDaemon plist mode to 0644
  [sudo]   $ sudo chmod 644 /Library/LaunchDaemons/org.nixos.darwin-store.plist
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] load the LaunchDaemon
  [sudo]   $ sudo launchctl load -w /Library/LaunchDaemons/org.nixos.darwin-store.plist
  [sudo] Press Enter to run, or Ctrl-C to abort...

[→] Phase 3/3: installing Nix 2.35.2 (no sudo from here)
  downloading nix-2.35.2-aarch64-darwin.tar.xz from releases.nixos.org
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0100 17.6M  100 17.6M    0     0  44.4M      0 --:--:-- --:--:-- --:--:-- 44.4M
  copying store paths into /nix/store
  registering store paths in the Nix database
  installing Nix into your user profile (~/.nix-profile)
installing 'nix-2.35.2'
building '/nix/store/51lhlqx1rkrfnjihip1vli2rr2f3lpcz-user-environment.drv'...
  [✓] nix --version: nix (Nix) 2.35.2
  writing ~/.config/nix/nix.conf (experimental-features, accept-flake-config)
  installing cacert (HTTPS certificates for Nix)
unpacking 'https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst' into the Git cache...
this path will be fetched (151.2 KiB download, 649.7 KiB unpacked):
  /nix/store/fyjfc7z61v4imvrh7srqawq8c35v2jb3-nss-cacert-3.126
copying path '/nix/store/fyjfc7z61v4imvrh7srqawq8c35v2jb3-nss-cacert-3.126' from 'https://cache.nixos.org'...
  appending nix profile sourcing to /Users/admin/.bash_profile

verification:
  nix --version: nix (Nix) 2.35.2
  /nix mount:    /dev/disk3s7 on /nix (apfs, local, journaled)
  querying public binary cache:
Store URL: https://cache.nixos.org

Final status:

This installer runs in 3 phases:
  [✓] Phase 1: declare /nix  (requires sudo + reboot)
  [✓] Phase 2: mount "Nix Store" volume via LaunchDaemon  (requires sudo)
  [✓] Phase 3: install Nix 2.35.2 to ~/.nix-profile

Operations performed this run:
  [✓] Phase 2: APFS volume + LaunchDaemon configured
  [✓] Phase 3: Nix 2.35.2 installed for bash
Privileged operations: 11 sudo call(s) executed.

done — single-user Nix is installed.
open a new shell (or re-source your shell rc) to pick up the PATH change.

[driver] sudo_lines=11 pauses=11 reported=11 password_prompts=1 exit=0 terminal=yes
[vm-test] ── scenario: verify/mount.sh
[vm-test] asserting: /nix is mounted
[vm-test] ── scenario: verify/launchdaemon.sh
[vm-test] asserting: org.nixos.darwin-store LaunchDaemon is loaded
Password:[vm-test] ── scenario: verify/nix-works.sh
[vm-test] asserting: nix --version works in a fresh bash login shell
[vm-test]   → nix (Nix) 2.35.2
[vm-test] asserting: nix can reach the public binary cache
Store URL: https://cache.nixos.org
[vm-test] ── scenario: verify/sudo-commands.sh
[vm-test] asserting: the sudo commands printed match the expected list (exact, invocations 1-999999)
[vm-test]   → 13 sudo commands match
[vm-test] ── scenario: verify/pauses-answered.sh
[vm-test] asserting: the terminal run answered sudo pauses
[vm-test]   invocation: sudo_lines=2 pauses=2 reported=none password_prompts=1 exit=0 terminal=yes
[vm-test]   invocation: sudo_lines=11 pauses=11 reported=11 password_prompts=1 exit=0 terminal=yes
[vm-test]   → 13 pauses answered
[vm-test] PASS — playbook 'happy-bash' completed
~~~

</details>

<details>
<summary>happy-zsh: pass</summary>

~~~text
[vm-test] playbook: happy-zsh → nix-test-happy-zsh-46336 (clone of nix-paved-tahoe)
[vm-test] cloning nix-paved-tahoe → nix-test-happy-zsh-46336
[vm-test] starting VM nix-test-happy-zsh-46336 (headless)
[vm-test] VM up at 192.168.64.107 — running playbook
[vm-test] ── scenario: setup/remove-passwordless-sudo.sh
[vm-test] removing every passwordless sudoers entry from this clone
[vm-test]   → sudo now needs a password
[vm-test] ── scenario: verify/guest-version.sh
[vm-test] asserting: guest macOS build starts with 26
[vm-test]   → macOS 26.6.2
[vm-test] ── scenario: install/upload.sh
[vm-test] uploading install.sh → admin@192.168.64.107:~/install.sh
[vm-test] ── scenario: install/phase1.sh
[vm-test] running install.sh (phase 1) on 192.168.64.107
TERMINAL:yes
macos-single-user-nix installer
detecting latest Nix release…
Nix version: 2.35.2  (latest from releases.nixos.org)

This installer runs in 3 phases:
  [ ] Phase 1: declare /nix  (requires sudo + reboot)
  [ ] Phase 2: mount "Nix Store" volume via LaunchDaemon  (requires sudo)
  [ ] Phase 3: install Nix 2.35.2 to ~/.nix-profile

Every sudo is echoed and then paused, so you can confirm to continue — no hidden privileges

Next, you'll be prompted for your password once  (sudo -v warm-up)

Password:

[→] Phase 1/3: declaring /nix in /etc/synthetic.conf
  [sudo] create /etc/synthetic.conf with 'nix' entry
  [sudo]   $ sudo tee > /etc/synthetic.conf
  [sudo]   ─── content ───
  [sudo]   │ nix  [sudo]   ─── end ───
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] ensure /etc/synthetic.conf is world-readable
  [sudo]   $ sudo chmod 644 /etc/synthetic.conf
  [sudo] Press Enter to run, or Ctrl-C to abort...

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


[driver] sudo_lines=2 pauses=2 reported=none password_prompts=1 exit=0 terminal=yes
[vm-test] ── scenario: install/reboot.sh
[vm-test] rebooting nix-test-happy-zsh-46336
Password:Connection to 192.168.64.107 closed by remote host.
[vm-test] ── scenario: install/phase2-3.sh
[vm-test] running install.sh (phases 2 + 3) on 192.168.64.107
TERMINAL:yes
macos-single-user-nix installer
detecting latest Nix release…
Nix version: 2.35.2  (latest from releases.nixos.org)

This installer runs in 3 phases:
  [✓] Phase 1: declare /nix  (requires sudo + reboot)
  [ ] Phase 2: mount "Nix Store" volume via LaunchDaemon  (requires sudo)
  [ ] Phase 3: install Nix 2.35.2 to ~/.nix-profile

Every sudo is echoed and then paused, so you can confirm to continue — no hidden privileges

Next, you'll be prompted for your password once  (sudo -v warm-up)

Password:
[-] Phase 1/3: /etc/synthetic.conf already declares /nix — skipping

[→] Phase 2/3: creating APFS Nix Store volume + LaunchDaemon
  using APFS container: disk3
  [sudo] create APFS volume "Nix Store" on disk3, mount at /nix
  [sudo]   $ sudo diskutil apfs addVolume disk3 Case-sensitive APFS Nix Store -mountpoint /nix
  [sudo] Press Enter to run, or Ctrl-C to abort...
Will export new APFS (Case-sensitive) Volume "Nix Store" from APFS Container Reference disk3
Started APFS operation on disk3
Preparing to add APFS Volume to APFS Container disk3
Creating APFS Volume
Created new APFS Volume disk3s7
Mounting disk
Setting volume permissions
Disk from APFS operation: disk3s7
Finished APFS operation on disk3
  [sudo] give your user ownership of /nix (single-user mode)
  [sudo]   $ sudo chown -R admin:staff /nix
  [sudo] Press Enter to run, or Ctrl-C to abort...
  creating Nix directory structure under /nix
  Nix Store UUID: 5A703477-CB3D-436D-B38D-8CDBF3FA33F5
  [sudo] record Nix Store in /etc/fstab (noauto: LaunchDaemon will mount it)
  [sudo]   $ sudo tee >> /etc/fstab
  [sudo]   ─── content ───
  [sudo]   │ UUID=5A703477-CB3D-436D-B38D-8CDBF3FA33F5 /nix apfs rw,noauto,nobrowse,nosuid,noatime,owners  [sudo]   ─── end ───
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] create /usr/local/libexec for the Nix mount helper
  [sudo]   $ sudo mkdir -p /usr/local/libexec
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] install named Nix Store mount helper (legible Login Items name)
  [sudo]   $ sudo tee > /usr/local/libexec/mount-nix-store
  [sudo]   ─── content ───
  [sudo]   │ #!/bin/sh
  [sudo]   │ # Mounts the "Nix Store" APFS volume at /nix. Installed by macos-single-user-nix.
  [sudo]   │ /bin/wait4path /nix && /usr/sbin/diskutil mount 5A703477-CB3D-436D-B38D-8CDBF3FA33F5  [sudo]   ─── end ───
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] set mount helper ownership to root:wheel
  [sudo]   $ sudo chown root:wheel /usr/local/libexec/mount-nix-store
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] make mount helper executable (0755)
  [sudo]   $ sudo chmod 755 /usr/local/libexec/mount-nix-store
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] install LaunchDaemon plist (mounts /nix at every boot)
  [sudo]   $ sudo cp /var/folders/p7/f_99nxmj7s16qrxbl0cbpz4r0000gn/T/tmp.LyNwpn31Kd /Library/LaunchDaemons/org.nixos.darwin-store.plist
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] set LaunchDaemon plist ownership to root:wheel
  [sudo]   $ sudo chown root:wheel /Library/LaunchDaemons/org.nixos.darwin-store.plist
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] set LaunchDaemon plist mode to 0644
  [sudo]   $ sudo chmod 644 /Library/LaunchDaemons/org.nixos.darwin-store.plist
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] load the LaunchDaemon
  [sudo]   $ sudo launchctl load -w /Library/LaunchDaemons/org.nixos.darwin-store.plist
  [sudo] Press Enter to run, or Ctrl-C to abort...

[→] Phase 3/3: installing Nix 2.35.2 (no sudo from here)
  downloading nix-2.35.2-aarch64-darwin.tar.xz from releases.nixos.org
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0 14 17.6M   14 2655k    0     0  18.5M      0 --:--:-- --:--:-- --:--:-- 18.5M100 17.6M  100 17.6M    0     0  51.4M      0 --:--:-- --:--:-- --:--:-- 51.5M
  copying store paths into /nix/store
  registering store paths in the Nix database
  installing Nix into your user profile (~/.nix-profile)
installing 'nix-2.35.2'
building '/nix/store/51lhlqx1rkrfnjihip1vli2rr2f3lpcz-user-environment.drv'...
  [✓] nix --version: nix (Nix) 2.35.2
  writing ~/.config/nix/nix.conf (experimental-features, accept-flake-config)
  installing cacert (HTTPS certificates for Nix)
unpacking 'https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst' into the Git cache...
this path will be fetched (151.2 KiB download, 649.7 KiB unpacked):
  /nix/store/fyjfc7z61v4imvrh7srqawq8c35v2jb3-nss-cacert-3.126
copying path '/nix/store/fyjfc7z61v4imvrh7srqawq8c35v2jb3-nss-cacert-3.126' from 'https://cache.nixos.org'...
  appending nix profile sourcing to /Users/admin/.zshenv

verification:
  nix --version: nix (Nix) 2.35.2
  /nix mount:    /dev/disk3s7 on /nix (apfs, local, journaled)
  querying public binary cache:
Store URL: https://cache.nixos.org

Final status:

This installer runs in 3 phases:
  [✓] Phase 1: declare /nix  (requires sudo + reboot)
  [✓] Phase 2: mount "Nix Store" volume via LaunchDaemon  (requires sudo)
  [✓] Phase 3: install Nix 2.35.2 to ~/.nix-profile

Operations performed this run:
  [✓] Phase 2: APFS volume + LaunchDaemon configured
  [✓] Phase 3: Nix 2.35.2 installed for zsh
Privileged operations: 11 sudo call(s) executed.

done — single-user Nix is installed.
open a new shell (or re-source your shell rc) to pick up the PATH change.

[driver] sudo_lines=11 pauses=11 reported=11 password_prompts=1 exit=0 terminal=yes
[vm-test] ── scenario: verify/mount.sh
[vm-test] asserting: /nix is mounted
[vm-test] ── scenario: verify/launchdaemon.sh
[vm-test] asserting: org.nixos.darwin-store LaunchDaemon is loaded
Password:[vm-test] ── scenario: verify/nix-works.sh
[vm-test] asserting: nix --version works in a fresh zsh login shell
[vm-test]   → nix (Nix) 2.35.2
[vm-test] asserting: nix can reach the public binary cache
Store URL: https://cache.nixos.org
[vm-test] ── scenario: verify/sudo-commands.sh
[vm-test] asserting: the sudo commands printed match the expected list (exact, invocations 1-999999)
[vm-test]   → 13 sudo commands match
[vm-test] ── scenario: install/reboot.sh
[vm-test] rebooting nix-test-happy-zsh-46336
Password:Connection to 192.168.64.107 closed by remote host.
[vm-test] ── scenario: verify/mount.sh
[vm-test] asserting: /nix is mounted
[vm-test] ── scenario: verify/nix-works.sh
[vm-test] asserting: nix --version works in a fresh zsh login shell
[vm-test]   → nix (Nix) 2.35.2
[vm-test] asserting: nix can reach the public binary cache
Store URL: https://cache.nixos.org
[vm-test] ── scenario: verify/pauses-answered.sh
[vm-test] asserting: the terminal run answered sudo pauses
[vm-test]   invocation: sudo_lines=2 pauses=2 reported=none password_prompts=1 exit=0 terminal=yes
[vm-test]   invocation: sudo_lines=11 pauses=11 reported=11 password_prompts=1 exit=0 terminal=yes
[vm-test]   → 13 pauses answered
[vm-test] PASS — playbook 'happy-zsh' completed
~~~

</details>

<details>
<summary>phase1-no-reboot-fails-cleanly: pass</summary>

~~~text
[vm-test] playbook: phase1-no-reboot-fails-cleanly → nix-test-phase1-no-reboot-fails-cleanly-47010 (clone of nix-paved-tahoe)
[vm-test] cloning nix-paved-tahoe → nix-test-phase1-no-reboot-fails-cleanly-47010
[vm-test] starting VM nix-test-phase1-no-reboot-fails-cleanly-47010 (headless)
[vm-test] VM up at 192.168.64.108 — running playbook
[vm-test] ── scenario: setup/remove-passwordless-sudo.sh
[vm-test] removing every passwordless sudoers entry from this clone
[vm-test]   → sudo now needs a password
[vm-test] ── scenario: verify/guest-version.sh
[vm-test] asserting: guest macOS build starts with 26
[vm-test]   → macOS 26.6.2
[vm-test] ── scenario: install/upload.sh
[vm-test] uploading install.sh → admin@192.168.64.108:~/install.sh
[vm-test] ── scenario: install/phase1.sh
[vm-test] running install.sh (phase 1) on 192.168.64.108
TERMINAL:yes
macos-single-user-nix installer
detecting latest Nix release…
Nix version: 2.35.2  (latest from releases.nixos.org)

This installer runs in 3 phases:
  [ ] Phase 1: declare /nix  (requires sudo + reboot)
  [ ] Phase 2: mount "Nix Store" volume via LaunchDaemon  (requires sudo)
  [ ] Phase 3: install Nix 2.35.2 to ~/.nix-profile

Every sudo is echoed and then paused, so you can confirm to continue — no hidden privileges

Next, you'll be prompted for your password once  (sudo -v warm-up)

Password:

[→] Phase 1/3: declaring /nix in /etc/synthetic.conf
  [sudo] create /etc/synthetic.conf with 'nix' entry
  [sudo]   $ sudo tee > /etc/synthetic.conf
  [sudo]   ─── content ───
  [sudo]   │ nix  [sudo]   ─── end ───
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] ensure /etc/synthetic.conf is world-readable
  [sudo]   $ sudo chmod 644 /etc/synthetic.conf
  [sudo] Press Enter to run, or Ctrl-C to abort...

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


[driver] sudo_lines=2 pauses=2 reported=none password_prompts=1 exit=0 terminal=yes
[vm-test] ── scenario: verify/phase2-refused.sh
[vm-test] asserting: install.sh refuses to enter phase 2 when /nix is absent
TERMINAL:yes
macos-single-user-nix installer
detecting latest Nix release…
Nix version: 2.35.2  (latest from releases.nixos.org)

This installer runs in 3 phases:
  [✓] Phase 1: declare /nix  (requires sudo + reboot)
  [ ] Phase 2: mount "Nix Store" volume via LaunchDaemon  (requires sudo)
  [ ] Phase 3: install Nix 2.35.2 to ~/.nix-profile

ERROR: /nix does not exist even though synthetic.conf declares it.
       Did you reboot since editing /etc/synthetic.conf? If so, check:
         cat /etc/synthetic.conf
       and reboot once more.

[driver] sudo_lines=0 pauses=0 reported=none password_prompts=0 exit=1 terminal=yes
[vm-test]   → installer refused as expected
[vm-test] ── scenario: verify/sudo-commands.sh
[vm-test] asserting: the sudo commands printed match the expected list (prefix, invocations 1-999999)
[vm-test]   → 2 sudo commands match
[vm-test] ── scenario: verify/pauses-answered.sh
[vm-test] asserting: the terminal run answered sudo pauses
[vm-test]   invocation: sudo_lines=2 pauses=2 reported=none password_prompts=1 exit=0 terminal=yes
[vm-test]   invocation: sudo_lines=0 pauses=0 reported=none password_prompts=0 exit=1 terminal=yes
[vm-test]   → 2 pauses answered
[vm-test] PASS — playbook 'phase1-no-reboot-fails-cleanly' completed
~~~

</details>

<details>
<summary>phase1-undone-fails-cleanly: pass</summary>

~~~text
[vm-test] playbook: phase1-undone-fails-cleanly → nix-test-phase1-undone-fails-cleanly-47274 (clone of nix-paved-tahoe)
[vm-test] cloning nix-paved-tahoe → nix-test-phase1-undone-fails-cleanly-47274
[vm-test] starting VM nix-test-phase1-undone-fails-cleanly-47274 (headless)
[vm-test] VM up at 192.168.64.109 — running playbook
[vm-test] ── scenario: setup/remove-passwordless-sudo.sh
[vm-test] removing every passwordless sudoers entry from this clone
[vm-test]   → sudo now needs a password
[vm-test] ── scenario: verify/guest-version.sh
[vm-test] asserting: guest macOS build starts with 26
[vm-test]   → macOS 26.6.2
[vm-test] ── scenario: install/upload.sh
[vm-test] uploading install.sh → admin@192.168.64.109:~/install.sh
[vm-test] ── scenario: install/phase1.sh
[vm-test] running install.sh (phase 1) on 192.168.64.109
TERMINAL:yes
macos-single-user-nix installer
detecting latest Nix release…
Nix version: 2.35.2  (latest from releases.nixos.org)

This installer runs in 3 phases:
  [ ] Phase 1: declare /nix  (requires sudo + reboot)
  [ ] Phase 2: mount "Nix Store" volume via LaunchDaemon  (requires sudo)
  [ ] Phase 3: install Nix 2.35.2 to ~/.nix-profile

Every sudo is echoed and then paused, so you can confirm to continue — no hidden privileges

Next, you'll be prompted for your password once  (sudo -v warm-up)

Password:

[→] Phase 1/3: declaring /nix in /etc/synthetic.conf
  [sudo] create /etc/synthetic.conf with 'nix' entry
  [sudo]   $ sudo tee > /etc/synthetic.conf
  [sudo]   ─── content ───
  [sudo]   │ nix  [sudo]   ─── end ───
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] ensure /etc/synthetic.conf is world-readable
  [sudo]   $ sudo chmod 644 /etc/synthetic.conf
  [sudo] Press Enter to run, or Ctrl-C to abort...

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


[driver] sudo_lines=2 pauses=2 reported=none password_prompts=1 exit=0 terminal=yes
[vm-test] ── scenario: install/reboot.sh
[vm-test] rebooting nix-test-phase1-undone-fails-cleanly-47274
Password:Connection to 192.168.64.109 closed by remote host.
[vm-test] ── scenario: corrupt/delete-synthetic-conf.sh
[vm-test] corrupting state: removing 'nix' from /etc/synthetic.conf
Password:Password:[vm-test] ── scenario: verify/phase1-redone.sh
[vm-test] asserting: install.sh redoes phase 1 when synthetic.conf was wiped
TERMINAL:yes
macos-single-user-nix installer
detecting latest Nix release…
Nix version: 2.35.2  (latest from releases.nixos.org)

This installer runs in 3 phases:
  [ ] Phase 1: declare /nix  (requires sudo + reboot)
  [ ] Phase 2: mount "Nix Store" volume via LaunchDaemon  (requires sudo)
  [ ] Phase 3: install Nix 2.35.2 to ~/.nix-profile

Every sudo is echoed and then paused, so you can confirm to continue — no hidden privileges

Next, you'll be prompted for your password once  (sudo -v warm-up)

Password:

[→] Phase 1/3: declaring /nix in /etc/synthetic.conf
  [sudo] create /etc/synthetic.conf with 'nix' entry
  [sudo]   $ sudo tee > /etc/synthetic.conf
  [sudo]   ─── content ───
  [sudo]   │ nix  [sudo]   ─── end ───
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] ensure /etc/synthetic.conf is world-readable
  [sudo]   $ sudo chmod 644 /etc/synthetic.conf
  [sudo] Press Enter to run, or Ctrl-C to abort...

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


[driver] sudo_lines=2 pauses=2 reported=none password_prompts=1 exit=0 terminal=yes
[vm-test]   → installer redid phase 1, printed the reboot notice, exited 0, made no volume
[vm-test] ── scenario: verify/sudo-commands.sh
[vm-test] asserting: the sudo commands printed match the expected list (prefix, invocations 1-1)
[vm-test]   → 2 sudo commands match
[vm-test] ── scenario: verify/sudo-commands.sh
[vm-test] asserting: the sudo commands printed match the expected list (prefix, invocations 2-2)
[vm-test]   → 2 sudo commands match
[vm-test] ── scenario: verify/pauses-answered.sh
[vm-test] asserting: the terminal run answered sudo pauses
[vm-test]   invocation: sudo_lines=2 pauses=2 reported=none password_prompts=1 exit=0 terminal=yes
[vm-test]   invocation: sudo_lines=2 pauses=2 reported=none password_prompts=1 exit=0 terminal=yes
[vm-test]   → 4 pauses answered
[vm-test] PASS — playbook 'phase1-undone-fails-cleanly' completed
~~~

</details>

<details>
<summary>phase2-launchdaemon-broken: pass</summary>

~~~text
[vm-test] playbook: phase2-launchdaemon-broken → nix-test-phase2-launchdaemon-broken-47641 (clone of nix-paved-tahoe)
[vm-test] cloning nix-paved-tahoe → nix-test-phase2-launchdaemon-broken-47641
[vm-test] starting VM nix-test-phase2-launchdaemon-broken-47641 (headless)
[vm-test] VM up at 192.168.64.110 — running playbook
[vm-test] ── scenario: setup/remove-passwordless-sudo.sh
[vm-test] removing every passwordless sudoers entry from this clone
[vm-test]   → sudo now needs a password
[vm-test] ── scenario: verify/guest-version.sh
[vm-test] asserting: guest macOS build starts with 26
[vm-test]   → macOS 26.6.2
[vm-test] ── scenario: install/upload.sh
[vm-test] uploading install.sh → admin@192.168.64.110:~/install.sh
[vm-test] ── scenario: install/phase1.sh
[vm-test] running install.sh (phase 1) on 192.168.64.110
TERMINAL:yes
macos-single-user-nix installer
detecting latest Nix release…
Nix version: 2.35.2  (latest from releases.nixos.org)

This installer runs in 3 phases:
  [ ] Phase 1: declare /nix  (requires sudo + reboot)
  [ ] Phase 2: mount "Nix Store" volume via LaunchDaemon  (requires sudo)
  [ ] Phase 3: install Nix 2.35.2 to ~/.nix-profile

Every sudo is echoed and then paused, so you can confirm to continue — no hidden privileges

Next, you'll be prompted for your password once  (sudo -v warm-up)

Password:

[→] Phase 1/3: declaring /nix in /etc/synthetic.conf
  [sudo] create /etc/synthetic.conf with 'nix' entry
  [sudo]   $ sudo tee > /etc/synthetic.conf
  [sudo]   ─── content ───
  [sudo]   │ nix  [sudo]   ─── end ───
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] ensure /etc/synthetic.conf is world-readable
  [sudo]   $ sudo chmod 644 /etc/synthetic.conf
  [sudo] Press Enter to run, or Ctrl-C to abort...

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


[driver] sudo_lines=2 pauses=2 reported=none password_prompts=1 exit=0 terminal=yes
[vm-test] ── scenario: install/reboot.sh
[vm-test] rebooting nix-test-phase2-launchdaemon-broken-47641
Password:Connection to 192.168.64.110 closed by remote host.
[vm-test] ── scenario: install/phase2-3.sh
[vm-test] running install.sh (phases 2 + 3) on 192.168.64.110
TERMINAL:yes
macos-single-user-nix installer
detecting latest Nix release…
Nix version: 2.35.2  (latest from releases.nixos.org)

This installer runs in 3 phases:
  [✓] Phase 1: declare /nix  (requires sudo + reboot)
  [ ] Phase 2: mount "Nix Store" volume via LaunchDaemon  (requires sudo)
  [ ] Phase 3: install Nix 2.35.2 to ~/.nix-profile

Every sudo is echoed and then paused, so you can confirm to continue — no hidden privileges

Next, you'll be prompted for your password once  (sudo -v warm-up)

Password:
[-] Phase 1/3: /etc/synthetic.conf already declares /nix — skipping

[→] Phase 2/3: creating APFS Nix Store volume + LaunchDaemon
  using APFS container: disk3
  [sudo] create APFS volume "Nix Store" on disk3, mount at /nix
  [sudo]   $ sudo diskutil apfs addVolume disk3 Case-sensitive APFS Nix Store -mountpoint /nix
  [sudo] Press Enter to run, or Ctrl-C to abort...
Will export new APFS (Case-sensitive) Volume "Nix Store" from APFS Container Reference disk3
Started APFS operation on disk3
Preparing to add APFS Volume to APFS Container disk3
Creating APFS Volume
Created new APFS Volume disk3s7
Mounting disk
Setting volume permissions
Disk from APFS operation: disk3s7
Finished APFS operation on disk3
  [sudo] give your user ownership of /nix (single-user mode)
  [sudo]   $ sudo chown -R admin:staff /nix
  [sudo] Press Enter to run, or Ctrl-C to abort...
  creating Nix directory structure under /nix
  Nix Store UUID: 03ECEF36-8031-4BF5-9AE0-5FA5D7EAF06B
  [sudo] record Nix Store in /etc/fstab (noauto: LaunchDaemon will mount it)
  [sudo]   $ sudo tee >> /etc/fstab
  [sudo]   ─── content ───
  [sudo]   │ UUID=03ECEF36-8031-4BF5-9AE0-5FA5D7EAF06B /nix apfs rw,noauto,nobrowse,nosuid,noatime,owners  [sudo]   ─── end ───
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] create /usr/local/libexec for the Nix mount helper
  [sudo]   $ sudo mkdir -p /usr/local/libexec
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] install named Nix Store mount helper (legible Login Items name)
  [sudo]   $ sudo tee > /usr/local/libexec/mount-nix-store
  [sudo]   ─── content ───
  [sudo]   │ #!/bin/sh
  [sudo]   │ # Mounts the "Nix Store" APFS volume at /nix. Installed by macos-single-user-nix.
  [sudo]   │ /bin/wait4path /nix && /usr/sbin/diskutil mount 03ECEF36-8031-4BF5-9AE0-5FA5D7EAF06B  [sudo]   ─── end ───
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] set mount helper ownership to root:wheel
  [sudo]   $ sudo chown root:wheel /usr/local/libexec/mount-nix-store
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] make mount helper executable (0755)
  [sudo]   $ sudo chmod 755 /usr/local/libexec/mount-nix-store
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] install LaunchDaemon plist (mounts /nix at every boot)
  [sudo]   $ sudo cp /var/folders/p7/f_99nxmj7s16qrxbl0cbpz4r0000gn/T/tmp.gyddiFjQL6 /Library/LaunchDaemons/org.nixos.darwin-store.plist
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] set LaunchDaemon plist ownership to root:wheel
  [sudo]   $ sudo chown root:wheel /Library/LaunchDaemons/org.nixos.darwin-store.plist
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] set LaunchDaemon plist mode to 0644
  [sudo]   $ sudo chmod 644 /Library/LaunchDaemons/org.nixos.darwin-store.plist
  [sudo] Press Enter to run, or Ctrl-C to abort...
  [sudo] load the LaunchDaemon
  [sudo]   $ sudo launchctl load -w /Library/LaunchDaemons/org.nixos.darwin-store.plist
  [sudo] Press Enter to run, or Ctrl-C to abort...

[→] Phase 3/3: installing Nix 2.35.2 (no sudo from here)
  downloading nix-2.35.2-aarch64-darwin.tar.xz from releases.nixos.org
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0100 17.6M  100 17.6M    0     0  41.9M      0 --:--:-- --:--:-- --:--:-- 42.0M
  copying store paths into /nix/store
  registering store paths in the Nix database
  installing Nix into your user profile (~/.nix-profile)
installing 'nix-2.35.2'
building '/nix/store/51lhlqx1rkrfnjihip1vli2rr2f3lpcz-user-environment.drv'...
  [✓] nix --version: nix (Nix) 2.35.2
  writing ~/.config/nix/nix.conf (experimental-features, accept-flake-config)
  installing cacert (HTTPS certificates for Nix)
unpacking 'https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst' into the Git cache...
this path will be fetched (151.2 KiB download, 649.7 KiB unpacked):
  /nix/store/fyjfc7z61v4imvrh7srqawq8c35v2jb3-nss-cacert-3.126
copying path '/nix/store/fyjfc7z61v4imvrh7srqawq8c35v2jb3-nss-cacert-3.126' from 'https://cache.nixos.org'...
  appending nix profile sourcing to /Users/admin/.zshenv

verification:
  nix --version: nix (Nix) 2.35.2
  /nix mount:    /dev/disk3s7 on /nix (apfs, local, journaled)
  querying public binary cache:
Store URL: https://cache.nixos.org

Final status:

This installer runs in 3 phases:
  [✓] Phase 1: declare /nix  (requires sudo + reboot)
  [✓] Phase 2: mount "Nix Store" volume via LaunchDaemon  (requires sudo)
  [✓] Phase 3: install Nix 2.35.2 to ~/.nix-profile

Operations performed this run:
  [✓] Phase 2: APFS volume + LaunchDaemon configured
  [✓] Phase 3: Nix 2.35.2 installed for zsh
Privileged operations: 11 sudo call(s) executed.

done — single-user Nix is installed.
open a new shell (or re-source your shell rc) to pick up the PATH change.

[driver] sudo_lines=11 pauses=11 reported=11 password_prompts=1 exit=0 terminal=yes
[vm-test] ── scenario: verify/sudo-commands.sh
[vm-test] asserting: the sudo commands printed match the expected list (exact, invocations 1-999999)
[vm-test]   → 13 sudo commands match
[vm-test] ── scenario: verify/mount.sh
[vm-test] asserting: /nix is mounted
[vm-test] ── scenario: verify/launchdaemon.sh
[vm-test] asserting: org.nixos.darwin-store LaunchDaemon is loaded
Password:[vm-test] ── scenario: corrupt/remove-launchdaemon.sh
[vm-test] corrupting state: unloading + removing org.nixos.darwin-store
Password:Password:[vm-test]   unmounting /nix
Password:Volume Nix Store on disk3s7 force-unmounted
[vm-test] ── scenario: install/reboot.sh
[vm-test] rebooting nix-test-phase2-launchdaemon-broken-47641
Password:Connection to 192.168.64.110 closed by remote host.
[vm-test]   → /nix correctly unmounted after LaunchDaemon removal
[vm-test]   → nix correctly unavailable when /nix is unmounted
[vm-test] ── scenario: verify/pauses-answered.sh
[vm-test] asserting: the terminal run answered sudo pauses
[vm-test]   invocation: sudo_lines=2 pauses=2 reported=none password_prompts=1 exit=0 terminal=yes
[vm-test]   invocation: sudo_lines=11 pauses=11 reported=11 password_prompts=1 exit=0 terminal=yes
[vm-test]   → 13 pauses answered
[vm-test] PASS — playbook 'phase2-launchdaemon-broken' completed
~~~

</details>
