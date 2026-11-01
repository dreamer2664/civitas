#!/usr/bin/env python3
"""Verifies Roblox names used by the client against the official API dump.

Why this exists: `luau-lsp` checks `Enum.X.Y` only where it can resolve the enum, and it does not
check strings at all. Key names in Bindings.luau and font faces in Theme.luau are strings, so a
typo would ship silently. This script fails the build on any name the dump does not contain.

Checks, all under src/client and only for the names listed:
  1. Every `Enum.<Name>.<Member>` reference exists in the dump.
  2. Every `Instance.new("<Class>")` names a class that exists and is creatable.
  3. Every `face = "<Font>"` in Theme.luau is an Enum.Font member.
  4. Every key string on a `keyboard =` or `gamepad =` line in Bindings.luau is an Enum.KeyCode member.

Usage: python3 tools/check_enums.py [--dump PATH]
Exit 0 when clean; exit 1 and list every problem otherwise.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DEFAULT_DUMP = Path(os.environ.get("CIV_CACHE", Path.home() / ".cache" / "civitas")) / "Full-API-Dump.json"

ENUM_REF = re.compile(r"\bEnum\.([A-Za-z_][A-Za-z0-9_]*)\.([A-Za-z_][A-Za-z0-9_]*)\b")
INSTANCE_NEW = re.compile(r"Instance\.new\(\"([A-Za-z_][A-Za-z0-9_]*)\"\)")
FACE = re.compile(r"\bface\s*=\s*\"([A-Za-z0-9_]+)\"")
KEY_LINE = re.compile(r"^\s*(keyboard|gamepad)\s*=\s*\{(.*)\}")
QUOTED = re.compile(r"\"([A-Za-z0-9_]+)\"")


def load_dump(path: Path) -> dict:
    if not path.exists():
        sys.exit(f"API dump not found at {path}. Run tools/install-tools.sh first.")
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def build_indexes(dump: dict) -> tuple[dict[str, set[str]], dict[str, dict]]:
    enums = {e["Name"]: {item["Name"] for item in e["Items"]} for e in dump["Enums"]}
    classes = {c["Name"]: c for c in dump["Classes"]}
    return enums, classes


def luau_files(root: Path) -> list[Path]:
    return sorted(p for p in root.rglob("*.luau") if p.is_file())


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--dump", type=Path, default=DEFAULT_DUMP)
    args = parser.parse_args()

    dump = load_dump(args.dump)
    enums, classes = build_indexes(dump)
    problems: list[str] = []
    checked = 0

    for path in luau_files(REPO / "src" / "client"):
        rel = path.relative_to(REPO)
        text = path.read_text(encoding="utf-8")
        for number, line in enumerate(text.splitlines(), start=1):
            code = line.split("--", 1)[0]  # ignore comments
            for enum_name, member in ENUM_REF.findall(code):
                checked += 1
                if enum_name not in enums:
                    problems.append(f"{rel}:{number}: unknown enum 'Enum.{enum_name}'")
                elif member not in enums[enum_name]:
                    problems.append(f"{rel}:{number}: 'Enum.{enum_name}.{member}' is not in the API dump")
            for class_name in INSTANCE_NEW.findall(code):
                checked += 1
                info = classes.get(class_name)
                if info is None:
                    problems.append(f"{rel}:{number}: Instance.new('{class_name}'): no such class")
                elif "Tags" in info and "NotCreatable" in info["Tags"]:
                    problems.append(f"{rel}:{number}: Instance.new('{class_name}'): class is not creatable")

    theme = REPO / "src" / "client" / "UI" / "Theme.luau"
    for number, line in enumerate(theme.read_text(encoding="utf-8").splitlines(), start=1):
        for face in FACE.findall(line):
            checked += 1
            if face not in enums["Font"]:
                problems.append(f"{theme.relative_to(REPO)}:{number}: font '{face}' is not an Enum.Font member")

    bindings = REPO / "src" / "client" / "Input" / "Bindings.luau"
    for number, line in enumerate(bindings.read_text(encoding="utf-8").splitlines(), start=1):
        match = KEY_LINE.match(line)
        if not match:
            continue
        for key in QUOTED.findall(match.group(2)):
            checked += 1
            if key not in enums["KeyCode"]:
                problems.append(f"{bindings.relative_to(REPO)}:{number}: key '{key}' is not an Enum.KeyCode member")

    print(f"check_enums: {checked} references checked against {args.dump.name}")
    if problems:
        print("\n".join(f"  {p}" for p in problems))
        print(f"check_enums: {len(problems)} problem(s)")
        return 1
    print("check_enums: 0 problems")
    return 0


if __name__ == "__main__":
    sys.exit(main())
