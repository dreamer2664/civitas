# CODE · vector — Phase 1 Report

**Project CIVITAS — Agent 3, Senior Luau Gameplay Engineer**  
Branch: `vector/rail-core` · Status: first push (report gate)  
Owner per `docs/OWNERSHIP.md`: `src/server/**`, `src/shared/Rail/**`, `src/shared/Gameplay/**`.  
`src/shared/Contracts/**` is Manager A-owned: I propose, I do not merge.

Honest limit stated up front: there is no Roblox Studio and no Roblox account in this
sandbox, so I cannot press Play, test multiplayer, or claim any engine-verified behaviour.
All verification here is `selene`, `luau-lsp analyze`, `lune` unit tests and `rojo build`;
every engine-dependent claim is flagged as analytical and to be validated by the Manager in
Studio.

---

## 1. What I read from docs/RESOURCES.md — five facts and how each changes my plan

| # | Fact (verbatim-ish) | Source | How it changes my plan |
|---|---------------------|--------|------------------------|
| 1 | "Instance streaming properties and script patterns... StreamingEnabled; distant instances do not exist." | All agents → streaming techniques | My simulation state is pure Luau (distance along a track), never keyed to a Workspace instance. `TrainService` spawns/despawns train models near players and tolerates stream-out. **No server code may cache a Workspace train/track instance at startup; track lookups are by data ID, not Instance reference.** This also protects `lune`-testability: pure modules never touch the DataModel. |
| 2 | "Roblox mesh requirements and limits — read the size/triangle limits before modelling" and `docs/STANDARDS.md`: **1 m = 3.571 studs** | All agents + STANDARDS | All rail units are studs. Train dimensions, stop accuracy and vehicle bounds come from mason's `assets/trains/EMU-1/README.md` (metres converted at 1 m = 3.571 studs). `Spline.luau` takes studs and makes no hard-coded metre assumptions. |
| 3 | "Remote events security — server authority, validation, rate limiting" | CODE · vector | `RemoteContract.luau` proposes per-remote rate limits, and every validator checks type, finite numbers, bounds, player state and authority. Validation functions live in pure modules so they can be unit-tested under `lune` with hostile inputs. |
| 4 | "DataStore, session locking, `UpdateAsync`, retries, and binding to close" | CODE · vector | Persistence (Phase 2) will use `UpdateAsync` with session locking and `BindToClose`. I design the profile data shape now as configuration data only (`src/shared/Config/`), no DataStore code in Phase 1. |
| 5 | "Parallel Luau / actors, and when **not** to use them" | CODE · vector | The train simulation stays deterministic and single-threaded per train on the server. Actors are rejected for the movement loop (ordering/debuggability cost, no benefit for fixed-tick kinematics). Pure maths modules run under `lune` with no actor model. |
| 6 | Tooling: `selene`, `stylua`, `luau-lsp`, `lune` | CODE · vector | Verification pipeline: `selene src/`, `stylua --check`, `luau-lsp analyze`, `lune run tests/run.luau`, `rojo build`. Configs already committed (`stylua.toml`, `selene.toml`). |

---

## 2. Proposed design for my area — and the trade-offs I rejected

**Adopted (prototype, Phase 1):** server-authoritative, track-following kinematics on an arc-length
parameterised cubic Catmull-Rom spline.

- `src/shared/Rail/Spline.luau` — pure geometry: control points → segments, arc-length table by
  adaptive subdivision, `sampleArcLength(s)` → `{position, tangent}`, `sample(t)`, inverse
  mapping, closest-point. Fully unit-testable without Studio.
- `src/shared/Rail/Kinematics.luau` — pure train dynamics: tractive effort, service/emergency
  brake, rolling resistance, speed clamping, braking-distance formula `d = v² / (2a)` for stop
  markers and signal braking curves. SI config (N, kg, m/s) converted to studs (1 m = 3.571
  studs).
- `src/server/Services/TrainService.luau` — thin Roblox layer: owns active trains, applies
  validated intent commands, integrates speed → distance each fixed tick (target 30 Hz), writes
  compact `TrainState` for replication at a fixed tick. Client sends intent only
  (throttle/brake/reverser/horn/doors) and predicts visuals locally (rule 1, rule 3).

**Rejected trade-offs:**

1. **Roblox physics-driven trains** (comparison B in `docs/DECISIONS/train-movement.md`): network
   ownership fights at switches/couplings, derailment explosions, non-determinism across clients,
   ~1-2 orders of magnitude more replication bandwidth, no exact scheduled stopping at platform
   markers. Ruled out for the simulation; visual sway only, client-side, if desired later.
2. **Client-authoritative position:** cheating and desync; violates rule 1 (server-authoritative).
3. **One mega-script:** violates rule 5 (one script per system). Services expose APIs and talk
   through them.
4. **Per-train actors:** determinism and debuggability cost with no benefit for fixed-tick
   kinematics (fact 5 above).
