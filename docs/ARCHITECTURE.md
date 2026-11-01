# ARCHITECTURE — v0.1 (Manager A), to be ratified by the four agents in Phase 1

This is a starting position, not a decree. Agents may amend it through PRs. What is **not**
negotiable: module boundaries, folder ownership, and contracts being frozen before dependent work.

## 1. Repository layout (Rojo, file-synced)
```
default.project.json        Rojo project: maps src/ into the DataModel
src/
  shared/                   ReplicatedStorage.Shared
    Contracts/              frozen interface types + Remote contract (MANAGER-owned)
    Config/                 data tables: trains, speeds, fares, stops, budgets
    Rail/                   pure track geometry, spline, signalling maths (owner: vector)
    Gameplay/               pure rules: scoring, progression maths (vector + lumen shared)
    Util/                   small pure helpers, no Roblox API
  server/                   ServerScriptService
    Services/               one ModuleScript per service, ServiceBag-started
    Railway/                TrainService, TrackService, SignalService, TimetableService
    Gameplay/               EconomyService, ProgressionService, JobService, PassengerService
    Data/                   DataService (profiles), persistence, session locking
  client/                   StarterPlayer.StarterPlayerScripts
    Controllers/            one controller per feature, started by a ControllerBag
    UI/                     Roact/Fusion-free plain Luau UI components + theming
tests/                      Lune unit tests for everything under src/shared
tools/                      build/verify scripts (rojo build, selene, luau-lsp, blender)
assets/
  trains/ stations/ city/   .blend source + exported .fbx/.glb + a build script each
  catalogue/                asset research, licences, verdicts
docs/                       this documentation set
```

## 2. DataModel layout (runtime)
```
Workspace
  World/
    City/        District A..E, roads, props
    Railway/     Track, Switches, Signals, Bridges, Tunnels, Embankments
    Stations/    Stations/<Name>/{Platforms, Concourse, Markers}
    Landmarks/
  ActiveTrains/  runtime train models, server-owned
  DynamicObjects/
ReplicatedStorage
  Shared/{Contracts, Config, Rail, Gameplay, Util}
  Remotes/{Train, Station, Economy, Progression, Interaction}
ServerScriptService/Services
ServerStorage/{AssetLibrary, NPCStorage, TrainTemplates}
StarterPlayer/StarterPlayerScripts/Controllers + UI
StarterGui/{MainUI, TrainUI, MapUI, InteractionUI}
```

## 3. Non-negotiable engineering rules
1. **Server-authoritative gameplay.** The client sends *intent*, the server decides. Train position,
   money, progression and doors are server state. Clients may predict visuals only.
2. **Remote validation at the boundary.** Every remote validates: type, finite numbers, bounds,
   rate limit, player state, authority. A remote that trusts its arguments is a bug.
3. **Physics on rails (decision pending).** CODE · vector must run the A/B prototype before anyone
   builds dependent systems: track-following server-driven kinematics vs Roblox physics. Default
   expectation, to be proven or rejected with measurements: server-driven along a spline, replicated
   at a fixed tick, because physics trains fight network ownership and explode in multiplayer.
4. **Streaming-aware client code.** With instance streaming on, distant instances do not exist.
   Never cache a Workspace instance at startup; use tags, `CollectionService`, and tolerate
   stream-out. A one-time scan of the whole city is a bug.
5. **One script per system.** No mega-scripts. Services expose an API and talk through it.
6. **Data-driven content.** Trains, stations, timetables, fares, districts live in `Config/` tables,
   not in code branches.
7. **Performance budgets** (Manager-owned, enforced per PR):
   - client: **< 1,000 draw calls, < 1,000,000 triangles** in the worst-case view;
   - streaming on, `StreamingMinRadius 64`, `StreamingTargetRadius 1024`, `ModelStreamingBehavior
     Improved`, `StreamingIntegrityMode PauseOutsideLoadedArea`, `StreamOutBehavior Opportunistic`;
   - ReplicatedStorage lean: geometry stays in ServerStorage/Workspace, never replicated wholesale;
   - no per-frame work without need; no unbounded loops in `Heartbeat`;
   - NPC budget: hard cap defined per district, target ≤ 40 animated NPCs near a player.

## 4. Contract-first integration (how four agents avoid colliding)
`src/shared/Contracts/` holds **types only** — no implementations:
- `RailContract.luau` — `TrainState`, `TrainCommand`, `TrackSegment`, `SignalState`.
- `RemoteContract.luau` — every remote name, direction, request/response shape, rate limit.
- `EconomyContract.luau`, `ProgressionContract.luau`, `StationContract.luau`.
Workflow: a contract change is a PR that only Manager A merges, after both affected agents agree in
the PR thread. CODE · vector implements the server side of a contract; CODE · lumen implements the
client side. Neither invents its own field names.

## 5. Train movement prototype — the Phase 1 decision gate
`docs/DECISIONS/train-movement.md` must contain: the two implementations, the measurement method,
numbers for stability/sync cost/perf/complexity, and a chosen approach with reasoning.
**No dependent work starts before this file exists.**

## 6. Testing & evidence (what "tested" means here, given no Studio)
| Artifact | Evidence required |
|---|---|
| Luau module | `selene` clean + `luau-lsp analyze` clean + Lune unit test where pure |
| Remote/contract | unit test of validation function with hostile inputs |
| Place file | `rojo build` succeeds, `.rbxlx` committed as milestone artifact |
| Blender asset | `.blend` + build script + headless render + mesh stats (tri count, manifold) |
| City blockout | blockout `.rbxlx`/`.rbxm`, top-down render, part count + streaming audit |
| Studio import | **Manager-run**, result recorded in `docs/MILESTONES.md` |

Claims without the matching row above are rejected, not discussed.
