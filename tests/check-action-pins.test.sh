#!/usr/bin/env bash
# Unit tests for scripts/check-action-pins.sh. Steps for features/action-pins.feature.
# Usage: tests/check-action-pins.test.sh   (CHECKER=path overrides the script under test)
set -uo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
checker="$(cd "$root" && realpath "${CHECKER:-scripts/check-action-pins.sh}")"
sha="11d5960a326750d5838078e36cf38b85af677262"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
pass=0 fail=0

# run NAME EXPECTED_EXIT YAML [EXPECTED_OUTPUT_SUBSTRING]
run() {
  local name="$1" want="$2" yaml="$3" expect="${4:-}" f out got
  f="$work/$pass-$fail.yml"
  printf '%s\n' "$yaml" >"$f"
  out="$(bash "$checker" "$f" 2>&1)"
  got=$?
  if [ "$got" -ne "$want" ] || { [ -n "$expect" ] && [[ "$out" != *"$expect"* ]]; }; then
    echo "FAIL: $name (exit $got, want $want)"
    printf '%s\n' "$out" | sed 's/^/  /'
    fail=$((fail + 1))
  else
    pass=$((pass + 1))
  fi
}

step() { printf 'jobs:\n  a:\n    steps:\n      - uses: %s\n' "$1"; }

# Scenario: A workflow uses a tag
run "tag fails" 1 "$(step actions/checkout@v4)" "not pinned to a commit SHA: actions/checkout@v4"
run "failure names file and line" 1 "$(step actions/checkout@v4)" ".yml:4:"
run "failure prints the fix hint" 1 "$(step actions/checkout@v4)" "docs/decisions/0002-pin-actions-to-sha.md"
run "tag with comment fails" 1 "$(step 'actions/checkout@v4 # v4')"
# Scenario: A workflow uses a branch or a short SHA
run "branch fails" 1 "$(step actions/checkout@main)"
run "short SHA fails" 1 "$(step actions/checkout@11d5960)"
run "39-char SHA fails" 1 "$(step "actions/checkout@${sha:0:39}")"
run "41-char ref fails" 1 "$(step "actions/checkout@${sha}a")"
run "uppercase hex fails" 1 "$(step "actions/checkout@${sha^^}")"
run "no ref fails" 1 "$(step actions/checkout)"
# Scenario: A workflow uses a full SHA
run "full SHA passes" 0 "$(step "actions/checkout@$sha")"
run "full SHA with comment passes" 0 "$(step "actions/checkout@$sha # v4.4.0")"
run "double-quoted SHA passes" 0 "$(step "\"actions/checkout@$sha\"")"
run "single-quoted SHA passes" 0 "$(step "'actions/checkout@$sha'")"
run "success prints nothing" 0 "$(step "actions/checkout@$sha")"
out="$(bash "$checker" /dev/null 2>&1)"
if [ -z "$out" ]; then
  pass=$((pass + 1))
else
  echo "FAIL: empty input is silent"
  fail=$((fail + 1))
fi
# Scenario: Local actions and digest-pinned images
run "local action passes" 0 "$(step ./my-action)"
run "quoted local action passes" 0 "$(step "\"./my-action\"")"
run "docker digest passes" 0 "$(step "docker://alpine@sha256:$sha$sha")"
run "docker tag fails" 1 "$(step docker://alpine:3)"
# Where references are found
run "job-level uses is checked" 1 "$(printf 'jobs:\n  a:\n    uses: org/repo/.github/workflows/x.yml@main\n')"
run "value on the next line is checked" 1 "$(printf '      - uses:\n          actions/checkout@v4\n')"
run "commented-out uses is ignored" 0 "$(printf '      # - uses: actions/checkout@v4\n')"
run "every violation is reported" 1 "$(
  step actions/checkout@v4
  printf '      - uses: actions/setup-node@v4\n'
)" "actions/setup-node@v4"
run "one bad pin among good ones fails" 1 "$(
  step "actions/checkout@$sha"
  printf '      - uses: actions/setup-node@v4\n'
)"

# Missing files are skipped
out="$(bash "$checker" "$work/missing.yml" 2>&1)"
got=$?
if [ "$got" -eq 0 ]; then
  pass=$((pass + 1))
else
  echo "FAIL: missing file is skipped (exit $got)"
  fail=$((fail + 1))
fi

# With no arguments it scans .github for .yml and .yaml files
repo="$work/repo"
mkdir -p "$repo/.github/workflows" "$repo/.github/actions/x"
step "actions/checkout@$sha" >"$repo/.github/workflows/ok.yml"
step actions/checkout@v4 >"$repo/.github/actions/x/action.yaml"
out="$(cd "$repo" && bash "$checker" 2>&1)"
got=$?
if [ "$got" -eq 1 ] && [[ "$out" == *"action.yaml:4:"* ]]; then pass=$((pass + 1)); else
  echo "FAIL: default scan finds .yaml (exit $got)"
  fail=$((fail + 1))
fi
step actions/checkout@v4 >"$repo/.github/workflows/bad.yml"
rm "$repo/.github/actions/x/action.yaml"
out="$(cd "$repo" && bash "$checker" 2>&1)"
got=$?
if [ "$got" -eq 1 ] && [[ "$out" == *"bad.yml:4:"* ]]; then pass=$((pass + 1)); else
  echo "FAIL: default scan finds .yml (exit $got)"
  fail=$((fail + 1))
fi

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
