# WALK · pave — real geometry audit checkpoint

**2026-11-01 / Manager A / NOT FROZEN / overall continuity gate RED**

## Latest publication-first checkpoint

Created branch **`walk/audit`** directly from the already committed patch work and attempted
push before further analysis, including an authenticated attempt using the supplied PAT.
GitHub returned **Invalid username or token**, exit 128. This is a write-access blocker,
not unpublished work by choice. No source token or credential is stored in the repository.

Added **OrientedAudit.luau**, a pure strict Luau kernel, and **check_world.luau**, which executes
the actual unmodified runtime builder in Lune, validates its exported data and asserts the
real route, full base seal and all 48 sidewalk axes. The Python audit remains independent;
`compare.py` proves the two implementations agree on parts, ground, route length, maximum
step and every sidewalk finding. A noncollidable intended surface now fails even if a
collidable base below it would prevent falling. Adapter guards reject unsupported part
classes and CFrame/PivotTo placement rather than silently using stale Position values.

Latest remote remains `329d358`. Command
`git diff --exit-code 8ae4bb0 origin/world/historic-core-blockout -- src/server/World`
returns **0**, confirming its World geometry matches the requested 8ae4bb0 exactly.

Concrete geometry categories, independently confirmed in Lune:

| Failure category | Actual findings |
|---|---:|
| Unsupported route/sidewalk intervals (including gaps >0.5 studs) | **0** |
| Steps >1.2 studs | **0** |
| Intended noncollidable walk surfaces | **0** |
| Ground-plane holes within declared rectangle | **0**, exact base-containment proof |
| Body-blocked sidewalk spans | **6 spans / 2 sidewalks**, WALK-004 below |

Regression evidence is now **18 Luau tests + 11 Python tests + 6 strata tests**, all passing.
The real-city acceptance command still returns **1**, correctly, for blocked sidewalks.
Lint/format and scoped analysis include the new pure Luau kernel and its tests. All analysis
is offline: no per-frame scan or training/player-model system was added to a phone client.

Commands for the requested measurements:
* `lune run tools/walkaudit/check_world.luau`: **1817 actual constructed parts**; route
  **1632.999280**; max route step **0.595001**; sealed base; 48 sidewalks, 2 blocked.
* `python tools/walkaudit/audit_world.py`: current 1024-stud sampled envelope peak **1813**;
  384-stud candidate peak **620**. Recommend **min=64 / target=384 as a mobile profiling
  candidate**, not as certified phone performance. Configuration remains 64/1024 until
  device/visibility validation, and measured draw calls remain unknown. Details below.

## Previous supervisor checkpoint (superseded by evidence above)

Integrated strata revision `329d358ca71f4fa4af2ae68e09d10f906d7db673` at
`7216be566410d5e5e9fe49af4c8b6c5fe35e699a` and reran the complete verification pipeline.
The new strata commit adds a builder-recipe part-count assertion, not geometry changes.
Results are unchanged: 1817 constructed parts, 1632.99928-stud route, 0.595001-stud maximum
route step, sealed 2,895,200-square-stud base, two blocked sidewalk axes and 291 facade
collision findings. Full audit still exits 1. Streaming envelopes are unchanged.
Fresh JSON evidence records the current integration/world revisions. Push retried but no
usable noninteractive write credentials are configured; the previously supplied token was
already rejected. No grading, motif, player-model or training-scheduler systems belong to
this assignment; none were modified.


Continued from the previous checkpoint; strata has now published geometry. Integrated
`origin/world/historic-core-blockout` at `8ae4bb0de7046af8882a48dbcf8d1ffeaa259315`
into `walk/audit` without changing any World-owned files. Audit evidence was generated
against integration commit `8736e3f2a71407cd7418f7c60aab20f902ea8031` plus the owned audit
changes in this checkpoint. An unrelated dirty asset file was left untouched.

## What is now verified headlessly

The unmodified **CityGenerator + CityConfig + CityBuilder** execute in Lune. The export
contains actual constructed parts, not a parallel geometry mock or an estimated formula.
Lune's Roblox data model supplies Instance and datatypes; it is **not the Roblox engine**.
No character physics, first-frame grounding, client streaming, mobile hardware or GPU
profiling is claimed. Builder placement uses explicit Position/Orientation at this revision;
Lune does not synchronize those properties with CFrame. See `tools/walkaudit/README.md`.

