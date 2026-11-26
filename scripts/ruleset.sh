#!/usr/bin/env bash
# Branch protection for main, as code. Decision: docs/decisions/0003-branch-protection.md
# Usage: scripts/ruleset.sh check   Read-only. Fails if the live ruleset is missing or differs.
#        scripts/ruleset.sh apply   Creates or updates the ruleset, then checks it. Needs repo admin.
#        scripts/ruleset.sh print   Prints the desired ruleset.
# Env:   REPO=owner/name (default: GITHUB_REPOSITORY, then the current gh repo). GH=gh command.
set -euo pipefail

name="main: required checks"

desired() {
  cat <<'JSON'
{
  "name": "main: required checks",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
  "bypass_actors": [],
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": false,
        "required_status_checks": [{ "context": "pre-commit", "integration_id": 15368 }]
      }
    }
  ]
}
JSON
}

# Sorts the arrays whose order GitHub doesn't keep.
norm='def norm: if type == "object" then
    (if has("rules") then .rules |= sort_by(.type) else . end) | map_values(norm)
  elif type == "array" then map(norm) else . end;'

# True when every field of $want is in the live ruleset with the same value. Arrays must match in full.
# bypass_actors is only returned to admins, so a read-only check skips it when it is absent.
# shellcheck disable=SC2016 # jq program, not shell
matches="$norm"'
def sub($a; $b): if ($a | type) == "object" then ($b | type) == "object"
    and all($a | keys[]; . as $k | sub($a[$k]; $b[$k]))
  elif ($a | type) == "array" then ($b | type) == "array" and ($a | length) == ($b | length)
    and all(range(0; $a | length); . as $i | sub($a[$i]; $b[$i]))
  else $a == $b end;
($want | norm) as $w | (norm | if has("bypass_actors") then . else .bypass_actors = $w.bypass_actors end) as $l
| sub($w; $l)'

gh_cmd="${GH:-gh}"
repo="${REPO:-${GITHUB_REPOSITORY:-}}"

find_id() {
  "$gh_cmd" api "repos/$repo/rulesets" | jq -r --arg n "$name" '[.[] | select(.name == $n) | .id][0] // empty'
}

check() {
  local id live
  id="$(find_id)"
  if [ -z "$id" ]; then
    echo "drift: ruleset \"$name\" is missing on $repo"
    echo "Fix: scripts/ruleset.sh apply (see docs/decisions/0003-branch-protection.md)"
    return 1
  fi
  live="$("$gh_cmd" api "repos/$repo/rulesets/$id")"
  if ! jq -e --argjson want "$(desired)" "$matches" <<<"$live" >/dev/null; then
    echo "drift: ruleset \"$name\" ($id) on $repo differs from scripts/ruleset.sh"
    diff <(desired | jq -S "$norm norm") <(jq -S "$norm norm | {name, target, enforcement, conditions, bypass_actors, rules}" <<<"$live") || true
    echo "Fix: scripts/ruleset.sh apply (see docs/decisions/0003-branch-protection.md)"
    return 1
  fi
  echo "ok: ruleset \"$name\" ($id) on $repo matches"
}

apply() {
  local id
  id="$(find_id)"
  if [ -n "$id" ]; then
    desired | "$gh_cmd" api -X PUT "repos/$repo/rulesets/$id" --input - >/dev/null
    echo "updated ruleset $id"
  else
    desired | "$gh_cmd" api -X POST "repos/$repo/rulesets" --input - >/dev/null
    echo "created ruleset"
  fi
  check # read back
}

case "${1:-}" in
  print) desired ;;
  check | apply)
    [ -n "$repo" ] || repo="$("$gh_cmd" repo view --json nameWithOwner --jq .nameWithOwner)"
    "$1"
    ;;
  *)
    echo "usage: scripts/ruleset.sh check|apply|print" >&2
    exit 2
    ;;
esac
