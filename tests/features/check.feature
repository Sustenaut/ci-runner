Feature: check.sh refuses an image that lacks what pubkit's workflows call
  The build workflow runs check.sh inside the image, and the first thing
  missing fails the build. Here it runs outside any image, with stand-in
  programs on PATH, so each refusal is seen on its own.

  Scenario: An image that runs as root is refused
    Given every tool check.sh looks for is installed
    And the image runs as "root"
    When check.sh runs
    Then it fails, saying "the image must run as runner, not root"

  Scenario Outline: An image without <tool> is refused, naming it
    Given every tool check.sh looks for is installed
    And the image runs as "runner"
    But "<tool>" is not installed
    When check.sh runs
    Then it fails, saying "missing: <tool>"

    Examples:
      | tool       |
      | git        |
      | shellcheck |
      | docker     |
      | nc         |

  Scenario: An image whose sudo asks for a password is refused
    Given every tool check.sh looks for is installed
    And the image runs as "runner"
    But sudo asks for a password
    When check.sh runs
    Then it fails, saying "sudo: a password is required"
