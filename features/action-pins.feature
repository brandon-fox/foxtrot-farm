# Decision: docs/decisions/0002-pin-actions-to-sha.md
# Steps: tests/check-action-pins.test.sh
Feature: Action pinning
  Every GitHub Action a workflow uses is pinned to a full commit SHA.

  Scenario: A workflow uses a tag
    Given a workflow step with "uses: actions/checkout@v4"
    When the pin check runs
    Then it fails
    And it names the file, line and reference

  Scenario: A workflow uses a branch or a short SHA
    Given a workflow step that uses "@main" or a 7-character SHA
    When the pin check runs
    Then it fails

  Scenario: A workflow uses a full SHA
    Given a workflow step with "uses: actions/checkout@<40-char-sha> # v4.4.0"
    When the pin check runs
    Then it passes

  Scenario: Local actions and digest-pinned images
    Given a step that uses "./my-action" or "docker://image@sha256:<digest>"
    When the pin check runs
    Then it passes

  Scenario: The checker itself is tested
    Given a change to the pin check or its tests
    When CI runs
    Then the unit tests pass
    And every mutant of the pin check is killed by the unit tests
    And main accepts no commit whose required checks have not passed
