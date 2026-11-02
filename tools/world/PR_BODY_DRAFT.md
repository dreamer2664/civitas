## Summary

- Deepened District A's block-size variation: four irregular superblocks merge 18 grid cells into four parcels (including an L-shaped five-cell cloister and a 3×2 guild block). Eighteen shared internal street runs are removed; the core now reads as 50 blocks rather than a uniform cell grid.
- Retained three 8.5-stud narrow-lane alignments in each direction (with local segments yielding to superblock courts), jog/diagonal cuts, articulated ground floors, and 302 ordinary buildings plus 12 landmarks.
- Kept the two small squares at the Crooked Lane elbow and Market Cut junction. Their paving now replaces five orthogonal/diagonal street approaches, which end at the square edges instead of crossing through the plazas.
- Preserved the 1,633.0-stud acceptance walk to the station concourse.

## Generated plan and views

![District A generated plan](https://github.com/dreamer2664/civitas/blob/world/historic-core-blockout/tools/world/renders/district-a-plan.png?raw=1)

![Historic grid street view](https://github.com/dreamer2664/civitas/blob/world/historic-core-blockout/tools/world/renders/street-view-grid.png?raw=1)

![Station approach street view](https://github.com/dreamer2664/civitas/blob/world/historic-core-blockout/tools/world/renders/street-view-station.png?raw=1)

## Verification

- 302 ordinary buildings; 12 landmarks.
- 50 blocks; 4 merged superblocks; 18 removed internal street runs; 2 pocket squares; 5 square-edge street cuts.
- 1,920 planned BaseParts against a 25,000-part budget; exact estimate independently checked against the builder recipe.
- Acceptance walk: 1,633.0 studs. Seven generated-city tests and 23 shared tests pass; Selene, StyLua, Luau analysis, deterministic export/renders, and Rojo build pass.

## Build verification log

```text
== selene src/ ==
Results: 0 errors, 0 warnings, 0 parse errors
== stylua --check src/ tests/ tools/world/ ==
== lune shared tests ==
23 passed, 0 failed
== lune generated-city acceptance tests ==
City acceptance: 7 passed, 0 failed
== deterministic city export + plan/street-level renders ==
Exported tools/world/generated-plan.json: 302 buildings, 12 landmarks, 1633.0 route studs, 1920 estimated parts
Rendered: district-a-plan.png, street-view-grid.png, street-view-station.png
== rojo build committed place file ==
Building project 'CIVITAS'
Built project to civitas-world-blockout.rbxlx
ALL CHECKS PASSED
```

## Limits

The renders are generated concept views, not Roblox Studio screenshots. No Studio import, live character/physics traversal, streaming behavior, or mobile runtime test was available for this pass.

## Local handoff

Prepared on `world/historic-core-blockout`, pushed through commit `2900231`; see `tools/world/README.md` for the reproducible verify command and metrics.
