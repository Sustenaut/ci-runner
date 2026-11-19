"""Steps for check.feature: check.sh run by bash with a PATH of pubtest's
stand-ins, each a program that succeeds, so only what a scenario takes away
is missing."""

from __future__ import annotations

import re
from pathlib import Path

from pubtest.steps.standins import standins
from pytest_bdd import given, scenarios

scenarios("check.feature")

CHECK = Path(__file__).resolve().parents[2] / "check.sh"
TOOLS = re.search(r"for tool in ([^;]+); do", CHECK.read_text(encoding="utf-8")).group(1).split()


@given("every tool check.sh looks for is installed")
def installed(pubtest_ctx, tmp_path):
    """A stand-in for each tool check.sh's loop looks for, read from check.sh
    itself, and nothing else on PATH but the shell's basic tools."""
    found = standins(pubtest_ctx, tmp_path)
    for tool in TOOLS:
        found.add(tool)
    found.only = True
