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

Pin every action to a full commit SHA with the version as a comment. `scripts/check-action-pins.sh` enforces it in pre-commit and in the `Action pins` CI workflow. Dependabot bumps pins monthly. Agent rules live in `AGENTS.md`.

## Behaviour

Feature: Action pinning
  Scenario: A workflow uses a tag
    Given a workflow step with `uses: actions/checkout@v4`
    When the pre-commit hook or the Action pins check runs
    Then it fails and names the file, line and reference

  Scenario: A workflow uses a full SHA
    Given `uses: actions/checkout@<40-char-sha> # v4.4.0`
    When the check runs
    Then it passes

  Scenario: Local actions and digest-pinned images
    Given `uses: ./my-action` or `uses: docker://image@sha256:<digest>`
    When the check runs
    Then it passes
