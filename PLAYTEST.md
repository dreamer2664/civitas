# Civitas — District A and experimental shuttle playtest guide

This release contains the generated historic-core slice, not the full 10,000 × 8,000-stud city. The Rojo artifact contains the project scripts/configuration; the server bootstrap generates the District A geometry when a test server starts.

## Build the current branch

Run `rojo build default.project.json --output build/civitas.rbxlx`, open that file in Studio, and start a local server/player. The old `v0.1-city` tag and its artifacts predate the experimental shuttle and the newer facade work.

## Fetch the older tagged place artifact

1. Open the [Rojo place artifact workflow](https://github.com/dreamer2664/civitas/actions/workflows/rojo-place.yml).
2. Select the successful run for tag `v0.1-city` (the run's ref is `refs/tags/v0.1-city`). The artifact name is `civitas-world-blockout-<full commit SHA>`.
3. Under **Artifacts**, download the ZIP and extract `civitas-world-blockout.rbxlx`.
4. In Roblox Studio, use **File → Open from File** and select the extracted `.rbxlx`.
5. Use **Test → Start** (one local player). Wait for the server Output message beginning `Civitas World:`; it reports the generated buildings, landmarks, route length, and actual generated part count.

The tag build is reproducible from `default.project.json` using the workflow's checksum-pinned Rojo 7.7.1. The artifact is built on GitHub Actions; it is not a Studio-published place.

## City interface and planned network map

The client now starts with a Historic Core sign and a MAP button. Open/close the map with the button, keyboard **M**, or gamepad **View/Select**. The diagram is explicitly labelled as a plan; the experimental one-track shuttle is separate from its proposed network. Drag the diagram to pan and use the + / - buttons to zoom. Station labels may be suppressed to avoid overlaps; zoom for more names. Roblox's normal movement controls remain in place.

In Studio test button and gamepad focus, touch drag and zoom, screen rotation, map open/close across respawns, font readability, label collisions, and interaction with Roblox's own touch controls. The interface has only been statically checked and illustrated with approximate concept images, not observed running in Studio. Pinch zoom, live player position, and real station status are not implemented. The experimental shuttle has not been tested in Studio.

## Walk the acceptance route

World coordinates are in studs (`X` east/west, `Z` along the route, `Y` vertical). The generated route is **1,718.5 studs** (plan centerline, excluding elevation change). Use these waypoint anchors in order; increasing `Z` leads from the spawn side toward the station in this slice:

1. Sidewalk spawn: `(136.75, -640)`.
2. Historic-grid sidewalk: `(136.75, 20)`.
3. Square north-west walk: `(150, 20)`; cross the public square at `(200, 75)`.
4. Leave via `(150, 130)` and rejoin the sidewalk at `(136.75, 130)`.
5. Follow the sidewalk to the station forecourt `(136.75, 810)`.
6. Continue through the station entrance `(120, 858)` to the placeholder concourse `(120, 925)`.
7. Pass through the rear doorway, ascend the shallow ramp and reach the experimental platform `(120, 1010.5)`.

The coordinates are review anchors, not a teleport sequence. Walk the actual collidable surfaces. Watch the Output window for script errors and note any fall, snag, unexpected step, collision, or stream-in pause. Do not use a Studio teleport to claim the route was walked.

## Experimental shuttle checklist

The single test track is at `Z=1027.0714`, separate from the proposed network. At the platform, use **Board test shuttle** to take the driver seat. The control panel should appear only while seated; use POWER, COAST, BRAKE, FORWARD and REVERSE buttons (or W, C, S, F, R). Doors are a state/interlock only, not animated doors or passenger boarding. Stop at the test platform to open them; close before powering. Track ends use an experimental brake and a hard-clamp fallback, not real signalling.

In Studio verify that a seated character actually follows the server-moved anchored seat, that exiting or disconnecting applies the brake, that direction changes while moving are blocked, that platform and door interlocks work, and that two clients cannot control the same train. Check prompt reach, touch/gamepad input, server Output, replication and mobile performance. **None of these runtime claims have been verified here.** If seat transport fails, the shuttle is not playable and needs redesign; do not treat it as a completed service.

## What to inspect

- Sidewalk continuity at all crossings, radius-cut curb returns, and the five street approaches clipped at the Crooked Lane Court and Market Cut Square edges.
- The three 8.5-stud narrow-lane alignments in each direction, six diagonal/jog cuts, variable blocks, and four irregular superblocks. Check that removed internal street runs read as courts rather than road seams.
- The main square and two pocket squares: paving should meet surrounding walk surfaces without a visible collision lip or hole.
- Articulated ground floors (darker street band, shopfront glazing/door cues, awnings or entry lintels) versus the deliberately simple upper-storey massing; identify repeated or unreadable frontages.
- The final forecourt, entry opening, concourse, rear doorway, ramp and test platform. Check ramp slope, seam heights, clearance from canopy columns, and boarding-prompt reach. The plan test does not prove live traversal.

Record the Studio version, device/emulation mode, route completion, observed steps/gaps, Output errors, and any screenshots with the issue report. Keep the generated-part count separate from GPU draw calls or mobile performance measurements.

## Known rough edges / not yet proven

- The station remains a procedural placeholder shell with an experimental platform and single test track; it is **not** integrated with Pave's separate Central station proposal. District A currently uses entry `(120, 858)` and concourse top `Y=0.63`; the separate proposal specifies a different world footprint and elevation. Coordinate, footprint, rail-datum, and square/sidewalk-height agreement remains tracked in [issue #4](https://github.com/dreamer2664/civitas/issues/4) and [station PR #6](https://github.com/dreamer2664/civitas/pull/6).
- The route-length, geometry-clearance, and part-recipe checks are automated plan/build checks, not Roblox physics or humanoid traversal. Studio import, actual grounding/collision at seams, streaming behavior, and mobile frame time/draw calls still need measured playtest evidence.
- The city is still blockout massing: no shop interiors, detailed building interiors, street trees/furniture, NPCs, or traffic. Buildings remain procedural; no sourced building kit is included.
- Facade windows, door cues, lintels and awnings are now non-collidable and non-queryable; the underlying building mass remains solid. This addresses the facade portion of [WALK-005](https://github.com/dreamer2664/civitas/issues/8), but still needs Studio collision verification and a broader decorative-detail audit. Spawn landmark sightlines ([WALK-007](https://github.com/dreamer2664/civitas/issues/9)) and the live station/platform gate ([WALK-006](https://github.com/dreamer2664/civitas/issues/10)) remain open. The suggested spawn candidate is not applied; don't infer full landmark visibility from sampled rays.

## Build record

- Main release baseline before this guide: `ce23e4df1e76d11791ec06c0c797e49b7e95852f`.
- District A plan: 302 ordinary buildings, 12 landmarks, 50 blocks, 4 superblocks, 2 pocket squares, 10,343 planned city-builder `BasePart`s (25,000 budget), excluding the separately generated test railway and train (about 655 more parts). This is an increase from 1,920 after adding non-colliding upper-window overlays; actual runtime count, draw calls and mobile frame time remain unmeasured.
- CI workflow: [Rojo place artifact](https://github.com/dreamer2664/civitas/actions/workflows/rojo-place.yml). The release tag triggers its own build and artifact upload.
