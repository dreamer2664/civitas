# CIVITAS — Norman's app report

**6 November 2026 · experimental Roblox build · not release-ready**

## Executive assessment

Civitas is still far from the complete railway world in the master directive. It now has a stronger, reproducible two-stop prototype, not a finished city or a proven multiplayer game. No Roblox Studio was available during this work. Builds, pure simulations, sampled geometry and Blender renders are reported separately from live game verification.

I read the Civitas directive, architecture, phase records, playtest notes, relevant agency-ops handoff, and current specialist branches. The handoff was historical: `main` had progressed to `eaad19c`, while the most integrated city/shuttle work was on `pericles/facade-walkability` at `9e8e737`. I continued that work on **`norman/civitas-integration`**, preserving its history and the other agents' branches. I did not copy private agency-ops credentials or unrelated project information into this public repository.

## What I implemented

- **Automatic passenger-service prototype:** S1 travels between Civitas Central and West Gardens when no driver occupies the cab. Pure service rules control approach, 18-second station dwell, a 1.5-second door-closing interval and direction reversal. Commands still pass through the existing validated TrainSimulation boundary. Manual driving takes over when a driver is seated; automatic recovery reselects a stop after the driver leaves.
- **Second provisional halt:** a 200-stud platform, tactile edge, canopy, benches and station signs at X=-450. A separate forecourt walk and approach connect it to Central without crossing the rail or cutting through the station walls. Both stops share the existing rail/platform datum. This is a short straight-track shuttle, not the proposed Line 1 loop.
- **Passenger flow:** both stops participate in server-derived alignment checks. Driver boarding now also requires stopped motion, open doors and a stop. Alighting uses the current stop rather than always teleporting to Central; repositioning is delayed for seat-weld release. Actual weld/seat behavior remains unverified.
- **Train geometry:** extracted the shared production recipe into RailGeometry; replaced the solid visual body with floor, side panels, glazing and door apertures, added visible seat cushions/backs and cylindrical wheels, and animated the platform-facing sliding door leaves. Geometry remains an original procedural placeholder, not the approved imported EMU-1.
- **Service interface:** live automatic/manual state, next-stop information, station dwell countdown, stale-status handling and a passenger panel with the current stop. Passenger controls moved above the stock mobile thumb zones. The service board yields to seated state, and both panels hide when the planned-network map opens. This is source/layout review, not touch or gamepad acceptance.
- **Station art and fixes:** original roof, portico, lettering, cornice, rear windows and pilasters; non-colliding decorative trims; correctly oriented fountain basin; deterministic small surface offsets to reduce coplanar overlap artifacts. This is an incremental shell pass, not a monumental final station.
- **Reproducible visual review:** the exporter executes CityBuilder and RailGeometry in Lune's data model, then Blender renders the authored part surfaces. No attractive substitute train or fictional architecture is inserted. Lighting/material shading are presentation-only. Six 3D views, a telemetry plot and a labelled UI layout study were inspected.

## Verification achieved

`bash tools/verify.sh` passed on this machine after the final source changes.

| Check | Result | What it does not prove |
|---|---|---|
| Formatting, lint, Luau analysis | Passed; zero reported diagnostics in checked lanes | Roblox execution |
| Rail unit tests | 44 passed, 0 failed | Seats, replication, actual remotes |
| Client/general tests | 125 passed, 0 failed | Visual layout, input feel, device safe areas |
| City acceptance tests | 9 passed, 0 failed | Humanoid traversal or streaming |
| Repeated-service simulation | 720 seconds at 30 Hz; 13 arrivals including startup | A multiplayer journey |
| Simulation peak / doors | 21.55 km/h; zero simulated unsafe door states | Physical doors or train safety certification |
| Prototype docking correction | Maximum 0.026 studs in measured run; guarded to <=0.6 studs at <=0.12 m/s | Genuine stopping accuracy; it is an explicit snap |
| New west-connection corridor | 2,328 sampled points across 2.5-stud width; no unsupported/blocked samples | Continuous swept volume or accessibility certification |
| West ramp | Rise/run 0.082153, below 1:12 | Actual Roblox slope/collision behavior |
| Executed data-model counts | 10,362 city + 771 railway = 11,133 BaseParts | Runtime memory, draw calls or mobile frame time |
| Rojo places | Main and isolated rail-test build; 13 main-place essential instances checked | Studio import or publishing |

The ordinary city plan retains 302 buildings, 12 landmarks and a 1,718.5-stud primary route. The new west connection is separately sampled; that distance is not added to the primary route length. Logs, telemetry and geometry summaries are under `evidence/norman/`.

## Render review — “is this good enough?”

**Good enough as honest prototype evidence: yes. Good enough as final production art: no.**

The first lighting setup washed out colours and was rejected. A first city camera was obstructed by a blank wall and was replaced with a pedestrian-axis view. Surface overlap and the initial west-ramp slope/join were corrected before acceptance. All eight final images were opened and inspected, not merely generated.

Central arrival, historic-core street, shuttle detail and Central forecourt are the curated 3D selection. The aerial and West Gardens views remain useful diagnostic evidence, but expose sparse surroundings and hard blockout boundaries; they are not final beauty shots. The city still has repetitive boxes, blank side elevations, minimal public-realm dressing and a plain station roof. The door/seat interior is only a prototype. The labelled interface study is not a Studio screenshot. The ZIP also includes a separate evidence folder for the service plot and UI study.

## What still blocks a finished game

1. **Live transport and security acceptance:** two-client Studio testing of moving anchored seats, weld release, door state and animation timing, prompt reach, disconnect/respawn recovery, seat exit while moving, remote spam, streaming and driver/passenger replication. Normal Roblox seat exit still bypasses the alight button; this has not been trapped or falsely declared safe. Door parts are visual/non-colliding and boarding remains prompt-to-seat, not walk-through entry.
2. **Real railway integration:** reconcile the final station, EMU-1 assets, track coordinate frame and the separate vector rail-core branch. Build the required loop and at least three connected stations, signals, scheduling and multi-train separation. Running the separate rail service alongside this geometry without reconciliation would create conflicting systems.
3. **In-engine art/performance:** replace placeholder train/station geometry, add coherent materials, lighting, public spaces and district dressing, verify collisions and measure representative mobile performance. Part counts alone are not performance approval.
4. **Full scope:** remaining districts, airport/harbour, interiors, NPCs/traffic, jobs, progression, persistence, audio and release onboarding remain unfinished. No separate web/Android port was produced; the current application is a Roblox place.

Do not publish this as the finished game. Use the supplied place for the new `PLAYTEST.md` checklist, then address transport failures before adding more world massing. No continuous background production is promised after this session.

## Reproduce and open

1. `bash tools/install-tools.sh`, then `bash tools/verify.sh`.
2. For the 3D review: install `tools/review/requirements.txt`, run `lune run tools/review/export_geometry.luau`, then `bash tools/review/render_all.sh`.
3. `lune run tools/review/measure_service.luau` and `python tools/review/render_service_evidence.py` regenerate service evidence after the geometry renders exist.
4. Open `deliverables/norman/civitas-norman.rbxlx` in Roblox Studio and follow `PLAYTEST.md`. Scripts create the city and railway at runtime.
5. The native review scene is supplied separately as `civitas-norman-review.blend`; regeneration scripts and camera recipes remain in the repository.
