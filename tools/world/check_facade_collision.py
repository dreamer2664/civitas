#!/usr/bin/env python3
"""Static guard for the decorative facade collision policy; not a Roblox physics test."""
from pathlib import Path
import re

source = (Path(__file__).resolve().parents[2] / "src/server/World/CityBuilder.luau").read_text()
match = re.search(r"local function facadePart\(.*?\n\tend\n\n\tif not building\.landmark then", source, re.S)
if not match:
    raise SystemExit("could not locate facadePart; update this policy check")
helper = match.group(0)
for statement in ("part.CanCollide = false", "part.CanQuery = false"):
    if statement not in helper:
        raise SystemExit(f"facade policy missing: {statement}")
if not (helper.index("part.CanCollide = false") < helper.index("part.CanQuery = false") < helper.index("return part")):
    raise SystemExit("facade policy must be applied in order before returning")
for name in ("DisplayWindow_Left", "DisplayWindow_Right", "RecessedShopDoor", "CanvasAwning", "RecessedDoor", "EntryLintel", "SingleShopAwning"):
    if not re.search(r'facadePart\(\s*"' + re.escape(name) + r'"', source):
        raise SystemExit(f"facade element missing or bypasses facadePart: {name}")
print("facade collision policy: 7 decorative overlays use the non-collidable, non-queryable helper")
