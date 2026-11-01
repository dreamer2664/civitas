# WALK · pave — walkability checkpoint

**2026-11-01 / Manager A / NOT FROZEN / CITY ACCEPTANCE BLOCKED**

Baseline: `aea670197fea6d24e5fde7b7e2a576a5ed4a0a09` (main).
Implementation branch: `walk/pave-audit`. No Studio, Roblox account, device profiling,
character simulation or multiplayer test was used or claimed.

## Delivery status

The first audit checkpoint is implemented locally, not a completed +3h spawn milestone.
No World generator or city output exists in the checked-out repository. Public remote heads
checked with `git ls-remote --heads origin`: main, lumen/ui-core, mason/emu-1, vector/rail-core;
no strata branch was published at inspection. No city geometry was fabricated or repaired.

Push attempted after the first commit. GitHub rejected authentication with the supplied PAT:
`remote: Invalid username or token`. Branch has **not** been published. The token is not in
source files or remote URLs. Replace/revoke the exposed credential through a secure channel.
A local branch and portable patch are retained; neither substitutes for a successful push.

## Acceptance matrix

| Contract | Evidence now | Remaining / status |
|---|---|---|
| District A sidewalk spawn; landmark visible; grounded first frame | Pure flat-footprint / clearance validator | BLOCKED: coordinates, landmark LOS, runtime spawn wiring and first-frame physics |
| >=1500-stud grid-square-forecourt-concourse route | Exact segment-boundary audit; synthetic route 1596 studs | BLOCKED: real route and destination semantics |
| Continuous crossings / driveways / dropped curbs | Regression rejects 1.21-stud step; permits 1.2 | BLOCKED: crossing inventory, actual ramps/slopes and curb geometry |
| Ground sealed everywhere | Exact rectangular-union coverage checker detects 0.01-stud hole | BLOCKED: actual world boxes/domain; roofs must not be used as ground |
| Performance budgets | Streaming configuration assembled by Rojo; static metrics below | BLOCKED: real generated part count and engine draw-call profile |
| Collision policy | Policy below and obstacle regression tests | BLOCKED: actual generator compliance |
| Station spawn / platform-to-city | Validator accepts second spawn field | BLOCKED: real station point, explicit platform-to-city route, teleport streaming |
| Route render | Reproducible SVG pipeline, explicit BLOCKED artifact | NO real route render possible until world export exists |

A green fixture suite is **not** acceptance of a walkable city. Even a green box geometry
result is not full acceptance: current centerline-only support, unverified semantic waypoints,
landmark visibility, unsupported ramps/meshes, runtime integration and engine tests remain.

## Precise defect / dependency handoff for WORLD · strata

| ID | Location | Failure | Required action |
|---|---|---|---|
| WALK-001 | `src/server/World` (absent) | `WORLD_DATA_UNAVAILABLE`; no auditable generated geometry | Publish pure runtime-source geometry export |
| WALK-002 | coordinates unavailable | District A sidewalk spawn, station spawn, square/forecourt/concourse/platform route cannot be located | Publish source-linked markers and ordered route >=1500 studs |
| WALK-003 | bounds unavailable | Cannot establish entire walkable coverage domain | Declare actual walkable bounds; do not exclude accidental holes |

There are **no invented coordinate defects**. No coordinate exists to quote until geometry is
available. On load, each finding contains code, x/z coordinates, a rectangle or interval in
studs, or source obstacle ID. Adapter details: `tools/walkaudit/README.md`.
No changes made in `src/server/World` or Manager-owned shared contracts.

## Verification / exact commands

Toolchain installed in `$HOME/bin` (not committed). Run from repository root with
`export PATH="$HOME/bin:$PATH"`.

| Command | Observed result |
|---|---|
| `lune run tests/walk/run.luau` | **10 passed, 0 failed**, synthetic fixtures only |
| `selene src/server/Walkability src/server/Spawn tests/walk tools/walkaudit` | **0 errors, 0 warnings, 0 parse errors** |
| `selene src/` | **0 errors, 0 warnings, 0 parse errors** at checkpoint |
| `stylua --check src/server/Walkability src/server/Spawn tests/walk tools/walkaudit` | exit 0 |
| `luau-lsp analyze --platform=standard src/server/Walkability/Audit.luau src/server/Spawn/Plan.luau tests/walk/run.luau` | exit 0, no diagnostics; tool warns no definitions file supplied |
| `rojo build default.project.json -o docs/reports/walkability-milestone.rbxlx` | success; place committed as assembly evidence only |
| `lune run tools/walkaudit/run.luau` | **fails intentionally**: missing World/Geometry module; BLOCKED JSON written |
| `python tools/walkaudit/measure.py` | writes static metrics below |
| `python tools/walkaudit/render.py` | writes `docs/reports/renders/walkability-route.svg` (BLOCKED, no invented route) |

