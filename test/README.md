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
