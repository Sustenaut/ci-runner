# ci-runner

The container image Sustenaut's self-hosted GitHub Actions runners run:
`ghcr.io/sustenaut/ci-runner`. It is GitHub's
[`actions-runner`](https://github.com/actions/runner) image, pinned by digest, plus what
[pubrules](https://github.com/Sustenaut/pubrules)'s reusable workflows expect of GitHub's
`ubuntu-latest`: a C toolchain, Python 3 with venv and pip, Node.js, ShellCheck, the GitHub CLI,
and a few archive, process and network tools (lsof, ss). `check.sh` lists them, and the build fails when one
is missing.

The runners are the scale set `sustenaut-ci`, run by GitHub's Actions Runner Controller
on Sustenaut's k3s server; Sustenaut/shared-infra's `help/ci-runners.md` describes it,
and its `infra/ci-runners/arc.yaml` pins this image by digest.

## Building

`.github/workflows/build.yml` builds the image on every pull request and checks it; on
main it pushes `ghcr.io/sustenaut/ci-runner:<commit>` and `:latest`, and the run's
summary gives the digest to pin. Once a week it builds again without the layer cache,
for the base's and Ubuntu's security updates.

A new image reaches the runners only when shared-infra's pin moves to its digest.

## Rules

The repository is a [pubrules](https://github.com/Sustenaut/pubrules) service, like the
other Sustenaut repositories: `pubrules.json` holds its rules and `pubrules sync` writes
the managed files (`AGENTS.md`, `./pubrules`, `./pubsec`, `with-secrets`, the CI in
`pr.yml` and `main.yml`, `.github/dependabot.yml`). The CI checks the managed files
are in step and runs ShellCheck on `check.sh`; `integrations.yml` holds
`integrations.json` to what the repository calls. Dependabot watches the
`Dockerfile`'s base image (docker) and the Actions it pins, and main's ruleset
requires `ci / passed` and `integrations / scan` (`./pubrules protect`). The image
itself is built by `build.yml`, which is the repository's own.

## Changing what it holds

Add the package to the `apt-get install` line of the `Dockerfile`, and its command to
`check.sh`. To move the runner, change the `FROM` line: its tag and its digest, from
`ghcr.io/actions/actions-runner`.

## License

Apache-2.0.
