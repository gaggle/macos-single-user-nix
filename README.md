# macos-single-user-nix

A single-shell-script installer for [Nix](https://nixos.org/) in **single-user
mode** on macOS.

Single-user mode is the lesser-trodden path on macOS — the official installer
defaults to multi-user (`nix-daemon`). This repo exists because single-user is
the right fit for a personal dev machine: no daemon to manage, no
`/etc/nix/nix.conf` to share, your own user owns `/nix/store` outright.

## Installing Nix on your Mac

Prerequisites: macOS, sudo access (just for installation, not ongoingly), and the ability to reboot.

The fast path:

```sh
curl -fsSL https://raw.githubusercontent.com/gaggle/macos-single-user-nix/main/install.sh | bash
```

To auditable the script before running (recommended to audit sudo operations):

```sh
curl -fsSL https://raw.githubusercontent.com/gaggle/macos-single-user-nix/main/install.sh | less
```

The script runs in three phases and is **safe to re-run** — it detects what's
already done and skips ahead.

1. **Phase 1** configures macOS to create `/nix` at boot. After this you are asked to reboot.
2. **Phase 2** (after reboot, run `bash install.sh` again) creates an APFS volume called `Nix Store`, mounts it on `/nix`, and installs a LaunchDaemon
   (`org.nixos.darwin-store`) that re-mounts the volume at every boot.
3. **Phase 3** downloads the Nix release tarball, copies the store paths into
   `/nix/store`, registers the database, drops a `nix.conf`, and adds the
   profile sourcing to your shell's rc file (see [Shell support](#shell-support)).

After phase 3 finishes, open a new shell:

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

### A note on `sudo`

The official Nix installer is notoriously opaque about what it does with
root — that's most of what this repo is reacting to. Our rules:

- Every `sudo` invocation is **echoed at the moment it runs** and then 
  waits for confirmation before proceding. So you can audit it in your 
  terminal.
- **Phase 3 uses no sudo at all** — that's a property of single-user mode
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
`install.sh` in, runs the two phases either side of a real reboot, and
asserts the final state.

```sh
test/run-vm-test.sh
```

See [`test/README.md`](test/README.md) for details.

## Why single-user?

Trade-offs vs. the default multi-user install:

|                      | Single-user                 | Multi-user (default)                                                                           |
|----------------------|-----------------------------|------------------------------------------------------------------------------------------------|
| LaunchDaemons        | 1, just for mounting `/nix` | 2, mounts `/nix` **and** runs a store-mediating daemon that handles socket-requests and builds |
| `/nix/store` owner   | your user                   | `root`                                                                                         |
| Sharing across users | no                          | yes                                                                                            |
| Setup complexity     | lower (no `_nixbld` users)  | higher (installs 32 `_nixbld` hidden users                                                     |
| Nix upgrades         | simpler, no sudo required   | complex, needs sudo and coordinating the root daemon                                           |

If you're the only person on the Mac and you don't need other accounts to share the store,
single-user is fewer moving parts.
