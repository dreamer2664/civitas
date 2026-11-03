# Canonical district and spawn names

**Binding interim naming — Manager A ruling, 2026-11-03.** Lumen consumes this root-level
file as the source of truth. Atlas confirms or adjusts these names in his `CHECKLIST.md`;
an objection must cite the ART-BIBLE. No Atlas confirmation or citation is claimed here.

Coordinates are **(X, Y, Z), studs; Y is the ground/plaza surface**, not HumanoidRootPart,
camera eye or SpawnLocation centre. +X east, +Z south. IDs are stable; labels are binding
interim names, not a renumbering of the master plan's existing A–E district IDs.

| Spawn ID | Canonical district | Plaza / anchor | Coordinates (X, Y, Z), studs | Availability |
|---|---|---|---|---|
| SC-01 | Historic Core (District A) | Old Town Square | (200, 0.575, 75) | Built plaza; selected primary anchor; runtime relocation pending |
| SC-02 | Harbour | Harbour Plaza (reserved) | (3700, 0, 2200) | Reserved planning node; plaza/ground unbuilt; teleport disabled |
| SC-03 | Market | Market Cut Square | (435, 0.565, 455) | Built plaza; named anchor; district spawn activation pending |
| SC-04 | Cathedral Quarter | Crooked Lane Court | (-175, 0.565, -80) | Built plaza; named anchor; district spawn activation pending |

## Spawn-anchor decision and exact construction evidence

The full route is **1632.999280 studs**. Its geometric centroid, defined by the line
integral `sum(segmentLength * segmentMidpoint) / totalLength`, is
**(X=139.391649, Z=141.008597)**. Old Town Square is the nearest real plaza node at
**89.613097 studs**, versus Crooked Lane Court 384.300545 and Market Cut Square 431.248070.
Thus **SC-01 (200, 0.575, 75)** is the Manager-directed anchor. It is not the route's old
south-sidewalk start. Preserve the complete >=1500-stud acceptance route as its own test;
do not silently shorten it to the plaza-to-concourse remainder.

The existing geometry names remain `OldTownSquare`, `MarketCutSquare_Paving` and
`CrookedLaneCourt_Paving`; these are source identities, not alternate canonical district
labels. Rounded Y values represent exported tops approximately 0.574997/0.564995.
The headless footprint/obstacle check is separate from engine first-frame/camera proof.

## Reserved Harbour node: no fabricated coverage

The current built slice ends at X=770; **no Harbour plaza or collidable ground exists at
SC-02**. (3700, 0, 2200) is an explicitly reserved site at the centre of the provisional
Harbour footprint in `docs/rail/NETWORK.md`, NOT a measured terrain height. Atlas must
site/build its plaza or amend the coordinate with evidence. Never teleport players there
until support, collision and streaming checks pass. Binding naming does not make it built.

Market and Cathedral Quarter are the Manager's interim display districts anchored to two
existing pocket plazas. Their complete geographic boundaries are not invented here.
No claim is made that the old spawn has already moved or that the four runtime spawns
exist: this table binds identity/placement handoff; runtime integration must use it.

Evidence: `audit/spawn-anchor-ruling.json`; actual builder export
`docs/reports/walkability-world.json`; `audit/PARKS.json`.

## Headless validation of the selected anchor

SC-01 has collidable support and a clear radius-1 / height-5 body envelope at the
selected point. **5 of 17 tested landmark-anchor rays are clear** from the assumed
4.5-stud eye offset (Museum of Navigation, South Arcade Tower, Riverside Exchange).
This resolves the selected-anchor geometry/sightline evidence, not runtime relocation
or first-frame engine framing. Evidence: `audit/sc01-geometry.json` and
`audit/sc01-sightlines.json`. The old south-sidewalk runtime anchor still has 0/17.

## Machine-readable handoff

`python tools/walkaudit/names.py` generates `audit/canonical-spawns.json` and
`src/server/Spawn/CanonicalPlan.luau` directly from the table above.
`python tools/walkaudit/names.py --check` rejects drift. All runtimeActive flags remain
false until actual integration/ground/engine checks; the old RecommendedPlan is a
legacy audit fixture, not an alternate naming authority.
