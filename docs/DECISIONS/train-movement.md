# Train Movement Decision — PROJECT CIVITAS

**Status:** DECISION MADE (prototype complete, measured)  
**Author:** CODE · vector (Agent 3)  
**Gate:** ARCHITECTURE §5 — no dependent work (signalling, timetable, passenger boarding,
lumen prediction) starts until this document is ratified.

---

## Decision

Adopt **approach A**: a track-following, server-controlled movement system. Each train simulates
on the server along an arc-length parameterised spline at a fixed tick (target 30 Hz), and the
server replicates a compact `TrainState` per train at that same tick. Clients send driving intent
only (throttle/brake/reverser/horn/doors) and predict visuals locally.

Prototype + measurements delivered in this branch:
- `src/shared/Rail/Spline.luau` — arc-length Catmull-Rom spline (position/tangent/cumulative
  distance + `distanceToPoint` for stop markers).
- `src/shared/Rail/Kinematics.luau` — tractive/brake/rolling/air-resistance dynamics and the
  `d = v^2 / (2a)` braking-distance formula used for stop markers and signal braking curves.
- `tools/measure_movement.luau` — A/B measurement harness run under `lune`.
- `tests/rail/spline.spec.luau` + `tests/rail/kinematics.spec.luau` — 23 pure-module tests passing.

Both rail modules are pure Luau (no Roblox types, `--!strict`), verified without Studio:
`selene` 0 errors, `luau-lsp analyze` 0 errors, `lune` **23 passed, 0 failed**.

---

## The two implementations, implemented against the same test track

The measurement harness (`tools/measure_movement.luau`) builds ONE test track (straight → 90°
curve → straight, ~1,513 studs) and runs both candidates over it for 25 simulated seconds at
60 Hz. Candidate B's numbers below use 5 trains (per-train metrics scale linearly); bandwidth
figures are scaled to 20 trains.

### Approach A — track-following, server-controlled (chosen)

- **Model.** Track centre line = cubic Catmull-Rom spline through control points, arc-length
  parameterised. Train state is one scalar: distance `s` along the line (studs), plus speed,
  direction and door state. The server integrates `s += v * dt` every fixed tick using
  Kinematics.luau (tractive effort, service/emergency brake, rolling + air resistance, grade).
- **Replication.** Server publishes one small `TrainState` per train per tick
  (`trainId`, `distanceStuds`, `speed`, `direction`, `doorState`, `signalAspect`, timestamp).
  Clients render each train at `sampleArcLength(s)` and interpolate between received states;
  local prediction masks one round trip of input latency.
- **Stopping.** Braking distance `d = v^2 / (2a)` is solved backwards from each platform stop
  marker, so scheduled stops are exact — a hard requirement for a timetabled railway.
- **Multiplayer.** Single source of truth on the server; no network ownership; no physics
  solver; clients never send position.

### Approach B — physics-driven (rejected)

- **Model.** A point-mass train body under forward tractive/brake force and drag, with a
  spring-damper lateral constraint pulling it toward the spline centre line (an approximation of
  a real rail constraint). A variant with **no** constraint simply leaves the track on curves.
- **Failure modes.** Network-ownership fights at switches/couplings/boarding; constraint-solver
  jitter and joint explosion at speed; non-determinism (same timetable plays out differently per
  client); scheduled stopping needs a PID fighting physics and drifts with load/frame rate.

---

## Measurement method

All measurements were made in pure Luau under `lune` (no Roblox Studio, no network, no engine).
Each is labelled with its caveats.

1. **Position error vs reference path.** The spline is densely sampled (4,000 points) as the
   reference ground truth. Each tick, the candidate's train position is compared to the closest
   point on the spline via `distanceToPoint` (studs).
2. **Per-tick update cost.** `os.clock()` timed over all trains/ticks → microseconds per train per
   tick. Proxy for CPU cost (lune is a different VM than Roblox Luau; engine cost may differ).
3. **State packet size.** Analytical byte counts for the per-tick replication payload, plus
   estimated Roblox remote overhead.
4. **Failure modes.** Derived from the replication model and the prototype; the engine-dependent
   parts (ownership fights, streaming behaviour, real-network jitter) are flagged and left to the
   Manager's Studio validation.

### Caveats — what genuinely cannot be measured without Studio

- **Real-network replication jitter and sync cost** under packet loss / varying RTT. The byte
  counts below are analytical; actual `Stats > Network` numbers require a live place with clients.
