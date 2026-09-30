#!/usr/bin/env bats

load test_helper

setup() {
  load_libs
  export RUNS_FILE="${BATS_TEST_TMPDIR}/runs.jsonl"
  export OUTPUT_DIR="${BATS_TEST_TMPDIR}/output"
  export REPORT_FILE="${BATS_TEST_TMPDIR}/REPORT.md"
  export README_FILE="${BATS_TEST_TMPDIR}/README.md"
  printf '# title\n\n[![tested on old](https://img.shields.io/badge/old)](REPORT.md)\n\ntext\n' > "$README_FILE"
}

run_line() {  # date commit macos nix result playbooks-json
  printf '{"date":"%s","commit":"%s","macos":"%s","nix":"%s","arch":"arm64","result":"%s","playbooks":%s}\n' "$@" >> "$RUNS_FILE"
}

build() { "${REPO_ROOT}/test/bin/build-report"; }

@test "one row per macOS and Nix combination, showing its newest run" {
  run_line 2026-09-28 aaaaaaa1111 26.6.2 2.35.2 pass '{"happy-zsh":"pass"}'
  run_line 2026-09-29 bbbbbbb2222 26.6.2 2.35.2 fail '{"happy-zsh":"fail"}'
  build
  run grep -c '^|' "$REPORT_FILE"
  assert_output 3   # header, separator, one row
  run grep '^| ❌ fail | 26.6.2 | 2.35.2 | `bbbbbbb` | 2026-09-29 |' "$REPORT_FILE"
  assert_success
}

@test "rows sort by macOS then Nix, highest first" {
  run_line 2026-09-01 aaaaaaa1111 26.6.2 2.9.1 pass '{"happy-zsh":"pass"}'
  run_line 2026-09-02 bbbbbbb2222 26.6.2 2.35.2 pass '{"happy-zsh":"pass"}'
  run_line 2026-09-03 ccccccc3333 15.7 2.35.2 pass '{"happy-zsh":"pass"}'
  run_line 2026-09-04 ddddddd4444 26.10 2.9.1 pass '{"happy-zsh":"pass"}'
  build
  run grep -o '^| [^|]*| [0-9.]* | [0-9.]* |' "$REPORT_FILE"
  assert_line --index 0 --partial "26.10 | 2.9.1"
  assert_line --index 1 --partial "26.6.2 | 2.35.2"
  assert_line --index 2 --partial "26.6.2 | 2.9.1"
  assert_line --index 3 --partial "15.7 | 2.35.2"
}

@test "a run's saved output goes in one collapsed section per playbook" {
  run_line 2026-09-29 bbbbbbb2222 26.6.2 2.35.2 pass '{"happy-zsh":"pass","happy-bash":"pass"}'
  mkdir -p "$OUTPUT_DIR/bbbbbbb"
  echo "zsh session <raw>" > "$OUTPUT_DIR/bbbbbbb/happy-zsh.txt"
  echo "bash session" > "$OUTPUT_DIR/bbbbbbb/happy-bash.txt"
  build
  run grep -c '^<details>' "$REPORT_FILE"
  assert_output 2
  run grep -F 'zsh session <raw>' "$REPORT_FILE"
  assert_success
  run grep '<summary>happy-bash: pass</summary>' "$REPORT_FILE"
  assert_success
}

@test "a run with no saved output says so" {
  run_line 2026-09-29 bbbbbbb2222 26.6.2 2.35.2 pass '{"happy-zsh":"pass"}'
  build
  run grep 'No terminal output was saved' "$REPORT_FILE"
  assert_success
}

@test "the page opens by saying what a passing run means" {
  run_line 2026-09-29 bbbbbbb2222 26.6.2 2.35.2 pass '{"happy-zsh":"pass"}'
  build
  run sed -n 3,4p "$REPORT_FILE"
  assert_output --partial "fresh macOS VM"
  run grep -F '[test/README.md](test/README.md)' "$REPORT_FILE"
  assert_success
}

@test "the README badge names the newest passing line, not a newer failing one" {
  run_line 2026-09-01 aaaaaaa1111 26.6.2 2.34.6 pass '{"happy-zsh":"pass"}'
  run_line 2026-09-02 bbbbbbb2222 26.6.2 2.35.2 pass '{"happy-zsh":"pass"}'
  run_line 2026-09-03 ccccccc3333 26.6.3 2.36.0 fail '{"happy-zsh":"fail"}'
  build
  run grep '^\[!\[tested on' "$README_FILE"
  assert_output '[![tested on macOS 26.6.2, Nix 2.35.2](https://img.shields.io/badge/tested%20on-macOS%2026.6.2,%20Nix%202.35.2-brightgreen)](REPORT.md)'
  run grep -c 'tested on' "$README_FILE"
  assert_output 1   # one badge line, not a second one
  run grep -c '^text$' "$README_FILE"
  assert_output 1
}

@test "the README badge says no run has passed when none has" {
  run_line 2026-09-03 ccccccc3333 26.6.2 2.35.2 fail '{"happy-zsh":"fail"}'
  build
  run grep -c 'no passing run' "$README_FILE"
  assert_success
}

@test "link text on the page has no backticks" {
  run_line 2026-09-29 bbbbbbb2222 26.6.2 2.35.2 pass '{"happy-zsh":"pass"}'
  build
  run grep -F '[`' "$REPORT_FILE"
  assert_failure 1   # grep found no match; 2 would mean grep itself errored
}