| Check | Result |
|---|---|
| Spawn → grid → square → forecourt → concourse | **1632.99928 studs**, 125 analytically partitioned intervals |
| Unsupported route footprint intervals | **0**, radius-1 support footprint, not just centerline |
| Route body blockers | **0**, conservative radius-1 / height-5 envelope |
| Maximum route step | **0.595001 studs**, below 1.2 |
| Ground sealing | **PROVEN across 2,895,200 square studs**, exact containment by actual closed base solid |
| Ground domain | x **[-770, 770]**, z **[-825, 1055]**, base top y=0 |
| Entire sidewalk axes | **48 checked**, including diagonal streets; **46 clear, 2 blocked** |
| Sidewalk gaps / steps >1.2 | **0 / 0**, largest sidewalk step **0.75** studs |
| Sidewalk body-block findings | **6 partitioned spans**, representing **2 distinct blocked sidewalks** |
| Actual generated BaseParts | **1817**, below 25,000 slice budget |
| District A spawn geometry | **clear**, x=136.75, z=-640, support top y=1.149994 |
| Station-concourse spawn geometry | **clear**, x=120, z=925, support top y=0.630005 |

Ground proof: the builder's actual anchored collidable `CollidableGround` block contains
all four corners of the declared rectangle, therefore every interior x/z coordinate. This
proves a sealed base, not that every upper floor is hole-free. Rotated horizontal support
rectangles use analytic clipping; no regular sampling grid substitutes for route continuity.
The route uses strata's generated link slabs; WALK did not add or alter any geometry.

## Precise defect handoff to WORLD · strata

### WALK-004 / two sidewalk axes intersect station rear wall — BLOCKER

Source wall:
`Workspace.CivitasWorld.City.DistrictA_HistoricCentreSlice.Stations.CentralStation_WalkablePlaceholder.StationRearWall`.
Actual solid footprint: **x=[42,198], z=[962.25,970.25], y=[0,19]**.

| Actual sidewalk source | Centre x | Tested blocked centreline z interval |
|---|---:|---|
| `Streets.Sidewalk_z_120_1` | 136.75 | **[961.25,969]** |
| `Streets.Sidewalk_z_120_-1` | 103.25 | **[961.25,969]** |

The wall collides with the radius-1 pedestrian envelope starting 1 stud before its physical
face. Source sidewalks continue to z=970; audit ends 1 stud before their endpoint. Six
reported spans are subdivisions of these two continuous conflicts, not six distinct walls.
Please resolve the sidewalk/station layout deliberately; WALK has not cut the wall, rerouted
the street or added a rescue slab. Full spans and IDs: `walkability-live-results.json`.
The contracted spawn-to-concourse route stops at z=925 and is clear; this broader sidewalk
check is why the overall gate remains red.

### WALK-005 / decorative collision policy — 291 findings

57 each: `DisplayWindow_Left`, `DisplayWindow_Right`, `RecessedShopDoor`.
60 each: `EntryLintel`, `RecessedDoor`. All are constructed with CanCollide=true by the
shared builder helper despite being facade details over solid massing.

Example: `Block 64 Plot 3-2.DisplayWindow_Right` centre **(578.57666, 5.800003, 552.474976)**,
size **(9.520004,4,0.350006)** studs. Exact full source IDs, xyz and dimensions for all 291
findings are in **`docs/reports/walkability-collision-defects.csv`**. This list does not claim
these details currently block the acceptance route; it identifies policy noncompliance.
Please disable decorative collision in the owning generator, keeping building massing,
canopies and meaningful street furniture collision. No silent patch was made.

### WALK-006 / platform-to-city promise — missing station interface

The actual station is explicitly named `CentralStation_WalkablePlaceholder`; no platform
geometry or platform marker is present in the generated city. The station-concourse spawn
point can be validated, but must not be called a platform teleport test. Platform handoff,
real teleport/stream readiness, landmark line of sight and first-frame character grounding
remain unverified. The existing sidewalk spawn is created by strata's builder, not WALK.

## Performance / streaming numbers

Commands: `lune run tools/walkaudit/export_world.luau`, then
`python tools/walkaudit/audit_world.py` and `python tools/walkaudit/measure.py`.

* **1817 actual generated BaseParts**. Static Rojo Workspace count is 0 because the city
  is built at runtime; do not confuse the two. Generator's current estimate also equals 1817.
* Serialized settings remain **StreamingEnabled=true, MinRadius=64, TargetRadius=1024**,
  **Improved / PauseOutsideLoadedArea / Opportunistic**. Rojo assembles these properties.
* The following counts are geometric footprint/radius intersections at **114 route
  positions**, maximum **16-stud spacing**. They are sampled residency envelopes, not
  observed stream-in/out, memory usage or guaranteed continuous maxima.

