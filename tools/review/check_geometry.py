#!/usr/bin/env python3
"""Independent sampled geometry checks. NOT a swept humanoid or Roblox physics test."""
import json
import math
from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
geometry = json.loads((ROOT / 'build/review/geometry.json').read_text())
plan = json.loads((ROOT / 'tools/world/generated-plan.json').read_text())
parts = geometry['parts']
assert geometry['cityParts'] == plan['stats']['estimatedParts'], 'recipe budget differs from instantiated data model'
assert geometry['cityParts'] + geometry['railParts'] < plan['stats']['partBudget'], 'combined part budget exceeded'

def part(name):
    found = [p for p in parts if p['name'] == name]
    assert len(found) == 1, (name, len(found))
    return found[0]

ramp = part('WestAccessRamp')
assert abs(math.tan(math.radians(ramp['orientation'][0]))) <= 1 / 12, 'West ramp steeper than 1:12'
assert part('WestPlatform')['position'][1] + .4 - plan['station']['platformTopY'] < 1e-4
leaves = [p for p in parts if p['name'] == 'SlidingDoor']
assert len(leaves) == 16 and all(not p['collide'] for p in leaves)
assert sum(p['position'][2] < plan['station']['railCenterZ'] for p in leaves) == 8
for p in parts:
    if p['name'].startswith(('StationRearWindow', 'StationRearPilaster', 'StationWindowSill', 'StationRearCornice', 'Portico', 'CentralStationName')):
        assert not p['collide'], 'decorative station geometry must not snag a walker'

# Sample a 2.5-stud-wide corridor on the new forecourt -> West Gardens connection.
# Check support at feet-0.12 and clearance at feet+0.8 / feet+5 in the exact rotated boxes.
x0 = plan['station']['centerX']
x1 = plan['station']['westStopX']
z0 = plan['station']['forecourtZ']
top = plan['station']['platformTopY']
anchors = [(x0, .63, z0), (x1, .63, z0), (x1, .63, 965.5), (x1, top, 1000), (x1, top, plan['station']['platformCenterZ'])]
points = []
for first, last in zip(anchors, anchors[1:]):
    a, b = np.array(first), np.array(last)
    delta = b - a
    horizontal = math.hypot(delta[0], delta[2])
    perpendicular = np.array([-delta[2] / horizontal, 0, delta[0] / horizontal])
    for t in np.linspace(0, 1, math.ceil(horizontal) + 1):
        for side in (-1.25, 0, 1.25):
            points.append(a + delta * t + perpendicular * side)
points = np.array(points)
support = np.zeros(len(points), dtype=bool)
blocked = np.zeros(len(points), dtype=bool)

def rotation(angles):
    x, y, z = map(math.radians, angles)
    rx = np.array([[1,0,0],[0,math.cos(x),-math.sin(x)],[0,math.sin(x),math.cos(x)]])
    ry = np.array([[math.cos(y),0,math.sin(y)],[0,1,0],[-math.sin(y),0,math.cos(y)]])
    rz = np.array([[math.cos(z),-math.sin(z),0],[math.sin(z),math.cos(z),0],[0,0,1]])
    return ry @ rx @ rz

for p in parts:
    if not p['collide']:
        continue
    center, half = np.array(p['position']), np.array(p['size']) / 2
    # Cylinder fountain lies outside this branch; all collision candidates here are boxes.
    if center[2] + max(half) < z0 - 5 or center[0] - max(half) > x0 + 5:
        continue
    matrix = rotation(p['orientation'])
    def inside(offset):
        q = (points + np.array([0, offset, 0]) - center) @ matrix
        return np.all(np.abs(q) <= half + 1e-4, axis=1)
    support |= inside(-.12)
    blocked |= inside(.8) | inside(5)
assert np.all(support), f'{np.sum(~support)} unsupported corridor sample points: {points[~support][:3]}'
assert not np.any(blocked), f'{np.sum(blocked)} blocked corridor sample points: {points[blocked][:3]}'
summary = {
    'cityParts': geometry['cityParts'], 'railParts': geometry['railParts'],
    'combinedParts': geometry['cityParts'] + geometry['railParts'],
    'westCorridorSamplePoints': len(points), 'unsupportedSamples': int(np.sum(~support)),
    'blockedSamples': int(np.sum(blocked)), 'westRampSlope': abs(math.tan(math.radians(ramp['orientation'][0]))),
    'doorLeaves': len(leaves), 'scope': 'Lune data model / sampled boxes only; no Roblox runtime verification',
}
(ROOT / 'evidence/norman/geometry-checks.json').write_text(json.dumps(summary, indent=2) + '\n')
print(json.dumps(summary, indent=2))
