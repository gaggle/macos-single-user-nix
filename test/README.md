# VM test harness

End-to-end verification that [`install.sh`](../install.sh) works as advertised.

We spin up a real macOS VM via [tart](https://tart.run),
drive `install.sh` over SSH, and assert outcomes.

It's a bit brutal, but it's a good way to verify everything actually works.

## Snapshot chain

```
ghcr.io/cirruslabs/macos-sequoia-vanilla:latest        (~25 GB, pulled once)
       │
       ▼  nix-test-vm pave
mssun-paved                vanilla + SSH key + passwordless sudo (baked once)
       │
       ▼  nix-test-vm playbook <name>      (clone, run, tear down)
mssun-test-<name>-$$       ephemeral per-run clone
```

Paving once means downstream test runs:

- skip cold-boot SSH warmup
- log in via key (no `sshpass`)
- run `install.sh` non-interactively (passwordless sudo)

## Prerequisites

- macOS host with Apple Silicon
- `tart` on PATH (run `devenv shell`)
- `sshpass` on PATH (only needed for `pave`; provided by `devenv shell`)
- `expect` on PATH (only needed for `--terminal`; provided by `devenv shell`)
- ~70 GB free disk per concurrent VM

## One-time setup

```sh
test/bin/nix-test-vm pull-base   # ~25 GB
test/bin/nix-test-vm pave        # ~5 min: boot, install key + sudoers, stop
```

## Day-to-day

```sh
# Happy paths
test/bin/nix-test-vm playbook happy-zsh
test/bin/nix-test-vm playbook happy-bash

# Negative paths
test/bin/nix-test-vm playbook phase1-no-reboot-fails-cleanly
test/bin/nix-test-vm playbook phase1-undone-fails-cleanly
test/bin/nix-test-vm playbook phase2-launchdaemon-broken

# Debugging a failing run
KEEP_VM=1 test/bin/nix-test-vm playbook happy-zsh
test/bin/nix-test-vm list
test/bin/nix-test-vm ssh mssun-test-happy-zsh-12345
test/bin/nix-test-vm clean     # nuke leftover test VMs
```

`test/run-vm-test.sh` runs all tests.

## Terminal mode

The playbooks above run `install.sh` over plain SSH with passwordless sudo, so
its sudo pauses are skipped. Terminal mode runs it the way a person meets it:

```sh
test/bin/nix-test-vm playbook happy-zsh --terminal
```

The test clone (never the paved image) loses passwordless sudo, and
[`test/lib/drive-installer.exp`](lib/drive-installer.exp), an
[expect](https://core.tcl-lang.org/expect/) script, runs `install.sh` in a
terminal inside the guest (`ssh -tt`). Each invocation starts with `sudo -k`,
and the driver refuses to go on if sudo still works without a password.

The driver answers only what it has matched, and sends nothing on a timer:

- Enter, only after a `[sudo]   $ sudo ...` line and then the exact pause text.
- The account's password, only at sudo's own `Password:` prompt.

For every invocation of `install.sh` it checks that:

- the guest gave the installer a terminal;
- pauses answered equals `[sudo]   $ sudo` lines printed;
- both equal the count the installer reports, when it reaches its summary (an
  invocation that exits early reports none, which is not a failure);
- the password was asked for exactly once;
- the installer exited as the scenario expects.

It waits at most 60 seconds for each prompt and fails with the last screen. A
reboot fails after 5 minutes and a terminal playbook after 1 hour. After the
playbook, `verify/pauses-answered.sh` fails the run if no pause was answered.
