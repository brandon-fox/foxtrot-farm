# Decision: docs/decisions/0003-branch-protection.md
# Steps: tests/ruleset.test.sh
Feature: Branch protection on main
  main only accepts commits that passed the pre-commit check, and nobody can bypass it.

  Scenario: The desired ruleset protects main
    Given scripts/ruleset.sh
    When it prints the desired ruleset
    Then main requires the "pre-commit" check from GitHub Actions
    And main cannot be deleted or force-pushed
    And the bypass list is empty

  Scenario: The live ruleset matches
    Given the live ruleset matches the desired one, apart from fields GitHub adds
    When the drift check runs
    Then it passes

  Scenario: The ruleset is missing or drifted
    Given the live ruleset is missing, or any desired field differs
    When the drift check runs
    Then it fails
    And it names the fix: scripts/ruleset.sh apply

  Scenario: Applying the ruleset
    Given an admin runs scripts/ruleset.sh apply
    When the ruleset is missing it is created, otherwise it is updated in place
    Then the script reads it back and the drift check passes
