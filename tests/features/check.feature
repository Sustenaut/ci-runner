Feature: check.sh refuses an image that lacks what pubrules's workflows call
  The build workflow runs check.sh inside the image, and the first thing
  missing fails the build. Here it runs outside any image, with stand-in
  programs on PATH, so each refusal is seen on its own.

  Background:
    Given a scratch directory
    And a file "check.sh" copied from "check.sh"
    And every tool check.sh looks for is installed

  Scenario: An image that runs as root is refused
    Given a stand-in "id" that prints "root"
    When I run "bash check.sh"
    Then it fails
    And stderr mentions "the image must run as runner, not root"
    And "id" was run with "-un"

  Scenario Outline: An image without <tool> is refused, naming it
    Given a stand-in "id" that prints "runner"
    But "<tool>" is not installed
    When I run "bash check.sh"
    Then it fails
    And stderr mentions "missing: <tool>"

    Examples:
      | tool       |
      | git        |
      | shellcheck |
      | docker     |
      | nc         |

  Scenario: An image whose sudo asks for a password is refused
    Given a stand-in "id" that prints "runner"
    But a stand-in "sudo" that fails, saying "sudo: a password is required"
    When I run "bash check.sh"
    Then it fails
    And stderr mentions "sudo: a password is required"
    And "docker" was run with "buildx version"
    And "sudo" was run with "-n true"
