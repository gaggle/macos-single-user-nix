# macos-single-user-nix


A single-shell-script installer for [Nix](https://nixos.org/) in **single-user
mode** on macOS.

Single-user is the lesser-trodden path on macOS: the official installer
defaults to multi-user (`nix-daemon`). This repo exists because single-user is
the right fit for a personal dev machine: no daemon to manage, no
`/etc/nix/nix.conf` to share, your own user owns `/nix/store` outright.

## Installing Nix on your Mac

Prerequisites: macOS, sudo access (just for installation, not ongoingly), and the ability to reboot.

The fast path:

```sh
curl -fsSL https://raw.githubusercontent.com/gaggle/macos-single-user-nix/main/install.sh | bash
```

To audit the script before running (recommended, since it uses sudo):

```sh
curl -fsSL https://raw.githubusercontent.com/gaggle/macos-single-user-nix/main/install.sh | less
```

The script runs in three phases and is **safe to re-run**: it detects what's
already done and skips ahead.

1. **Phase 1** configures macOS to create `/nix` at boot. After this you are asked to reboot.
2. **Phase 2** (after reboot, run the same install command again) creates an APFS volume called `Nix Store`, mounts it on `/nix`, and installs a LaunchDaemon
   (`org.nixos.darwin-store`) that re-mounts the volume at every boot.
3. **Phase 3** downloads the Nix release tarball, copies the store paths into
   `/nix/store`, registers the database, drops a `nix.conf`, and adds the
   profile sourcing to your shell's rc file (see [Shell support](#shell-support)).

After phase 3 the installer prints what a working install looks like:

```
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

Privileged operations: 11 sudo call(s) executed.

done — single-user Nix is installed.
```

Nix is installed. Open a new shell to pick up the PATH change:

```sh
nix --version
nix store info --store https://cache.nixos.org
```

### Picking the Nix version

By default the installer detects the latest published release by listing
`https://releases.nixos.org/?prefix=nix/` and picking the highest semver.
To pin explicitly:

```sh
NIX_VERSION=2.34.6 ./install.sh
```

### Shell support

The installer dispatches on `$SHELL` and writes to whichever rc file is right
for your shell. Supported out of the box:

| Shell                   | Target file                      | Syntax                                       |
|-------------------------|----------------------------------|----------------------------------------------|
| **zsh** (macOS default) | `~/.zshenv`                      | sources `nix-profile/etc/profile.d/nix.sh`   |
| **bash**                | `~/.bash_profile`                | sources `nix-profile/etc/profile.d/nix.sh`   |

(PRs for other shells welcome!)

## Why single-user?

Single-user is a mode Nix supports. The [manual](https://nix.dev/manual/nix/2.34/installation/)
documents it, and on Linux multi-user requires SELinux disabled. Only the macOS
installer dropped it, in [NixOS/nix#4289](https://github.com/NixOS/nix/pull/4289)
(Nix 2.4), because its author found the macOS install getting too complex for
single-user mode. There is a [discussion on Discourse](https://discourse.nixos.org/t/change-my-mind-i-still-want-single-user-on-macos/16278)
about it. No shade on the maintainers, it is a thankless job to maintain the infinite desires of a large userbase, and I respect their decision. I just don't accept it 😅, and this repository exists because of it.

Trade-offs vs. the default multi-user install:

|                      | Single-user                 | Multi-user (default)                                                                           |
|----------------------|-----------------------------|------------------------------------------------------------------------------------------------|
| LaunchDaemons        | 1, just for mounting `/nix` | 2, mounts `/nix` **and** runs a store-mediating daemon that handles socket-requests and builds |
| `/nix/store` owner   | your user                   | `root`                                                                                         |
| Sharing across users | no                          | yes                                                                                            |
| Setup complexity     | lower (no `_nixbld` users)  | higher (installs 32 `_nixbld` hidden users)                                                    |
| Nix upgrades         | simpler, no sudo required   | complex, needs sudo and coordinating the root daemon                                           |

If you're the only person on the Mac and you don't need other accounts to share the store,
single-user is fewer moving parts.

## A note on `sudo`

The official Nix installer is notoriously opaque about what it does with
root, and that's most of what this repo is reacting to. Our rules:

- Every `sudo` invocation is **echoed at the moment it runs** and then
  waits for confirmation before proceeding. So you can audit it in your
  terminal. The commands a full install prints are listed in
  [`test/expected-sudo-commands.txt`](test/expected-sudo-commands.txt), and the
  test suite fails if they change.
- **Phase 3 uses no sudo at all**: that's a property of single-user mode
  (Nix is owned by your user, not root), and we surface it explicitly.

## Hacking on this repo

If you've got Nix installed (via this very script, perhaps), then
[install devenv](https://devenv.sh/getting-started/#2-install-devenv).

Then, activate the environment:

```sh
devenv allow      # one-time
# or
devenv shell
```

This enables for you a shell with all dependencies available.

### Running the tests

The test harness boots a fresh macOS VM via [tart](https://tart.run), copies
[`install.sh`](install.sh) in, runs the installer through its phases either
side of a real reboot, answers it at a terminal as a person would, and asserts
the final state.

```sh
test/run-vm-test.sh
```

See [`test/README.md`](test/README.md) for details, and [`REPORT.md`](REPORT.md)
for the latest run.
