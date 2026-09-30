# Run history

A passing run means: a fresh macOS VM, the installer run through its three phases across
a real reboot, answered as a person would. The password is typed at sudo's own prompt and
Enter is pressed at every pause the installer prints.

One row per macOS and Nix combination, showing its newest run, whether it passed or failed.

| Result | macOS | Nix | Commit | Date |
|---|---|---|---|---|

To reproduce a run, see [test/README.md](test/README.md).
[test/runs.jsonl](test/runs.jsonl) is the source of the table; `test/bin/build-report` builds this page.

## Terminal output
