#!/usr/bin/env bash
# Runs every tests/*.test.sh.
set -uo pipefail
status=0
for t in "$(dirname "$0")"/*.test.sh; do
  echo "== $(basename "$t")"
  bash "$t" || status=1
done
exit "$status"
