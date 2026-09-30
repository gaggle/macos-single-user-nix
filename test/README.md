# VM test harness

End-to-end verification that [install.sh](../install.sh) works as advertised.

We spin up a real macOS VM via [tart](https://tart.run), run `install.sh` in it
at a terminal, and assert outcomes. It's a bit brutal, but it's a good way to
verify everything actually works.

## Snapshot chain

```
ghcr.io/cirruslabs/macos-<release>-vanilla:<version>   (~25 GB, pulled once)
       │
       ▼  nix-test-vm pave
nix-paved-<release>          vanilla + SSH key + passwordless sudo (baked once)
       │
       ▼  nix-test-vm playbook <name>      (clone, run, tear down)
nix-test-<name>-$$           ephemeral per-run clone
```

The default is the Tahoe (macOS 26) image, `nix-paved-tahoe`. Paving once means
test runs skip the cold-boot SSH warmup and log in with a key instead of a
password. The paved image keeps passwordless sudo for the harness's own steps;
every test clone removes every passwordless entry under `/etc/sudoers.d` and
proves sudo then wants a password.

## Prerequisites

- macOS host with Apple Silicon
- `tart` and `expect` on PATH (run `devenv shell`)
- `sshpass` on PATH (only needed for `pave`; provided by `devenv shell`)
- ~70 GB free disk per concurrent VM

## One-time setup

```sh
test/bin/nix-test-vm pull-base   # ~25 GB
test/bin/nix-test-vm pave        # ~5 min: boot, install key + sudoers, stop
```

## Playbooks

| Playbook | What it does |
|---|---|
| `happy-zsh` | Happy-path install with zsh as the login shell, then a second reboot to prove the LaunchDaemon re-mounts `/nix` at boot. |
| `happy-bash` | Happy-path install with bash as the login shell. |
| `phase1-no-reboot-fails-cleanly` | Phase 1 wrote `synthetic.conf` but the user skipped the reboot. Running the installer again must refuse phase 2 with a clear error. |
| `phase1-undone-fails-cleanly` | Phase 1 ran and `/nix` appeared, then `/etc/synthetic.conf` was wiped. Running the installer again must redo phase 1, print the reboot notice, exit 0, and create no volume. |
| `phase2-launchdaemon-broken` | After a clean install, the LaunchDaemon is removed and `/nix` unmounted, then the VM reboots. `/nix` must stay unmounted and `nix --version` must fail. |

```sh
test/bin/nix-test-vm playbook happy-zsh
test/run-vm-test.sh              # every playbook, one after another
```

### How the installer is driven

Every playbook runs `install.sh` in a terminal inside the guest (`ssh -tt`),
driven by [test/lib/drive-installer.exp](lib/drive-installer.exp), an
[expect](https://core.tcl-lang.org/expect/) script. Each invocation starts with
`sudo -k`, and the driver refuses to go on if sudo still works without a
password. It answers only what it has matched, and sends nothing on a timer:

- Enter, only after a `[sudo]   $ sudo ...` line and then the exact pause text.
- The account's password, only at sudo's own `Password:` prompt.

For every invocation it checks that:

- the guest gave the installer a terminal;
- pauses answered equals `[sudo]   $ sudo` lines printed;
- both equal the count the installer reports, when it reaches its summary (an
  invocation that exits early reports none, which is not a failure);
- the password was asked for exactly once, or not at all when the installer refuses to start phase 2 because `/nix` is missing, which it reports before it asks;
- the installer exited as the playbook expects.

Every playbook also fails if the guest's `sw_vers -productVersion` does not
start with 26, or if no pause was answered. The sudo commands the installer
printed must match [expected-sudo-commands.txt](expected-sudo-commands.txt):
`happy-zsh`, `happy-bash` and `phase2-launchdaemon-broken` print all of them,
and the other playbooks the list up to where they stop.

The driver waits at most 60 seconds for each prompt and fails with the last
screen. A reboot fails after 5 minutes and a playbook after 1 hour.

## Output and the report

The suite saves each playbook's terminal output to
`test/output/<commit>/<playbook>.txt`, under the commit checked out (the working
tree must be clean). After a run, append a line to [runs.jsonl](runs.jsonl)
and rebuild [REPORT.md](../REPORT.md) and the badge at the top of the README:

```sh
test/bin/build-report
```

## Debugging

```sh
KEEP_VM=1 test/bin/nix-test-vm playbook happy-zsh
test/bin/nix-test-vm list
test/bin/nix-test-vm ssh nix-test-happy-zsh-12345
test/bin/nix-test-vm clean     # delete leftover nix-test-* VMs
```

Before a VM run, `devenv shell -- check` runs the unit tests and lint.
