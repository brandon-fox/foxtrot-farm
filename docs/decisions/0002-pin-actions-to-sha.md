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

- Hooks in [.pre-commit-config.yaml](../../.pre-commit-config.yaml) are the only definition of the checks: the pin check, its unit tests and its mutation tests (any surviving mutant fails).
- CI runs `pre-commit run --all-files`; that `pre-commit` check is required on `main` with no bypass: [.github/rulesets/main.json](../../.github/rulesets/main.json).
- To pin an action: `git ls-remote https://github.com/OWNER/REPO 'refs/tags/TAG^{}' refs/tags/TAG`, then write the SHA with `# TAG`.

## Behaviour

[features/action-pins.feature](../../features/action-pins.feature)
