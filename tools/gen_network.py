#!/usr/bin/env python3
"""Generates the client map data from docs/rail/NETWORK.md (CODE · vector's network description).

Why: Roblox cannot read a Markdown file at runtime, so the map needs a Luau table. The table is
generated, never typed by hand, so a change to NETWORK.md shows up as a diff in this check.

Writes src/client/UI/Map/NetworkData.luau. With --check, writes nothing and exits 1 if the committed
file is out of date. tools/verify.sh runs --check.

What is taken from NETWORK.md: station table (§2), waypoints (§3). What is NOT in NETWORK.md and is
decided here, in one place: the line colour tokens (lumen's choice, from Theme) and the section
kinds, which §6 states in prose. Each §6 rule below quotes the sentence it comes from. Anything
the doc says that is not listed in RULES is ground, as §3 says for "everything else".

Usage: python3 tools/gen_network.py          (write)
       python3 tools/gen_network.py --check  (verify the committed file is current)
"""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SOURCE = REPO / "docs" / "rail" / "NETWORK.md"
TARGET = REPO / "src" / "client" / "UI" / "Map" / "NetworkData.luau"

# lumen's colour choice per line; must be keys of Theme.lineColours.
LINE_COLOURS = {1: "teal", 2: "slate", 3: "ochre"}

# §6 section rules: (line, kind, start waypoint, end waypoint, the §6 sentence it comes from).
# Waypoints are (x, z) in studs. Segments between start and end take `kind`; all others are surface.
RULES = [
    (1, "underground", (-1100, 200), (900, 700), "§6: Old Town → Riverside (under the A/C boundary)"),
    (1, "elevated", (2500, 1400), (3600, 2400), "§6: embankment Harbour Gate → Container Terminal"),
    (2, "underground", (0, 0), (800, -800), "§6: tunnels Central ↔ Civic Plaza (under District A)"),
    (2, "elevated", (2400, -1800), (3400, -2600), "§6: viaduct Exchange ↔ Tower Station"),
]

Point = tuple[int, int]


def section_text(md: str, number: int) -> str:
    """Returns the body of the '## N.' section of the Markdown, up to the next '## '."""
    match = re.search(rf"^## {number}\..*?$(.*?)(?=^## |\Z)", md, re.S | re.M)
    if match is None:
        raise SystemExit(f"gen_network: NETWORK.md has no section {number}; the doc changed shape")
    return match.group(1)


def parse_stations(md: str) -> list[dict]:
    """§2 station table rows: | # | Station | Line(s) | District | (X, Z) | Section |."""
    rows = []
    row_re = re.compile(
        r"^\|\s*(\d+)\s*\|\s*([^|]+?)\s*\|\s*([\d, ]+?)\s*\|\s*[^|]+\|\s*\((-?\d+),\s*(-?\d+)\)\s*\|"
    )
    for line in section_text(md, 2).splitlines():
        m = row_re.match(line)
        if m:
            rows.append(
                {
                    "order": int(m.group(1)),
                    "name": m.group(2),
                    "id": slug(m.group(2)),
                    "lines": [int(v) for v in m.group(3).split(",")],
                    "x": int(m.group(4)),
                    "z": int(m.group(5)),
                }
            )
    if not rows:
        raise SystemExit("gen_network: no station rows found in NETWORK.md §2")
    return rows


def parse_waypoints(md: str) -> dict[int, list[Point]]:
    """§3: 'Line N: (x,z) (x,z) ...', where a line may wrap onto following indented-free lines."""
    waypoints: dict[int, list[Point]] = {}
    current: int | None = None
    for raw in section_text(md, 3).splitlines():
        head = re.match(r"^Line (\d+):", raw)
        if head:
            current = int(head.group(1))
            waypoints[current] = []
        elif raw.strip() == "":
            current = None
        elif current is not None and raw.startswith("("):
            pass
        else:
            continue
        if current is not None:
            for m in re.finditer(r"\((-?\d+),\s*(-?\d+)\)", raw):
                waypoints[current].append((int(m.group(1)), int(m.group(2))))
    if not waypoints:
        raise SystemExit("gen_network: no 'Line N:' waypoint lists found in NETWORK.md §3")
    return waypoints


