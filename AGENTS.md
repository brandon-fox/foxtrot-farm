# Agent rules for this repo

These rules apply to every coding agent (Claude, Gemini, Copilot and others) and to people.

## GitHub Actions are pinned to commit SHAs

- Every `uses:` in `.github/` points at a full 40-character commit SHA, followed by the version as a comment:
  `uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0`
- Never use a tag (`@v4`), branch (`@main`) or short SHA. Local actions (`./path`) and docker images pinned by digest are fine.
- To add or update an action: resolve the release tag to its commit SHA from the action's own repository (`git ls-remote https://github.com/OWNER/REPO refs/tags/TAG 'refs/tags/TAG^{}'`; use the `^{}` line when present), then write the SHA and the tag comment.
- Run `scripts/check-action-pins.sh` before committing. The pre-commit hook and the `Action pins` CI check run the same script; don't bypass, skip or disable either.
- Why: docs/decisions/0002-pin-actions-to-sha.md

## Public repo hygiene

- Commit as `32090240+brandon-fox@users.noreply.github.com`. No personal emails, local paths, usernames or machine names in files, commits or PRs.
- The farm is a truck farm and nursery. Never call it a garden.