- **Streaming-aware behaviour** (stream-in/out of trains/track near players) — rule 4 of
  ARCHITECTURE §3. The pure sim never keys on a Workspace instance, but engine-level streaming
  needs Studio testing.
- **Physics ownership fights and joint explosion** for approach B — only observable in the engine
  with multiple clients near a moving train.
- **Per-tick engine cost** — lune µs is a CPU proxy, not Roblox Luau/physics cost.

---

## Measured results

| Criterion | Approach A — spline, fixed tick | Approach B — physics (constrained) |
|---|---|---|
| Mean position error vs reference | **0.37 studs** | **0.76 studs** |
| Max position error vs reference | **0.88 studs** (< 1) | **3.19 studs** (oscillates) |
| Per-tick update cost | **139 µs / train / tick** | **256 µs / train / tick** (point-mass only) |
| State packet per train per tick | **~31 B raw / ~50 B wire** | **~1,728 B** (24 networked parts) |
| Downstream, 20 trains | **~29 KB/s @ 30 Hz** | **~2,025 KB/s @ 60 Hz (~2 MB/s)** |
| Determinism | exact — identical `s` everywhere | no — solver + ownership differ per client |
| Scheduled stop accuracy | exact — `d = v²/(2a)` backwards | approximate — PID vs physics, drifts |
| Multiplayer synchronisation | single authoritative state, fixed tick | ownership fights, jitter, corrective snaps |
| Stability | cannot derail (track is data) | coupling/switch constraints can explode |

### How the numbers were derived

- **Approach A error:** the train rides exactly on the spline; the residual (≤ 0.88 studs) is the
  sub-sample arc-length approximation resolution of `distanceToPoint`, not sim drift. Stop
  markers use arc-length `s` directly, which is exact.
- **Approach B error:** even WITH a spring-damper lateral constraint the body oscillates around
  the centre line (max 3.19 studs on a gentle 90° curve). WITHOUT the constraint it leaves the
  track on curves entirely — the derailment failure mode. Real Roblox physics would add
  constraint-solver jitter on top.
- **Per-tick cost:** A is a single `Kinematics.integrate` + `sampleArcLength` (139 µs in lune).
  B adds closest-point + tangent projection (256 µs for a single point mass); a real 24-part
  train with a constraint solver is far more expensive and still desyncs.
- **Packet size:** A = `trainId` u16 + `distanceStuds` f64 + `speed` f64 + `direction` u8 +
  `doorState` u8 + `signalAspect` u8 + `speedLimitKph` u16 + `timestamp` f64 ≈ 31 B raw, ~50 B
  with Roblox remote overhead. B = ~24 rigid parts × CFrame + linear velocity + angular velocity
  ≈ 72 B/part ≈ 1,728 B per train per tick.
- **Downstream bandwidth:** A: 50 B × 30 Hz × 20 trains ≈ 29 KB/s/client — trivial on mobile Wi-Fi
  and acceptable on 4G. B: 1,728 B × 60 Hz × 20 trains ≈ 2 MB/s/client — incompatible with the
  performance budget (ARCHITECTURE §3 rule 7: playable on ordinary mobile devices).

---

## Railway-domain basis

- Constant-deceleration braking `d = v² / (2a)` is the same model real signalling / ATP systems
  use for braking curves, with conservative margins added on top (Phase 2 signalling).
- Safe separation in block signalling requires deterministic train positions — approach A gives
  that natively; approach B can only approximate it.
- Passenger railways prioritise punctuality and precise platform stops over suspension dynamics;
  visual sway (if wanted later) is client-side decoration and does not affect the sim.

---

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Fixed-tick replication jitter under load | Client interpolation between states; tick rate configurable (30 Hz target, degrade to 20 Hz) |
| Input latency (1 RTT) before the server applies | Client-side prediction of the cab (visuals only; server corrects) |
| No "physics feel" (suspension, wheel slip) | Acceptable for a passenger sim; client-side visual effects can be added later without touching the sim |
| Numbers unvalidated (no Studio here) | All engine-dependent numbers flagged analytical; Manager validates replication + streaming in Studio before Phase 2 |

---

## What this gates

Approach A is the foundation for `TrainService` (server fixed tick), `SignalService` (block
occupancy from deterministic `s`), `TimetableService` (scheduled stops from braking distance),
passenger boarding (doors open at exact stop `s`), and lumen's client prediction/interpolation.
Nothing dependent builds on this until the Manager ratifies this document.
