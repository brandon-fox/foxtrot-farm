#!/usr/bin/env bash
# Mutation tests: every mutant in tests/mutants/NAME.txt of scripts/NAME.sh must make tests/NAME.test.sh fail.
# Each line: literal text to find (first match), a tab, and its replacement.
# A surviving mutant means behaviour the tests don't pin down. Add a test, or remove dead code.
set -uo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
killed=0 survived=0

for list in "$root"/tests/mutants/*.txt; do
  name="$(basename "$list" .txt)"
  src="$root/scripts/$name.sh"
  tests="$root/tests/$name.test.sh"
  if ! SUT="$src" bash "$tests" >/dev/null 2>&1; then
    echo "$name: unit tests fail on the unmutated script; fix them first."
    exit 1
  fi
  original="$(cat "$src")"
  while IFS= read -r m || [ -n "$m" ]; do
    [ -n "$m" ] || continue
    from="${m%%$'\t'*}" to="${m#*$'\t'}"
    if [[ "$original" != *"$from"* ]]; then
      echo "STALE: $name: mutant no longer matches the script: $from"
      survived=$((survived + 1))
      continue
    fi
    printf '%s\n' "${original/"$from"/"$to"}" >"$work/mutant.sh"
    if SUT="$work/mutant.sh" bash "$tests" >/dev/null 2>&1; then
      echo "SURVIVED: $name: $from  ->  $to"
      survived=$((survived + 1))
    else
      killed=$((killed + 1))
    fi
  done <"$list"
done

echo "$killed killed, $survived survived"
[ "$survived" -eq 0 ]