5. **Full timetable, signalling logic, passenger management, persistence:** deferred to Phase 2;
   Phase 1 is movement + contracts + spline + network diagram + report.

---

## 3. Interfaces I need from other agents (named concretely)

- **Manager A** (`src/shared/Contracts/**`, Manager-owned — I propose, Manager ratifies in the PR thread):
  - `src/shared/Contracts/RailContract.luau` exporting `TrainState`, `TrainCommand`, `TrackSegment`, `SignalState`.
  - `src/shared/Contracts/RemoteContract.luau` exporting the remote table: name, direction, request shape, response shape, rate limit for `Train.Control`, `Train.State`, `Station.Board`, `Signal.Observe`.
- **BLENDER · mason** (`assets/trains/EMU-1/`): EMU-1 `README.md` with dimensions **in studs** (overall length, bogie pivot positions, door positions, height), pivot convention (track centre line, gauge), plus the platform-kit "platform edge" mesh position relative to station origin — needed for stop markers and `Kinematics.luau` config.
- **BLENDER · atlas** (`docs/world/WORLD-MAP.md`): district and station world coordinates for the 10,000 × 8,000 layout. If it is not written yet, I define my own coordinate frame in `docs/rail/NETWORK.md` and say so (see §4).
- **CODE · lumen** (`src/shared/Contracts/` proposals): client input message shape
  (throttle −1..1, brake 0..1, reverser −1/0/1) and dashboard display fields (speedometer, signal
  aspect, destination). Lumen implements the client side; we agree field names in the Contracts
  PR thread, per rule 4 of ARCHITECTURE.md.

---

## 4. File plan — exactly the paths I will create

No file owned by another agent is touched; no Manager-owned file is edited beyond proposals.

1. `docs/reports/vector-phase1-report.md` (this file)
2. `docs/DECISIONS/train-movement.md` — A/B movement decision with measured numbers
3. `docs/rail/NETWORK.md` — 2–3 lines, 12–16 stations, junctions, depot, section types, world coordinates (frame stated explicitly)
4. `src/shared/Rail/Spline.luau` — arc-length parameterised spline (`--!strict`)
5. `src/shared/Rail/Kinematics.luau` — train dynamics model (`--!strict`)
6. `src/shared/Contracts/RailContract.luau` — PROPOSED types (`TrainState`, `TrainCommand`, `TrackSegment`, `SignalState`)
7. `src/shared/Contracts/RemoteContract.luau` — PROPOSED remote table
8. `src/server/Services/TrainService.luau` — thin server train service (stub API + fixed tick)
9. `tests/run.luau` — lune test runner (spec loader + reporter + exit code)
10. `tests/rail/spline.spec.luau` — spline unit tests
11. `tests/rail/kinematics.spec.luau` — dynamics unit tests
12. `tools/verify.sh` — `selene` + `stylua` + `luau-lsp` + `lune` + `rojo build` in one script
13. `.gitignore` — add `*.rbxlx` (place files are build artifacts, not sources)

---

## 5. Risks and the one thing most likely to go wrong

- **No Studio / no multiplayer:** replication jitter, streaming behaviour and physics cannot be
  measured by me. Every number in `docs/DECISIONS/train-movement.md` is an analytical estimate,
  explicitly flagged, with a measurement method for the Manager's Studio validation.
- **Most likely to go wrong:** the movement decision (A vs B) proves wrong in the real engine —
  e.g. fixed-tick replication jitter or spline stop accuracy under streaming — forcing rework of
  lumen's client prediction and mason's track assets. Mitigation: keep the prototype small, keep
  the decision documented with its measurement method, and let nothing dependent build on it until
  the Manager ratifies `docs/DECISIONS/train-movement.md`.
- **Coordinate-frame mismatch** between my `NETWORK.md` frame and atlas's `WORLD-MAP.md` frame.
  Mitigation: state the frame explicitly (`NETWORK.md` §1); convert coordinates when `WORLD-MAP.md`
  lands.
- **Contract freeze waiting on Manager approval** blocks lumen's client side. Mitigation: propose
  contracts early in the PR thread and keep them minimal.

---

## 6. What I will **not** do in Phase 1

- No timetable / service scheduling engine.
- No signalling implementation beyond data shapes in `RailContract.luau`.
- No passenger management or NPC spawning.
- No DataStore persistence code (data shape only).
- No client UI or controllers (lumen's lane).
- No train models, station assets, or city blockout (mason / atlas).
- No claim of Studio or multiplayer testing.
- No edits to files owned by other agents, and no merging of contracts (Manager A only).

---

**Next after this report:** `docs/DECISIONS/train-movement.md` (the A/B prototype decision — this
gates the whole railway per ARCHITECTURE §5), then `Spline.luau` + tests, the proposed contracts,
`TrainService.luau`, `NETWORK.md`, commit and push `vector/rail-core`, open PR.
