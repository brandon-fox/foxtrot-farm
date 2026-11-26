#!/usr/bin/env bash
# Fails if any GitHub Actions `uses:` reference is not pinned to a full 40-character commit SHA.
# Allowed: local actions (./path) and docker images pinned by digest (docker://image@sha256:...).
# Usage: scripts/check-action-pins.sh [file ...]   (defaults to every workflow and action file)
set -euo pipefail

if [ "$#" -gt 0 ]; then
  files=("$@")
else
  mapfile -t files < <(find .github -type f \( -name '*.yml' -o -name '*.yaml' \) 2>/dev/null | sort)
fi

status=0
for f in "${files[@]}"; do
  [ -f "$f" ] || continue
  while IFS= read -r hit; do
    line="${hit%%:*}"
    ref="$(printf '%s' "${hit#*:}" | sed -E 's/^[[:space:]]*-?[[:space:]]*uses:[[:space:]]*//; s/[[:space:]]+#.*$//; s/^["'\'']//; s/["'\'']$//')"
    case "$ref" in
      ./*) continue ;;
      docker://*@sha256:*) continue ;;
    esac
    if ! printf '%s' "$ref" | grep -Eq '@[0-9a-f]{40}$'; then
      echo "$f:$line: not pinned to a commit SHA: $ref"
      status=1
    fi
  done < <(grep -nE '^[[:space:]]*-?[[:space:]]*uses:' "$f" || true)
done

if [ "$status" -ne 0 ]; then
  echo
  echo "Pin each action to a full commit SHA with the version as a comment, e.g."
  echo "  uses: actions/checkout@<40-char-sha> # v4.4.0"
  echo "See docs/decisions/0002-pin-actions-to-sha.md"
fi
exit "$status"