`bash tools/walkaudit/verify.sh` combines checks and returns nonzero at city gate. Lune runner
has runtime validation at its dynamic boundary; luau-lsp checks the pure modules/spec, not
Lune-library bindings. No blanket claim that all repository tests or all code was analyzed.

## Performance budget / measurements

Source: `python tools/walkaudit/measure.py`, after the Rojo command above.

| Metric | Value | Meaning |
|---|---|---|
| Static Workspace BaseParts | **0** | Counted in assembled place; runtime city is absent. NOT a successful low part count. |
| Generated walkable parts | **unknown / null** | World export unavailable. Target **<25,000** for slice. |
| Estimated draw calls | **unavailable / null** | No geometry, material/mesh batches, camera or engine renderer. Do not equate parts with calls. Target **<1,000**. |
| Triangles | unmeasured | Architecture target <1,000,000 worst-case visible triangles. |
| Streaming min / target radius | **64 / 1024 studs** | Serialized configuration, not measured loaded extents. |
| Streaming behavior on movement | unverified | Must measure client residency, pauses and memory on real mobile hardware. |

Serialized Workspace settings: StreamingEnabled true; ModelStreamingBehavior Improved;
StreamingIntegrityMode PauseOutsideLoadedArea; StreamOutBehavior Opportunistic. Rojo build
success verifies property assembly, not runtime streaming. Keep architecture defaults rather
than unilaterally lowering target radius and compromising landmark views. For mobile,
recommend built-in materials, reused meshes, small spatially coherent models, collision
simplification and tight local detail budgets first. Test a baseline low-memory phone before
sign-off; require worst-case station/city camera draw calls, triangles, frame time and memory.
Never keep the whole city Persistent. Break geometry into local units; avoid attaching huge
city extents to a small moving prop/model. Teleports must request the destination stream,
handle timeout and verify local support before releasing movement; this is not yet wired.

## Collision design policy

* Ground, sidewalks, crossings, floors and simplified building massing: anchored collidable
  solids; no gaps, including underneath driveways/crossings. Do not rely on render-only mesh.
* Curbs: heights <=1.2 studs on pedestrian paths; dropped kerbs or accurately represented
  ramps at crossings. No continuous collidable curb fence across crossing openings.
* Canopies and street furniture: simplified, appropriately placed collisions, maintaining
  walking width and headroom; canopy support posts must be present in obstacle export.
* Decorative trim, lettering, tactile visual strips, tiny handles and foliage detail:
  noncollidable; no detailed render-mesh collision. Important obstacles may not be hidden
  through the `walk` flag: export all collidable solids independently of transparency.
* Enforce policy in generator; audit does not silently switch collision flags or add rescue
  slabs. Collision group changes and query flags need explicit engine-side review.

## Resource study / adopted facts

Read MASTER-DIRECTIVE world/performance sections, ARCHITECTURE, OWNERSHIP, STANDARDS and
RESOURCES before implementation. Specific facts from opened Creator documentation:

1. [Streaming techniques](https://create.roblox.com/docs/workspace/streaming/techniques)
   recommends MinRadius 64 to allow low-end scaling: retain 64, do not force a huge minimum.
2. Same page recommends TargetRadius 1024 as visibility/memory balance: preserve baseline.
3. Same page recommends PauseOutsideLoadedArea and Opportunistic stream-out: serialize both;
   never describe configured behavior as observed client behavior.
4. Same page recommends spatially/logically related model grouping and small extents: require
   local geometry units, not a single city-wide atomic model.
5. [Design for performance](https://create.roblox.com/docs/performance-optimization/design)
   says device emulation is not accurate memory testing: do not claim mobile viability from
   headless assembly or a desktop emulator.
6. Same page gives <1000 draw calls / <1M triangles as an example determined on a baseline
   device, not a universal automatic guarantee: real draw-call measurement stays unverified.
7. Same page says built-in materials use less memory than custom textures: prioritize material
   reuse and reserve custom texture memory for hero content.
8. [Improve performance](https://create.roblox.com/docs/performance-optimization/improve)
   warns about heavy work in high-frequency frame events: full audits stay offline; no
   Heartbeat loop added. Current seal algorithm is expensive and needs indexing for 25k parts.

## Next gates (not claims of elapsed milestones)

1. Publish this branch once working repository write access is available.
2. Consume strata's real data; implement an adapter for its actual schema without a parallel
   fake city; extend exact surface math for any true ramps/rotations.
3. Assign grounded District A spawn with verified landmark line of sight; integrate runtime
   spawn/stream handoff; add full-width route support and real station exit tests.
4. Run city audit, send coordinate defects to strata, rerun after their fixes. No rescue floors.
5. Render actual route and report actual parts; model draw-call estimate only with declared
   batching assumptions, then hand device/engine checks to Manager. Freeze only after evidence.
