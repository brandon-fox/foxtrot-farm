# 0003: Branch protection for main

- Status: Accepted
- Date: 2026-11-26
- Revisit: when any central-repo trigger below fires

## Question

How should main's protection be defined, applied and kept from drifting, so agents can't bypass the checks?

## Why it needs a decision

GitHub doesn't read rulesets from files in the repo, so a JSON file on main does nothing by itself. Applying protection needs admin rights, and agent sessions can't change repo settings. Nothing noticed if the protection was missing or loosened.

## Inputs

- Reading a repo's rulesets needs only Metadata read, which CI's default token has. Creating or updating one needs admin. Source: https://docs.github.com/en/rest/repos/rules (read 2026-11-26).
- `bypass_actors` is only returned to admins. VERIFY: CI's read-only check therefore can't see a bypass actor; `scripts/ruleset.sh check` run by an admin can.
- GitHub Free: protected branches for private repos are a Pro feature; private repos get 2,000 Actions minutes a month. Source: https://docs.github.com/en/get-started/learning-about-github/githubs-plans (read 2026-11-26).
- Fine-grained tokens can be limited to selected repos and default to 30-day expiry. Source: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens (read 2026-11-26).
- safe-settings is documented for organizations, with an `admin` repo; personal accounts aren't mentioned. Source: https://github.com/github-community-projects/safe-settings (read 2026-11-26).
- This is a one-time setup for one repo. Don't over-engineer it.

## Options

1. **ADR only.** Cheapest. Cons: nothing notices drift.
2. **Per-repo apply script, drift check in CI (chosen).** `scripts/ruleset.sh` holds the ruleset. The owner runs `apply` once with their own login; `check` runs in CI on every PR, on push to main and daily. No admin token in the repo. Cons: applying stays a manual step from a laptop, or the GitHub UI on a phone.
3. **Settings app (third-party).** Syncs `.github/settings.yml`. Cons: its own page warns it gives anyone who can push admin power; classic branch protection only, no rulesets.
4. **Central private admin repo.** One private repo holds an admin token (fine-grained, Administration write on selected repos) and a workflow that runs each repo's own `scripts/ruleset.sh apply` on change and on a schedule.
   - Pros: one place for every repo; drift is repaired, not just reported; editable from a phone; public repos still carry no admin token.
   - Cons: it becomes the most sensitive repo. On Free its own main can't be protected (private), so any session with push access to it can loosen protection everywhere. The token must be rotated. It spends private Actions minutes. safe-settings doesn't cover personal accounts, so it would be homegrown.
5. **Terraform or Pulumi.** Real infrastructure as code. Cons: an admin token plus state storage, heavy for one repo.

## Decision

Option 2. Apply once with `scripts/ruleset.sh apply` (or the GitHub UI with the same settings) and let CI report drift.

## Central-repo triggers

Move to option 4 only when one of these holds:

- Three or more repos need the same protection and a change has had to be made in each by hand.
- Drift has happened and needs automatic repair, not just a failed check.
- Protection must change while away from a laptop, and the UI route has failed.
- A second person or an organization gets admin on these repos.

Until then, each repo keeps its own `scripts/ruleset.sh`.

## Behaviour

[features/branch-protection.feature](../../features/branch-protection.feature)

## Consequences

- CI fails until the ruleset is applied once. That failure is the reminder.
- A change to protection is a PR to `scripts/ruleset.sh`, then `scripts/ruleset.sh apply` after merge.
