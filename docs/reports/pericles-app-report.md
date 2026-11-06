# Civitas — app report

**Pericles · 5 November 2026**  
**Status: experimental Roblox prototype, not a finished or Studio-verified game.**

## What is in the current place

- A procedurally generated District A historic-core blockout with 302 ordinary buildings and 12 landmark massings. The planned horizontal walking route runs 1,718.5 studs from the spawn area to the test platform. Route continuity and clearance were checked against generated geometry, not by walking it in Roblox.
- A placeholder station with a rear doorway, ramp, test platform, canopy, benches and tactile edge. The current station and track are provisional; they are not the final Central station or planned network.
- A separate experimental straight-track, two-car placeholder shuttle. A driver can be seated using a prompt; server-validated controls use a deterministic simulation with timeouts, direction and door interlocks, and track-end safeguards. These are prototype safeguards, not railway signalling.
- Six experimental passenger seats, a boarding prompt and an alighting button with server-side stop, door, platform and occupancy checks. Roblox's normal seat exit is not blocked and can bypass that button. The implementation has not been tested in Studio.
- A provisional pan-and-zoom planned-network map. The diagram is not a live service map; the test shuttle is separate. Standard Roblox movement controls remain in place.
- A facade pass with windows on upper floors and non-colliding decorative overlays. This addresses part of the facade snagging issue; it does not prove the full walkability audit is complete.

The isolated `rail-test.project.json` is a separate prototype, not the integrated city. The shipped place is built from `default.project.json`; the world and railway are created by scripts at runtime.

## Verification and visual review

`bash tools/verify.sh` passed on 5 November 2026. It ran 125 client/general tests, 40 rail tests, nine city acceptance tests, formatting, lint and Luau analysis, static checks, exported the plan and concepts, checked essential instances in the Rojo place, and built both places. Deterministic simulation telemetry is evidence of the pure simulation, not an in-engine run.

The city recipe estimates 10,343 parts and the separate track/train about 661 more; neither figure is an observed runtime measurement, draw-call count or mobile performance result. Concept images were generated and visually reviewed, including the plan, street, station, shuttle, controls and passenger interface. They are **not Roblox Studio screenshots**; the blockout remains sparse and the train/station are placeholder art.

## What still blocks completion

1. Roblox Studio was unavailable. Verify actual building collisions, full walking route, ramp and platform access, spawn sightlines, lighting, streaming and mobile frame time. Audit remaining decorative collisions.
2. Verify driver and passenger transport on anchored moving seats, boarding prompts, alighting placement and normal seat exits, train controls, replication, interlocks, disconnect behavior, exploits, gamepad/touch UI and multiple clients. If seated characters do not travel reliably with the train, redesign the transport before calling it playable.
3. Complete a real station/network and reconcile its coordinate frame and geometry with the final assets. Replace the placeholder shuttle with the approved train; implement actual animated doors, safe boarding/alighting, multiple stations, service scheduling, multi-train separation and robust operational systems.
4. Build the remaining districts, environment, interiors, NPC/traffic systems and intended gameplay/progression. Establish in-engine art, accessibility and performance acceptance and review asset licensing.

## How to run and reproduce

Open the built `civitas-place-updated.rbxlx` in Roblox Studio and follow the detailed route and two-client checklist in `PLAYTEST.md`. For the repository build, install the pinned tools with `bash tools/install-tools.sh`, then run `bash tools/verify.sh`. The branch is `pericles/facade-walkability`; implementation and playtest notes are in `docs/reports/pericles-shuttle-integration.md` and `PLAYTEST.md`. Earlier Pericles reports describe their historical baselines and should not be read as the current state.
