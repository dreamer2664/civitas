#!/usr/bin/env python3
"""Fails if client code refers to Workspace outside comments.

Why: under StreamingEnabled a distant Workspace instance may not exist on the client. Indexing it
errors, FindFirstChild returns nil, and a cached reference goes stale when the instance streams out
(docs/ARCHITECTURE.md rule 4). The UI must read its data from modules, never from Workspace.
Comments are stripped first, so a note that explains the rule does not trip the check.

Usage: python3 tools/check_streaming.py    (exit 0 clean, 1 with the offending lines)
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PATTERN = re.compile(r"\bworkspace\b", re.IGNORECASE)


def strip_comments(text: str) -> list[str]:
    """Returns the lines of `text` with Luau block and line comments blanked out."""
    text = re.sub(r"--\[(=*)\[.*?\]\1\]", lambda m: "\n" * m.group(0).count("\n"), text, flags=re.S)
    return [re.sub(r"--.*$", "", line) for line in text.splitlines()]


def main() -> int:
    problems: list[str] = []
    for path in sorted((REPO / "src" / "client").rglob("*.luau")):
        raw = path.read_text(encoding="utf-8")
        for number, line in enumerate(strip_comments(raw), start=1):
            if PATTERN.search(line):
                problems.append(f"{path.relative_to(REPO)}:{number}: {line.strip()}")
    print(f"check_streaming: scanned src/client")
    if problems:
        print("\n".join(f"  {p}" for p in problems))
        print(f"check_streaming: {len(problems)} reference(s) to Workspace in client code")
        return 1
    print("check_streaming: 0 references to Workspace")
    return 0


if __name__ == "__main__":
    sys.exit(main())