def slug(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")


def split_sections(points: list[Point], rules: list[tuple[str, Point, Point]]) -> list[tuple[str, list[Point]]]:
    """Turns one waypoint polyline into sections of one kind each. Neighbouring sections share their
    boundary point, so the drawn line is continuous."""
    kinds = ["surface"] * (len(points) - 1)
    for kind, start, end in rules:
        if start not in points or end not in points:
            raise SystemExit(f"gen_network: rule endpoint {start} or {end} is not a waypoint")
        a, b = points.index(start), points.index(end)
        if a >= b:
            raise SystemExit(f"gen_network: rule {start}→{end} runs against the line direction")
        for i in range(a, b):
            kinds[i] = kind
    sections: list[tuple[str, list[Point]]] = []
    start_index = 0
    for i in range(1, len(kinds) + 1):
        if i == len(kinds) or kinds[i] != kinds[start_index]:
            sections.append((kinds[start_index], points[start_index : i + 1]))
            start_index = i
    return sections


def build() -> str:
    md = SOURCE.read_text(encoding="utf-8")
    stations = parse_stations(md)
    waypoints = parse_waypoints(md)
    by_pos = {(s["x"], s["z"]): s for s in stations}

    # Consistency: every station sits on each line it serves, as one of that line's waypoints.
    for station in stations:
        for line in station["lines"]:
            if line not in waypoints:
                raise SystemExit(f"gen_network: station {station['name']} is on line {line}, which has no waypoints")
            if (station["x"], station["z"]) not in waypoints[line]:
                raise SystemExit(f"gen_network: {station['name']} is not a waypoint of line {line}")

    out: list[str] = []
    out.append("--!strict")
    out.append("--[[")
    out.append("\tGENERATED by tools/gen_network.py from docs/rail/NETWORK.md (CODE · vector). Do not edit.")
    out.append("\tRegenerate with `python3 tools/gen_network.py`; tools/verify.sh fails if this is stale.")
    out.append("\tFrame: studs, X east, Z south (NETWORK.md §1). The map draws north at the top.")
    out.append("]]")
    out.append("")
    out.append("return {")
    out.append("\tstations = {")
    for s in stations:
        interchange = "true" if len(s["lines"]) > 1 else "false"
        out.append(
            f'\t\t{{ id = "{s["id"]}", name = "{s["name"]}", x = {s["x"]}, z = {s["z"]}, '
            f"interchange = {interchange} }},"
        )
    out.append("\t},")
    out.append("\tlines = {")
    for line in sorted(waypoints):
        if line not in LINE_COLOURS:
            raise SystemExit(f"gen_network: line {line} has no colour in LINE_COLOURS")
        stops = [s["id"] for s in stations if line in s["lines"]]
        rules = [(kind, start, end) for (ln, kind, start, end, _) in RULES if ln == line]
        sections = split_sections(waypoints[line], [(k, a, b) for k, a, b in rules])
        out.append("\t\t{")
        out.append(f'\t\t\tid = "line-{line}",')
        out.append(f'\t\t\tcode = "{line}",')
        out.append(f'\t\t\tcolour = "{LINE_COLOURS[line]}",')
        out.append("\t\t\tstops = { " + ", ".join(f'"{x}"' for x in stops) + " },")
        out.append("\t\t\tsections = {")
        for kind, points in sections:
            pts = ", ".join(f"{{ x = {x}, z = {z} }}" for x, z in points)
            out.append(f'\t\t\t\t{{ kind = "{kind}", points = {{ {pts} }} }},')
        out.append("\t\t\t},")
        out.append("\t\t},")
    out.append("\t},")
    out.append("}")
    text = "\n".join(out) + "\n"
    return format_with_stylua(text)


def format_with_stylua(text: str) -> str:
    """Formats with the repo's stylua so the generated file passes `stylua --check`."""
    stylua = shutil.which("stylua")
    if stylua is None:
        raise SystemExit("gen_network: stylua not found; run tools/install-tools.sh")
    result = subprocess.run(
        [stylua, "--stdin-filepath", str(TARGET), "-"],
        input=text,
        capture_output=True,
        text=True,
        cwd=REPO,
        check=False,
    )
    if result.returncode != 0:
        raise SystemExit(f"gen_network: stylua failed: {result.stderr.strip()}")
    return result.stdout


def main() -> int:
    generated = build()
    if "--check" in sys.argv[1:]:
        current = TARGET.read_text(encoding="utf-8") if TARGET.exists() else ""
        if current != generated:
            print(f"gen_network: {TARGET.relative_to(REPO)} is stale; run python3 tools/gen_network.py")
            return 1
        print(f"gen_network: {TARGET.relative_to(REPO)} is current")
        return 0
    TARGET.write_text(generated, encoding="utf-8")
    print(f"gen_network: wrote {TARGET.relative_to(REPO)} ({len(generated)} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
