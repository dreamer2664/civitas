# District A walkable-core generator — v0.2

This folder owns the reproducible city-plan exporter, tests, renders, and the generated Rojo place artifact. The runtime generator/builder is in `src/server/World/`.

## Slice / coordinate contract

Coordinates are Roblox studs, with world `Y` vertical. This is a bounded slice of District A, not a claim to have built the 10,000 × 8,000-stud city:

- Collidable ground: 1,540 × 1,880 studs, centered at `(X=0, Z=115)`, top at `Y=0` (bounds `X=[-770,770]`, `Z=[-825,1055]`).
- Historic core: 9 north-south × 9 east-west street lines, uneven 140–185-stud neighbor spacings, and 81 intersections. Four merged superblocks collapse 18 grid cells into 4 irregular parcels; 18 shared road runs are removed inside their footprints, including an L-shaped five-cell court and a 3×2 guild block. Arterials remain on the outer ring and station approach.
- Carriageways: 30-stud outer/station arterials, 13-stud locals and 8.5-stud lanes at 140–150-stud intervals; sidewalks are 3.5 studs each side. Six narrow diagonal/jog segments cut across the network; their landings reserve building-free corridors. Low curbs are 0.65 wide × 0.28 high, with 11-stud radius cutbacks at intersections.
- Three squares: the 100 × 110-stud main square at `(200,75)`, plus two smaller pocket squares at the Crooked Lane elbow and Market Cut junction. The main square is inside an irregular block, not an arterial cadence. Station forecourt begins at `Z=810`; entry at `Z=858`; concourse walk floor centered at `Z=925`.
- The route is generated as connected physical walk links: east station-avenue sidewalk spawn → narrow-lane grid → square → station forecourt → concourse. The test-measured centerline is **1,633.0 studs**.
- Ordinary massing has a darker separate ground storey, varied storefront glazing/doors, awnings or entry lintels, and upper massing. Landmark-scale forms retain their own crowns and tower lanterns.

All street widths, sidewalk width, block lot pattern, square, station, bounds, seed, streaming values, and building ranges come from `src/server/World/CityConfig.luau`. Change a parameter there; `CityGenerator.generate(config)` regenerates the deterministic plan.

## Current generated budget

From `lune run tools/world/export_plan.luau` (same `CityGenerator` consumed by the Roblox builder):

| Measure | Result |
|---|---:|
| Ordinary blockout buildings | 302 |
| Landmark-scale buildings | 12 |
| Total massings | 314 |
| Blocks / merged superblocks / street segments / intersections | 50 / 4 / 34 / 81 |
| Extra pocket squares / removed internal street runs | 2 / 18 |
| Exact planned Roblox `BasePart` count | **1,915** |
| Part budget | 25,000 |
| Route centerline | **1,633.0 studs** |

The 1,915 figure is an exact count against the current builder recipe (ordinary ground/upper/roof pieces plus frontage accents, landmark ground/upper/crowns, segmented curb returns, diagonal-lane surfaces, plaza paving, ground, station shell, route, and spawn); the Roblox builder also counts actual `BasePart` descendants on startup and stores `GeneratedPartCount`. No Studio runtime count has been observed here.

Landmarks: Old Town Clock Tower, St. Elian's Church, Civic Archive Tower, North Gate Hotel, Covered Market Hall, Guildhall, Riverside Exchange, Opera House, South Arcade Tower, Museum of Navigation, West Bastion Tower, and East Gate Basilica.

## Streaming and slice edges

`default.project.json` authors `StreamingEnabled=true`, `StreamingMinRadius=64`, `StreamingTargetRadius=1024`, `ModelStreamingBehavior=Improved`, `StreamingIntegrityMode=PauseOutsideLoadedArea`, and `StreamOutBehavior=Opportunistic`. The latter properties are marked `NotScriptable` in the current Roblox API dump, so they must be serialized by Rojo rather than assigned in a server script. The generated District A slice model records its exact min/max bounds as attributes and contains the continuous collision ground; the ground bounds are the physical edge of this slice. The avenue is not silently claimed to continue into Districts B–E. No atomic district-wide streaming is forced: normal instance streaming can stream individual geometry near the player.

## Build, test, render

From repo root:

```sh
./tools/verify.sh
```

The script runs Selene and StyLua; downloads Roblox `globalTypes.d.luau` into the user cache and passes it to `luau-lsp analyze --definitions`; makes a Rojo sourcemap; runs shared Lune tests plus `tools/world/test_city.luau`; exports `generated-plan.json`; renders evidence; and builds `civitas-world-blockout.rbxlx`.

The acceptance test is deliberately a plan/geometry test, not an assertion that Studio was run. It checks the generated path length/stages, ground bounds, route and diagonal-lane collision-footprint clearance, irregular spacing, merged-block count, removed internal road runs, pocket squares, building count/height/frontage diversity, landmark count, and an independently reconstructed exact part recipe. It does not simulate Roblox character movement, physics, streaming, mobile frame rate, or the import in Studio.

## Evidence renders

Generated by `tools/world/render_city.py` from the JSON exported by the Luau generator:

- `renders/district-a-plan.png` — top-down plan and route.
- `renders/street-view-grid.png` — north grid eye-height view.
- `renders/street-view-station.png` — station-approach eye-height view.

These are Python/matplotlib concept renders of the actual generated footprints and heights, not Roblox screenshots.

## Sourcing decision (Director addendum)

Read `docs/ASSET-SOURCING-POLICY.md` from current `origin/main` before deciding. It permits sourced buildings but still requires a fully vetted, decimated, reproducible asset pipeline, per-model script/hidden-part/licence/hash audit, a catalogue + manifest entry, and metre scale/pivot checks. No building kit is included in this milestone: this workspace has no Blender or mesh-processing toolchain, and no art bible/model candidate is available in the repo to match. Getting a kit through vetting, decimation, catalogue handoff, and deterministic generator integration would exceed the one-hour cap and risks the walkable acceptance target. The city therefore keeps the original procedural blockout; sourcing is a follow-up with atlas for the shared catalogue/manifest.

## Handoff / not in this slice

The station is a **walkable placeholder shell** (entry opening, forecourt colonnade, floor, side/rear walls), not mason's final station asset or rail concourse integration. No tracks/platforms, coastline, other districts, NPCs/traffic, shop interiors, upper-storey window detail, street trees/furniture, Studio import, or mobile runtime profiling are represented. The route's collidable geometry is generated and statically checked; only a Roblox Studio run can confirm the live character controller clears every seam and collision interaction.
