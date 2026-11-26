#!/usr/bin/env bash
# Mutation tests: each mutant of scripts/check-action-pins.sh must make the unit tests fail.
# A surviving mutant means behaviour the tests don't pin down. Add a test, or remove dead code.
set -uo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
src="$root/scripts/check-action-pins.sh"
tests="$root/tests/check-action-pins.test.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# Each mutant: literal text to find (first match), a tab, and its replacement.
mapfile -t mutants <<'MUTANTS'
{40}$	{7}$
{40}$	{39}$
@[0-9a-f]{40}$	[0-9a-f]{40}$
@[0-9a-f]{40}$	@[0-9a-f]{40}
[0-9a-f]{40}	[0-9a-fA-F]{40}
      status=1	      status=0
exit "$status"	exit 0
      ./*) continue ;;	      *) continue ;;
docker://*@sha256:*) continue	docker://*) continue
-name '*.yaml'	-name '*.none'
-name '*.yml'	-name '*.none'
s/[[:space:]]+#.*$//; 	
s/^["'\'']//; 	
s/["'\'']$//	s/x$//
grep -nE '^[[:space:]]*-?[[:space:]]*uses:'	grep -nE '^[[:space:]]*uses:'
grep -nE '^[[:space:]]*-?[[:space:]]*uses:'	grep -nE '^[[:space:]]*-?[[:space:]]*uses: '
echo "$f:$line: not	echo "$f: not
  echo "See docs/decisions/0002-pin-actions-to-sha.md"	  true
MUTANTS

if ! CHECKER="$src" bash "$tests" >/dev/null 2>&1; then
  echo "Unit tests fail on the unmutated script; fix them first."; exit 1
fi

original="$(cat "$src")"
killed=0 survived=0
for m in "${mutants[@]}"; do
  from="${m%%$'\t'*}" to="${m#*$'\t'}"
  if [[ "$original" != *"$from"* ]]; then
    echo "STALE: mutant no longer matches the script: $from"; survived=$((survived + 1)); continue
  fi
  printf '%s\n' "${original/"$from"/"$to"}" > "$work/mutant.sh"
  if CHECKER="$work/mutant.sh" bash "$tests" >/dev/null 2>&1; then
    echo "SURVIVED: $from  ->  $to"; survived=$((survived + 1))
  else
    killed=$((killed + 1))
  fi
done

echo "$killed killed, $survived survived"
[ "$survived" -eq 0 ]
