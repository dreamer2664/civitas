# Civitas v0.1-city — District A playtest guide

This release contains the generated historic-core slice, not the full 10,000 × 8,000-stud city. The Rojo artifact contains the project scripts/configuration; the server bootstrap generates the District A geometry when a test server starts.

## Fetch the tagged place artifact

1. Open the [Rojo place artifact workflow](https://github.com/dreamer2664/civitas/actions/workflows/rojo-place.yml).
2. Select the successful run for tag `v0.1-city` (the run's ref is `refs/tags/v0.1-city`). The artifact name is `civitas-world-blockout-<full commit SHA>`.
3. Under **Artifacts**, download the ZIP and extract `civitas-world-blockout.rbxlx`.
4. In Roblox Studio, use **File → Open from File** and select the extracted `.rbxlx`.
5. Use **Test → Start** (one local player). Wait for the server Output message beginning `Civitas World:`; it reports the generated buildings, landmarks, route length, and actual generated part count.

The tag build is reproducible from `default.project.json` using the workflow's checksum-pinned Rojo 7.7.1. The artifact is built on GitHub Actions; it is not a Studio-published place.

## City interface and planned network map

The client now starts with a Historic Core sign and a MAP button. Open/close the map with the button, keyboard **M**, or gamepad **View/Select**. The diagram is explicitly labelled as a concept: its stations and train services are not operational. Drag the diagram to pan and use the + / - buttons to zoom. Station labels may be suppressed to avoid overlaps; zoom for more names. Roblox's normal movement controls remain in place.

In Studio test button and gamepad focus, touch drag and zoom, screen rotation, map open/close across respawns, font readability, label collisions, and interaction with Roblox's own touch controls. The interface has only been statically checked and illustrated with approximate concept images, not observed running in Studio. Pinch zoom, live player position, real station status, and a usable train service are not implemented.

## Walk the acceptance route

World coordinates are in studs (`X` east/west, `Z` along the route, `Y` vertical). The generated route is **1,632.999280 studs** (reported as 1,633.0). Use these waypoint anchors in order; increasing `Z` leads from the spawn side toward the station in this slice:

1. Sidewalk spawn: `(136.75, -640)`.
2. Historic-grid sidewalk: `(136.75, 20)`.
3. Square north-west walk: `(150, 20)`; cross the public square at `(200, 75)`.
4. Leave via `(150, 130)` and rejoin the sidewalk at `(136.75, 130)`.
5. Follow the sidewalk to the station forecourt `(136.75, 810)`.
6. Continue through the station entrance `(120, 858)` to the placeholder concourse `(120, 925)`.

The coordinates are review anchors, not a teleport sequence. Walk the actual collidable surfaces. Watch the Output window for script errors and note any fall, snag, unexpected step, collision, or stream-in pause. Do not use a Studio teleport to claim the route was walked.

## What to inspect

- Sidewalk continuity at all crossings, radius-cut curb returns, and the five street approaches clipped at the Crooked Lane Court and Market Cut Square edges.
- The three 8.5-stud narrow-lane alignments in each direction, six diagonal/jog cuts, variable blocks, and four irregular superblocks. Check that removed internal street runs read as courts rather than road seams.
- The main square and two pocket squares: paving should meet surrounding walk surfaces without a visible collision lip or hole.
- Articulated ground floors (darker street band, shopfront glazing/door cues, awnings or entry lintels) versus the deliberately simple upper-storey massing; identify repeated or unreadable frontages.
- The final forecourt, entry opening, and concourse floor. The 1,633-stud acceptance route ends at this concourse shell; it does not continue onto a platform.

Record the Studio version, device/emulation mode, route completion, observed steps/gaps, Output errors, and any screenshots with the issue report. Keep the generated-part count separate from GPU draw calls or mobile performance measurements.

## Known rough edges / not yet proven

- The station is a procedural placeholder shell. It has no rails or platforms and is **not** integrated with Pave's separate Central station proposal. District A currently uses entry `(120, 858)` and concourse top `Y=0.63`; the separate proposal specifies a different world footprint and elevation. Coordinate, footprint, rail-datum, and square/sidewalk-height agreement remains tracked in [issue #4](https://github.com/dreamer2664/civitas/issues/4) and [station PR #6](https://github.com/dreamer2664/civitas/pull/6).
- The route-length, geometry-clearance, and part-recipe checks are automated plan/build checks, not Roblox physics or humanoid traversal. Studio import, actual grounding/collision at seams, streaming behavior, and mobile frame time/draw calls still need measured playtest evidence.
- The city is still blockout massing: no shop interiors, detailed building interiors, street trees/furniture, NPCs, or traffic. Buildings remain procedural; no sourced building kit is included.
- Facade windows, door cues, lintels and awnings are now non-collidable and non-queryable; the underlying building mass remains solid. This addresses the facade portion of [WALK-005](https://github.com/dreamer2664/civitas/issues/8), but still needs Studio collision verification and a broader decorative-detail audit. Spawn landmark sightlines ([WALK-007](https://github.com/dreamer2664/civitas/issues/9)) and the live station/platform gate ([WALK-006](https://github.com/dreamer2664/civitas/issues/10)) remain open. The suggested spawn candidate is not applied; don't infer full landmark visibility from sampled rays.

## Build record

- Main release baseline before this guide: `ce23e4df1e76d11791ec06c0c797e49b7e95852f`.
- District A plan: 302 ordinary buildings, 12 landmarks, 50 blocks, 4 superblocks, 2 pocket squares, 10,326 planned `BasePart`s (25,000 budget). This is an increase from 1,920 after adding non-colliding upper-window overlays; actual runtime count, draw calls and mobile frame time remain unmeasured.
- CI workflow: [Rojo place artifact](https://github.com/dreamer2664/civitas/actions/workflows/rojo-place.yml). The release tag triggers its own build and artifact upload.
