#!/usr/bin/env bash
# Unit tests for scripts/ruleset.sh against a fake gh. Steps for features/branch-protection.feature.
# Usage: tests/ruleset.test.sh   (SUT=path overrides the script under test)
set -uo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
sut="$(cd "$root" && realpath "${SUT:-scripts/ruleset.sh}")"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
pass=0 fail=0

# Fake gh: GET rulesets -> list.json, GET rulesets/ID -> live.json, POST/PUT -> sent.json (and becomes live).
cat >"$work/gh" <<'FAKE'
#!/usr/bin/env bash
d="$FAKE_DIR"
echo "$*" >>"$d/calls"
if [ "$1" = repo ]; then echo "from/gh"; exit 0; fi
case "$*" in
  "api -X POST repos/"*"/rulesets --input -" | "api -X PUT repos/"*"/rulesets/7 --input -")
    cat >"$d/sent.json"; cp "$d/sent.json" "$d/live.json"; echo '[{"id":7,"name":"main: required checks"}]' >"$d/list.json" ;;
  "api repos/"*"/rulesets") cat "$d/list.json" ;;
  "api repos/"*"/rulesets/7") cat "$d/live.json" ;;
  *) echo "unexpected gh call: $*" >&2; exit 9 ;;
esac
FAKE
chmod +x "$work/gh"

desired="$(bash "$sut" print)"
listed='[{"id":3,"name":"other"},{"id":7,"name":"main: required checks"}]'

# run NAME WANT_EXIT CMD LIST LIVE_JQ [OUTPUT_SUBSTRING]   LIVE_JQ edits the desired ruleset into the live one.
run() {
  local name="$1" want="$2" cmd="$3" list="$4" edit="$5" expect="${6:-}" out got
  d="$work/case"
  rm -rf "$d" && mkdir -p "$d"
  printf '%s\n' "$list" >"$d/list.json"
  jq "$edit" <<<"$desired" >"$d/live.json"
  out="$(FAKE_DIR="$d" GH="$work/gh" REPO=o/r bash "$sut" "$cmd" 2>&1)"
  got=$?
  if [ "$got" -ne "$want" ] || { [ -n "$expect" ] && [[ "$out" != *"$expect"* ]]; }; then
    echo "FAIL: $name (exit $got, want $want)"
    printf '%s\n' "$out" | sed 's/^/  /'
    fail=$((fail + 1))
  else
    pass=$((pass + 1))
  fi
}
ok() { pass=$((pass + 1)); }
bad() {
  echo "FAIL: $1"
  fail=$((fail + 1))
}

# Scenario: The desired ruleset protects main
spec='.name == "main: required checks" and .target == "branch" and .enforcement == "active" and .bypass_actors == []
  and .conditions.ref_name.include == ["~DEFAULT_BRANCH"]
  and ([.rules[].type] | sort) == ["deletion", "non_fast_forward", "required_status_checks"]
  and (.rules[] | select(.type == "required_status_checks") | .parameters.required_status_checks) == [{"context": "pre-commit", "integration_id": 15368}]'
if jq -e "$spec" <<<"$desired" >/dev/null; then ok; else bad "desired ruleset matches the decision"; fi

# Scenario: The live ruleset matches
run "match passes" 0 check "$listed" '. + {id: 7, source: "o/r", _links: {}}' 'matches'
run "unsorted rules pass" 0 check "$listed" '.rules |= reverse'
run "server defaults pass" 0 check "$listed" '(.rules[] | select(.type == "required_status_checks") | .parameters.do_not_enforce_on_create) = false'
run "hidden bypass list passes" 0 check "$listed" 'del(.bypass_actors)'
# Scenario: The ruleset is missing
run "missing fails" 1 check '[]' '.' 'is missing on o/r'
run "other names only fails" 1 check '[{"id":3,"name":"other"}]' '.' 'is missing'
run "missing names the fix" 1 check '[]' '.' 'scripts/ruleset.sh apply'
# Scenario: The live ruleset drifted
run "disabled fails" 1 check "$listed" '.enforcement = "disabled"' 'differs'
run "evaluate fails" 1 check "$listed" '.enforcement = "evaluate"'
run "tag target fails" 1 check "$listed" '.target = "tag"'
run "other branch fails" 1 check "$listed" '.conditions.ref_name.include = ["refs/heads/dev"]'
run "bypass actor fails" 1 check "$listed" '.bypass_actors = [{"actor_id": 5, "actor_type": "RepositoryRole", "bypass_mode": "always"}]'
run "dropped rule fails" 1 check "$listed" '.rules |= map(select(.type != "non_fast_forward"))'
run "extra rule fails" 1 check "$listed" '.rules += [{"type": "creation"}]'
run "renamed check fails" 1 check "$listed" '(.rules[] | select(.type == "required_status_checks") | .parameters.required_status_checks[0].context) = "ci"'
run "any-source check fails" 1 check "$listed" '(.rules[] | select(.type == "required_status_checks") | .parameters.required_status_checks[0]) |= del(.integration_id)'
run "extra check fails" 1 check "$listed" '(.rules[] | select(.type == "required_status_checks") | .parameters.required_status_checks) += [{"context": "x"}]'
run "strict policy change fails" 1 check "$listed" '(.rules[] | select(.type == "required_status_checks") | .parameters.strict_required_status_checks_policy) = true'
run "drift names the fix" 1 check "$listed" '.enforcement = "disabled"' 'scripts/ruleset.sh apply'

# Scenario: Applying the ruleset
run "apply creates when missing and reads back" 0 apply '[]' '.' 'matches'
if grep -qx 'api -X POST repos/o/r/rulesets --input -' "$d/calls" && ! grep -q PUT "$d/calls"; then ok; else bad "apply posts once"; fi
if jq -e --argjson w "$desired" '. == $w' "$d/sent.json" >/dev/null; then ok; else bad "apply sends the desired ruleset"; fi
run "apply updates when present" 0 apply "$listed" '.enforcement = "disabled"' 'updated ruleset 7'
if grep -qx 'api -X PUT repos/o/r/rulesets/7 --input -' "$d/calls" && ! grep -q POST "$d/calls"; then ok; else bad "apply puts to the existing id"; fi
if grep -q 'matches' <(FAKE_DIR="$d" GH="$work/gh" REPO=o/r bash "$sut" check); then ok; else bad "apply leaves no drift"; fi

# Repo selection and usage
d="$work/repo" && mkdir -p "$d" && echo '[]' >"$d/list.json"
FAKE_DIR="$d" GH="$work/gh" GITHUB_REPOSITORY=ci/repo bash "$sut" check >/dev/null 2>&1
if grep -qx 'api repos/ci/repo/rulesets' "$d/calls"; then ok; else bad "uses GITHUB_REPOSITORY"; fi
: >"$d/calls"
FAKE_DIR="$d" GH="$work/gh" GITHUB_REPOSITORY='' bash "$sut" check >/dev/null 2>&1
if grep -qx 'api repos/from/gh/rulesets' "$d/calls"; then ok; else bad "falls back to the gh repo"; fi
out="$(bash "$sut" nope 2>&1)"
got=$?
if [ "$got" -eq 2 ] && [[ "$out" == *usage* ]]; then ok; else bad "unknown command exits 2 with usage"; fi
out="$(bash "$sut" 2>&1)"
got=$?
if [ "$got" -eq 2 ]; then ok; else bad "no command exits 2"; fi

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
