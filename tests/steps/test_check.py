"""Steps for check.feature: check.sh run by bash with a PATH of stand-ins,
each a script that succeeds, so only what a scenario takes away is missing."""

from __future__ import annotations

import re
import shutil
import subprocess
from pathlib import Path

from pytest_bdd import given, parsers, scenarios, then, when

scenarios("check.feature")

CHECK = Path(__file__).resolve().parents[2] / "check.sh"
TOOLS = re.search(r"for tool in ([^;]+); do", CHECK.read_text(encoding="utf-8")).group(1).split()


@given("every tool check.sh looks for is installed", target_fixture="bin_dir")
def installed(tmp_path):
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    for tool in [*TOOLS, "id", "sudo"]:
        stand_in(bin_dir, tool, "exit 0")
    # What check.sh and the stand-ins run besides the tools it checks: the real ones.
    for tool in ("mkdir", "chmod", "rm", "sed", "head"):
        if tool not in TOOLS:
            (bin_dir / tool).symlink_to(shutil.which(tool))
    # python3 -m venv DIR makes a DIR/bin/pip that answers, as a real one does.
    stand_in(bin_dir, "python3", '[ "$1 $2" = "-m venv" ] && mkdir -p "$3/bin" && printf "#!/bin/sh\\n" > "$3/bin/pip" '
                                 '&& chmod +x "$3/bin/pip"; exit 0')
    return bin_dir


def stand_in(bin_dir: Path, name: str, body: str) -> None:
    path = bin_dir / name
    path.write_text(f"#!/bin/sh\n{body}\n", encoding="utf-8")
    path.chmod(0o755)


@given(parsers.parse('the image runs as "{user}"'))
def runs_as(bin_dir, user):
    stand_in(bin_dir, "id", f'[ "$1" = -un ] && echo {user}')


@given(parsers.parse('"{tool}" is not installed'))
def not_installed(bin_dir, tool):
    (bin_dir / tool).unlink()


@given("sudo asks for a password")
def sudo_asks(bin_dir):
    stand_in(bin_dir, "sudo", 'echo "sudo: a password is required" >&2; exit 1')


@when("check.sh runs", target_fixture="ran")
def check_runs(bin_dir):
    bash = shutil.which("bash")
    return subprocess.run([bash, str(CHECK)], env={"PATH": str(bin_dir)}, capture_output=True, text=True,
                          check=False)


@then(parsers.parse('it fails, saying "{text}"'))
def fails_saying(ran, text):
    assert ran.returncode != 0
    assert text in ran.stderr, ran.stderr


@then("it fails")
def fails(ran):
    assert ran.returncode != 0, ran.stdout
