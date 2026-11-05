# Isolated rail test

This is a **separate experimental Roblox place**, not District A and not the finished game. It exists to exercise a small end-to-end driving slice without inventing a station/rail alignment in the city. It uses simple procedural boxes, not the EMU-1 asset. Studio runtime, multiplayer, seat transport and mobile input are unverified.

## Build and try in Studio

From the repo root, after `tools/install-tools.sh`:

```sh
rojo build rail-test.project.json --output build/rail-test.rbxlx
# Or run the full check/build/render pipeline:
bash tools/verify.sh
```

Open `build/rail-test.rbxlx` in Roblox Studio and start a local server and player. You spawn on the platform; approach the train and trigger **Board driver seat**. Use the screen buttons or W power, C coast, S brake, F forward, R reverse. Controls latch; the client repeats intent every 0.2 seconds, and stale commands cause braking. Open doors only at the platform while stopped, close them before applying power. Door state is simulated text/interlock only; no door animation or passenger boarding exists. Test leaving the seat, disconnecting the client, opening doors while moving, trying to reverse while moving, and commanding a train near each end. Server code accepts intent only from the player whose character occupies the seat and limits messages per player. Check all results and errors in Studio; none are claimed to have been tested there.

The seat is on the roof for a visible test affordance; the proximity prompt is a placeholder boarding interaction. Moving an anchored Roblox seat with `Model:PivotTo` and carrying a seated character is a particularly important runtime test. There is no guarantee it works correctly until tested. If it fails, stop and redesign the character transport; do not claim the game loop works.

## Scope and safety

- One straight 1,200-stud test track, one 44-stud placeholder train, one platform and no operational signals. The city/network coordinate mismatch is unresolved.
- `DriverControl` validates finite values, bounds and directions. The pure `TrainSimulation` adds a dead-man timeout, reverser restriction, door/traction interlock, speed intervention and simple track-end safety margin. The last-resort hard clamp can stop the train unrealistically; this is **not** a railway protection system, and it does not account for other trains, switches, brakes failing or train length beyond the margin.
- A per-player token bucket and seat-occupancy check protect the prototype remote. This is not a security audit or production authorization design. Roblox server authority and anti-exploit behavior need adversarial multiplayer testing.
- Server time is `os.clock`; heartbeat catch-up is capped and excess elapsed time is dropped under stalls. A dropped tick slows the simulation rather than guaranteeing real-time timetable behavior.
- No actual asset import, live railway service, passengers, multi-train separation, economy, signal network, persistence or production HUD is present. The separate experiment must not be merged into the city as if those things exist.

## Automated evidence

`tests/rail/train_simulation.spec.luau` covers hostile commands, control timeout, platform/doors, reverser, bounds, and retreat from an end margin. `tests/rail/kinematics.spec.luau` covers reverse traction, braking to rest, static hold and reverse-grade braking. `tools/measure_train_simulation.luau` generates data for `tools/render_train_simulation.py`; `tools/render_rail_test.py` produces a geometry concept. These are reproducible diagrams, not Studio screenshots or proofs of in-engine behavior. `tools/verify.sh` checks formatting/lint/types and builds both places.
