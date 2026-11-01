# mason — Phase 1 technical report

Status: proposal, 2026-11-01. No models, Studio imports, performance measurements, or asset production are claimed here. This report is explicitly requested by Manager A despite `docs/**` being Manager-owned; it is a proposed report for Manager review, not a change to shared contracts or architecture. Full production remains gated by core architecture approval in the master directive.

## 1. Resources read: facts and consequences

1. [Roblox general modeling specifications](https://create.roblox.com/docs/art/modeling/specifications#geometry): individual meshes cannot exceed **20,000 triangles**; geometry must be watertight and nonzero thickness, with quads where possible. Keep each exported mesh under that ceiling with headroom; test evaluated triangulated meshes and manifoldness, including collision pieces, before export. The limit is per mesh, not permission to spend 20,000 triangles on every object.
2. [Importer](https://create.roblox.com/docs/studio/importer#supported-file-types): FBX and glTF support multiple meshes and hierarchy, and glTF imports each primitive inside a nested Model. Prefer FBX for predictable simple hierarchy; name and verify exported pieces and ask the Manager to validate the actual Studio hierarchy.
3. [Importer settings](https://create.roblox.com/docs/studio/importer#import-settings): Scale Unit defaults to studs, Set Pivot to Scene Origin defaults on, and Anchored defaults off; child Use Imported Pivot defaults on. Export an explicit 3.5714286 studs per metre scale, document axes and scene/object pivots, and specify static station assets anchored at import; moving train anchoring is for vector's integration decision. Verify conversion in Studio instead of assuming it works.
4. [Meshes — LOD](https://create.roblox.com/docs/parts/meshes#level-of-detail): Automatic RenderFidelity uses highest detail under 250 studs, medium at 250–500, and lowest at 500+. Avoid silhouette-critical fine details; plan reusable low-detail visual pieces and inspect transitions in Studio, rather than claiming the automatic result was tested.
5. [Meshes — collision](https://create.roblox.com/docs/parts/meshes#collision-fidelity): Box is suitable for small/simple objects; PreciseConvexDecomposition costs most and is not exact. Ship separate simplified collision geometry, disable visual mesh collisions in integration, and use simple floor/wall proxies that leave door openings clear; Manager tests actual walkability and collision in Studio.
6. [Design for performance](https://create.roblox.com/docs/performance-optimization/design#low-end-devices): 1,000 draw calls and 1,000,000 triangles are an illustrative baseline-device example, not a universal engine limit. The architecture adopts them as project worst-view budgets; share materials and reuse kit modules, then measure on a real baseline device with Manager rather than assert compliance from asset counts.
7. [Streaming techniques](https://create.roblox.com/docs/workspace/streaming/techniques#model-level-of-detail): SLIM is for static models; runtime-modified/animated models are unsupported. Group static platform bays spatially, avoid promising SLIM for the moving train, and coordinate streaming behavior with vector. Atomic models only guarantee initial replication, not later-added descendants.
8. [Improve performance](https://create.roblox.com/docs/performance-optimization/improve#physics-computation): unnecessary simulation and overly precise collision increase physics cost; anchor static station pieces and keep visual meshes non-colliding where practical. Actual runtime cost is unmeasured.
9. [Blender modeling introduction](https://docs.blender.org/manual/en/latest/modeling/meshes/introduction.html): mesh modeling normally starts with primitives and continues with edit-mode detail. Develop editable, non-destructive source, not a box presented as a completed EMU.

## 2. Proposed design and trade-offs

Original fictional coastal European EMU, restrained warm white body with deep blue glazing band and muted red door accents. Cab has a sculpted tapered nose, sloped wraparound windscreen, lights, coupler and underframe; the intermediate has coordinated doors, glazing, roof and bogies. Accessible, believable cab and passenger spaces; separately addressable door panels and bogies. No unlicensed third-party asset or photograph is adopted. Target 21 m cab car and 20 m intermediate car, 2.85 m width and ~4.1 m rail-to-roof height, subject to integration review: approximately 75.00 / 71.43 studs long, 10.18 wide, 14.64 high. 1 m = 1/0.28 = 3.5714286 studs. Track/door/platform compatibility is a design target, not yet validated.

Kit has 4 m (14.286 studs) repeat modules for edge, coping, tactile strip and canopy, plus bench, bin, lamp and gantry; each is reusable with a documented mounting origin. Reject a single huge combined train or platform mesh: it impedes doors, reuse, streaming and collision. Reject extremely fine physical detailing, heavy bespoke PBR maps and a rectilinear placeholder presented as final; preserve silhouette and use a restrained material palette. Blender coordinates and FBX export axis mapping will be explicitly documented and measured; Blender's native Z-up versus project's +Y-up convention needs an export transform, not an undocumented assumption.

Budget proposal, not measured: <= 18,000 triangles per render mesh and <= 60,000 render triangles for both complete cars; <= 8,000 per kit component. The project view budget applies to all visible assets, not only these. Render and collision meshes must be separate; no continuous invisible slab may block door apertures. Reproducible generator produces the editable .blend, then a separate exporter reads it without destructive edits. Reports will include evaluated per-mesh triangles, total counts, dimensions, manifold checks, pivot and material lists, as well as three headless renders. Budget and geometry are provisional until independently verified.

## 3. Interfaces needed

- **vector:** approved track coordinate frame and rail-top datum; gauge, curve minimum and clearance envelope; car root/pivot and bogie positions; coupling interface and car spacing; door IDs, animation travel, state ownership, anchoring/movement requirements, and boarding collision behavior. No contract changes assumed.
- **atlas:** station platform top height above rail, platform gap and edge setback, kit placement grid and canopy clearance; shared art-bible materials, colors and sign dimensions; central-station footprint and interfaces for future architecture.
- **lumen:** destination/sign display aperture dimensions and readable UI surface requirements, agreed with atlas; no UI implementation by mason.
- **Manager:** ratify architecture and asset budgets; approve the report and coordinate interfaces; run and record Studio imports, collision/walkability, dimensions, render-fidelity transitions and target-device profiling.

## 4. Exact proposed file plan

First push: `docs/reports/mason-phase1-report.md` only. All subsequent asset paths below remain within mason-owned folders. Scripts live with their assets, not in shared `tools/**`.

Train:
- `assets/trains/README.md` (reference provenance and scale)
- `assets/trains/EMU-1/README.md`
- `assets/trains/EMU-1/build_emu.py`
- `assets/trains/EMU-1/export_emu.py`
- `assets/trains/EMU-1/EMU-1.blend`
- `assets/trains/EMU-1/EMU-1.fbx`
- `assets/trains/EMU-1/renders/front-three-quarter.png`
- `assets/trains/EMU-1/renders/side.png`
- `assets/trains/EMU-1/renders/cab-interior.png`
- `assets/trains/EMU-1/mesh-stats.json`

Platform kit:
- `assets/stations/platform-kit/README.md`
- `assets/stations/platform-kit/build_platform.py`
- `assets/stations/platform-kit/export_platform.py`
- `assets/stations/platform-kit/platform-kit.blend`
- `assets/stations/platform-kit/edge.fbx`
- `assets/stations/platform-kit/coping.fbx`
- `assets/stations/platform-kit/tactile.fbx`
- `assets/stations/platform-kit/canopy.fbx`
- `assets/stations/platform-kit/bench.fbx`
- `assets/stations/platform-kit/bin.fbx`
- `assets/stations/platform-kit/lamp.fbx`
- `assets/stations/platform-kit/gantry.fbx`
- `assets/stations/platform-kit/mesh-stats.json`

No shared `docs`, `src`, or `tools` paths other than the explicitly requested report. Later station buildings, bridges and portals need a separate scoped file plan and architecture review.

## 5. Risks

Most likely: Blender-to-Studio unit/axis/pivot conversion or platform gap differs from assumptions, causing a visually plausible but unusable train; mitigate with a Manager-run measured test before integration. Other risks: door proxies trapping passengers, mesh limits after modifier evaluation, draw calls from too many material splits, streaming seams and unreviewed visual consistency. No Studio or Roblox account is available here, so importing, runtime collisions, performance and multiplayer cannot be verified by this agent. Headless Blender is currently absent from this environment and must be installed or supplied before asset verification.

## 6. Not in Phase 1

No full city, production railway systems, contracts, gameplay, service code, network, full station buildings, bridges, tunnel portals, additional fleets, unvetted marketplace content, or claims of Studio import/publishing. Full-scale asset production is held until architecture approval; this report does not assert that approval has occurred.