| Radius (studs) | Minimum intersecting parts | Maximum at sampled positions |
|---:|---:|---:|
| 64 | 7 | 38 |
| 256 | 27 | 315 |
| 384 | 82 | 620 |
| 512 | 212 | 998 |
| 1024 | 1023 | 1813 |

**Estimated unbatched main-pass submissions: 1813** at the configured target envelope,
assuming one submission per intersecting part, no batching and no culling. This conservative
risk proxy exceeds the 1000-call target, but is **not measured engine draw calls** and is not
an upper bound on all GPU passes. Batching/occlusion reduce calls; shadows/multipass rendering
can add calls. Measured draw calls and triangles remain unknown, not zero.

Mobile recommendation: test a **384-stud target-radius candidate** (620-part sampled peak),
keeping min=64 and the integrity/stream-out settings, before approving it for production.
512 already reaches 998 without characters or trains and leaves negligible headroom. Do not
claim the 384 candidate meets the draw-call budget until profiling a baseline low-memory
phone; also check landmark visibility and pause behavior. Current architecture-default
1024 is retained in committed config pending this validation. Use built-in materials,
reused mesh batches and small spatially coherent models; do not make the entire city
Persistent. No full-city per-frame scanning is introduced.

## Collision design policy

Ground, pavements, floors and simplified massing stay anchored and collidable. Crossings
need continuous support and dropped kerbs/ramps, with no curb fence; permitted path step
maximum is 1.2 studs. Canopies, posts and street furniture get simplified collision with
walking clearance. Decorative lettering, facade detail, windows, tiny handles and visual
strips do not get render-detail collision. Current 291 facade findings need strata's fix.
Cylinder obstacles are conservatively bounded; cylinders do not prove support. Unsupported
shapes/tilted surfaces fail rather than being silently treated as walkable boxes.

## Evidence / commands

Run **`bash tools/walkaudit/verify.sh`**. Current expected exit is **1** for the two blocked
sidewalks; earlier missing-World blocker is superseded. Full output: `tools/walkaudit/evidence.log`.

| Command | Observed result |
|---|---|
| `selene src/server/Walkability src/server/Spawn tests/walk tools/walkaudit` | 0 errors, 0 warnings, 0 parse errors |
| `stylua --check src/server/Walkability src/server/Spawn tests/walk tools/walkaudit` | exit 0 |
| `luau-lsp analyze --platform=standard src/server/Walkability/Audit.luau src/server/Spawn/Plan.luau tests/walk/run.luau src/server/Walkability/OrientedAudit.luau tests/walk/oriented.luau` | exit 0, no diagnostics; warns no definitions file supplied |
| `lune run tests/walk/run.luau` | 10 passed, 0 failed |
| `lune run tests/walk/oriented.luau` | 8 passed, 0 failed |
| `lune run tools/walkaudit/check_world.luau` | asserts actual builder output in Lune; exits 1 for two blocked sidewalks |
| `python tools/walkaudit/compare.py` | independent Lune/Python parity PASS |
| `python tests/walk/test_world_audit.py` | 11 passed |
| `lune run tools/world/test_city.luau` | 6 passed, 0 failed (strata's tests; not full acceptance) |
| `rojo build default.project.json -o docs/reports/walkability-milestone.rbxlx` | success |
| `lune run tools/walkaudit/export_world.luau` | actual builder: 1817 BaseParts, 1633.00 route studs |
| `python tools/walkaudit/audit_world.py` | acceptance route clear; 48 sidewalk axes checked; 2 blocked; exit 1 |
| `python tools/walkaudit/measure.py` | counts and configured streaming properties recorded |
| `python tools/walkaudit/render_world.py` | real top-down footprints and gold route; red blocked sidewalk locations |

**Render:** `docs/reports/renders/walkability-route.svg` — now real city geometry, replacing
the earlier BLOCKED card. The place file is assembly evidence, not a city simulation.
Lune-library bindings are runtime-validated/executed; scoped luau-lsp claim covers pure
modules/specs only. No whole-project clean-analysis or engine acceptance claim.

## Publication / remaining gates

Initial push failed: supplied PAT rejected by GitHub. New checkpoint push is attempted at
session end; no successful publication should be inferred from a local commit. The exposed
PAT should be revoked and replaced securely. Portable patch remains available if push fails.

Next: strata resolves WALK-004/005; rerun the same commands and render. Station/platform
integration, real spawn/teleport streaming, landmark visibility and mobile profiling remain
separate gates. No freeze until those gaps are explicitly resolved or accepted by Manager A.

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

