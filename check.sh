# What the image must hold, run inside it by the build workflow (and by hand:
#   docker run --rm -i --entrypoint bash ghcr.io/sustenaut/ci-runner:latest -s < check.sh).
# Each line is a tool pubkit's reusable workflows call without installing it on
# GitHub's ubuntu-latest; the first one missing fails the build.
set -euo pipefail
[[ $(id -un) == runner ]] || { echo "the image must run as runner, not $(id -un)" >&2; exit 1; }
for tool in git curl jq unzip zip xz zstd make gcc cc pkg-config python3 shellcheck gh docker sudo wget rsync file gpg node npm npx lsof ss ps pkill nc; do
  command -v "$tool" >/dev/null || { echo "missing: $tool" >&2; exit 1; }
done
python3 -m venv /tmp/venv-check && /tmp/venv-check/bin/pip --version >/dev/null && rm -rf /tmp/venv-check
docker buildx version >/dev/null
sudo -n true
test -x /home/runner/run.sh
echo "ok: $(/home/runner/bin/Runner.Listener --version) runner, $(python3 --version), node $(node --version), $(gh --version | head -n 1), $(shellcheck --version | sed -n 2p)"
