# 0002: Pin GitHub Actions to commit SHAs

- Status: Accepted
- Date: 2026-11-26

## Question

How should workflows reference third-party GitHub Actions?

## Why it needs a decision

The Pages workflow GitHub generated uses tags (`@v4`, `@v5`). A tag can be moved to different code at any time, so a compromised or changed action would run in our deploy job with Pages and OIDC token permissions.

## Inputs

- A full commit SHA is the only reference that can't be changed after the fact.
- Dependabot can keep SHA pins current and updates the version comment with them.
- VERIFY: whether repo settings should also enforce SHA pinning (Settings > Actions > General) once that setting is available for this account.

## Options

1. **Tags (`@v4`).** Easy to read, and they pick up fixes automatically. Cons: mutable, so the supply-chain risk stays.
2. **Full SHAs plus a version comment, enforced by a pre-commit hook and a CI check (chosen).** Immutable and checked mechanically. Cons: harder to read, and updates need Dependabot or a manual bump.
3. **SHAs by convention only.** No tooling. Cons: drifts the first time someone pastes a snippet.

## Decision

Pin every action to a full commit SHA with the version as a comment. Dependabot bumps pins monthly.

## Enforcement

- Check: `scripts/check-action-pins.sh`, run by pre-commit and the `Action pins` workflow.
- Unit tests: `tests/check-action-pins.test.sh`. Mutation tests: `tests/mutation.sh` fail if any mutant of the check survives.
- Required checks on `main` (no bypass): [.github/rulesets/main.json](../../.github/rulesets/main.json).
- To pin an action: `git ls-remote https://github.com/OWNER/REPO 'refs/tags/TAG^{}' refs/tags/TAG`, then write the SHA with `# TAG`.

## Behaviour

[features/action-pins.feature](../../features/action-pins.feature)
