# ci-runner

The container image Sustenaut's self-hosted GitHub Actions runners run:
`ghcr.io/sustenaut/ci-runner`. It is GitHub's
[`actions-runner`](https://github.com/actions/runner) image, pinned by digest, plus what
[pubkit](https://github.com/Sustenaut/pubkit)'s reusable workflows expect of GitHub's
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

## Changing what it holds

Add the package to the `apt-get install` line of the `Dockerfile`, and its command to
`check.sh`. To move the runner, change the `FROM` line: its tag and its digest, from
`ghcr.io/actions/actions-runner`.

## License

Apache-2.0.
