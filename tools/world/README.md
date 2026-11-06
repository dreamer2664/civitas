# District A walkable-core generator — v0.2

This folder owns the reproducible city-plan exporter, tests, renders, and the generated Rojo place artifact. The runtime generator/builder is in `src/server/World/`.

## Slice / coordinate contract

Coordinates are Roblox studs, with world `Y` vertical. This is a bounded slice of District A, not a claim to have built the 10,000 × 8,000-stud city:

- Collidable ground: 1,540 × 1,880 studs, centered at `(X=0, Z=115)`, top at `Y=0` (bounds `X=[-770,770]`, `Z=[-825,1055]`).
- Historic core: 9 north-south × 9 east-west street lines, uneven 140–185-stud neighbor spacings, and 81 intersections. Four merged superblocks collapse 18 grid cells into 4 irregular parcels; 18 shared road runs are removed inside their footprints, including an L-shaped five-cell court and a 3×2 guild block. Arterials remain on the outer ring and station approach.
- Carriageways: 30-stud outer/station arterials, 13-stud locals and 8.5-stud lanes at 140–150-stud intervals; sidewalks are 3.5 studs each side. Six narrow diagonal/jog segments cut across the network; their landings reserve building-free corridors. Low curbs are 0.65 wide × 0.28 high, with 11-stud radius cutbacks at intersections.
- Three squares: the 100 × 110-stud main square at `(200,75)`, plus two smaller pocket squares at the Crooked Lane elbow and Market Cut junction. Their paving replaces five intersecting orthogonal/diagonal street runs; those approaches terminate at the square edge rather than crossing through it. The main square is inside an irregular block, not an arterial cadence. Station forecourt begins at `Z=810`; entry at `Z=858`; concourse walk floor centered at `Z=925`.
- The route is generated as connected physical walk links: east station-avenue sidewalk spawn → narrow-lane grid → square → station forecourt → concourse → ramp → experimental platform. The plan centerline is **1,718.5 studs** (horizontal only).
- Ordinary massing has a darker separate ground storey, varied storefront glazing/doors, awnings or entry lintels, and upper massing with non-colliding window overlays on two faces. Landmark-scale forms retain their own crowns and tower lanterns.

All street widths, sidewalk width, block lot pattern, square, station, bounds, seed, streaming values, and building ranges come from `src/server/World/CityConfig.luau`. Change a parameter there; `CityGenerator.generate(config)` regenerates the deterministic plan.

## Current generated budget

From `lune run tools/world/export_plan.luau` (same `CityGenerator` consumed by the Roblox builder):

| Measure | Result |
|---|---:|
| Ordinary blockout buildings | 302 |
| Landmark-scale buildings | 12 |
| Total massings | 314 |
| Blocks / merged superblocks / street segments / intersections | 50 / 4 / 35 / 81 |
| Extra pocket squares / removed internal street runs / square street cuts | 2 / 18 / 5 |
| Exact planned Roblox `BasePart` count | **10,343** |
| Part budget | 25,000 |
| Route centerline | **1,718.5 studs** |

The 10,343 figure is an exact count against the current builder recipe (ordinary ground/upper/roof pieces plus frontage accents and upper windows, landmark ground/upper/crowns, segmented curb returns, diagonal-lane surfaces, plaza paving, clipped junction approaches, ground, station shell, route, and spawn); this excludes the separate experimental railway/train model, estimated at about 661 additional parts. The Roblox builder also counts actual `BasePart` descendants on startup and stores `GeneratedPartCount`. No Studio runtime count has been observed here. This increases the original 1,920-part recipe substantially; instance count is not a draw-call or mobile performance measurement. Profile in Studio on target hardware before accepting it as a performance budget.

Landmarks: Old Town Clock Tower, St. Elian's Church, Civic Archive Tower, North Gate Hotel, Covered Market Hall, Guildhall, Riverside Exchange, Opera House, South Arcade Tower, Museum of Navigation, West Bastion Tower, and East Gate Basilica.

## Streaming and slice edges

`default.project.json` authors `StreamingEnabled=true`, `StreamingMinRadius=64`, `StreamingTargetRadius=1024`, `ModelStreamingBehavior=Improved`, `StreamingIntegrityMode=PauseOutsideLoadedArea`, and `StreamOutBehavior=Opportunistic`. The latter properties are marked `NotScriptable` in the current Roblox API dump, so they must be serialized by Rojo rather than assigned in a server script. The generated District A slice model records its exact min/max bounds as attributes and contains the continuous collision ground; the ground bounds are the physical edge of this slice. The avenue is not silently claimed to continue into Districts B–E. No atomic district-wide streaming is forced: normal instance streaming can stream individual geometry near the player.

## Build, test, render

From repo root:

```sh
./tools/verify.sh
```

The script runs Selene and StyLua; downloads Roblox `globalTypes.d.luau` into the user cache and passes it to `luau-lsp analyze --definitions`; makes a Rojo sourcemap; runs shared Lune tests plus `tools/world/test_city.luau`; exports `generated-plan.json`; renders evidence; and builds `civitas-world-blockout.rbxlx`.

The acceptance test is deliberately a plan/geometry test, not an assertion that Studio was run. It checks the generated path length/stages, ground bounds, route and diagonal-lane collision-footprint clearance, irregular spacing, merged-block count, removed internal road runs, pocket-square street cutouts, building count/height/frontage diversity, landmark count, and an independently reconstructed exact part recipe. It does not simulate Roblox character movement, physics, streaming, mobile frame rate, or the import in Studio.

## Evidence renders

Generated by `tools/world/render_city.py` from the JSON exported by the Luau generator:

- `renders/district-a-plan.png` — top-down plan and route.
- `renders/street-view-grid.png` — north grid eye-height view.
- `renders/street-view-station.png` — station-approach eye-height view.

These are Python/matplotlib concept renders of the actual generated footprints and heights, not Roblox screenshots.

## Sourcing decision (Director addendum)

Read `docs/ASSET-SOURCING-POLICY.md` from current `origin/main` before deciding. It permits sourced buildings but still requires a fully vetted, decimated, reproducible asset pipeline, per-model script/hidden-part/licence/hash audit, a catalogue + manifest entry, and metre scale/pivot checks. No building kit is included in this milestone: this workspace has no Blender or mesh-processing toolchain, and no art bible/model candidate is available in the repo to match. Getting a kit through vetting, decimation, catalogue handoff, and deterministic generator integration would exceed the one-hour cap and risks the walkable acceptance target. The city therefore keeps the original procedural blockout; sourcing is a follow-up with atlas for the shared catalogue/manifest.

## Handoff / not in this slice

The station is a **placeholder shell** with a ramp and experimental test platform, not mason's final station asset. A separate single-track shuttle prototype is generated behind it; it is not the proposed network, and is not yet verified in Studio. No coastline, other districts, NPCs/traffic, shop interiors, fully detailed facades, street trees/furniture, Studio import, or mobile runtime profiling are represented. The route's collidable geometry is generated and statically checked; only a Roblox Studio run can confirm the live character controller clears every seam and collision interaction.
