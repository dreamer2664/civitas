# WALK · pave — walkability and performance evidence

**2026-11-01 · branch `walk/audit` · NOT FROZEN · overall geometry gate RED**

## Current checkpoint

Continued the existing audit; no restart or substitute city. First-action push was attempted
and failed because no usable noninteractive GitHub authentication is configured. The
previously supplied PAT was explicitly rejected (`Invalid username or token`, exit 128).
No publication is claimed. Working repository write authentication is required to publish.
Portable patch and verified Git bundle are retained; see `tools/walkaudit/PUBLISH.md`.

Fetched World revision: **329d358ca71f4fa4af2ae68e09d10f906d7db673**.
`git diff --exit-code 8ae4bb0 origin/world/historic-core-blockout -- src/server/World`
returns **0**: World geometry is unchanged from the requested **8ae4bb0**, with 302 ordinary
buildings, 12 landmarks and 64 irregular blocks. No World-owned geometry was edited.

**New this checkpoint:** recovered the existing committed history from the verified bundle
rather than rebuilding it, reran the complete real-world audit, and added conservative 3D
landmark-anchor sightline checks. The current spawn has **0 clear anchors out of 17 tested
across 12 landmarks** at an explicitly assumed 4.5-stud eye offset. This does not prove every
landmark pixel is hidden or simulate the engine camera; exact target/blocker/hit coordinates
are now recorded. A verified alternative spawn plan is documented below, not applied.

The previous checkpoint's continuous streaming sweep remains unchanged: 384-radius peak
621, 512 peak 1005, 1024 peak 1814. Nine regression tests cover that algorithm.

## Headless geometry results

`lune run tools/walkaudit/check_world.luau` executes the same unmodified CityGenerator,
CityConfig and CityBuilder used by the server, using Lune's Instance/datatype implementation.
Strict pure Luau geometry checks then assert over the actual constructed parts. Independent
Python checks agree on geometry and all sidewalk/crossing findings.

| Check | Result |
|---|---|
| Actual constructed BaseParts | **1817**, below 25,000 slice budget |
| Spawn → grid → square → forecourt → concourse route | **1632.999280 studs**, 125 partitioned intervals |
| Unsupported route/sidewalk/crossing intervals, including gaps >0.5 | **0** |
| Steps >1.2 studs | **0** |
| Intended noncollidable walk surfaces | **0** |
| Maximum route / sidewalk / crossing step | **0.595001 / 0.75 / 0.254997 studs** |
| Entire sidewalk long axes | **48 checked**, 46 clear, **2 body-blocked** |
| Grid crossings | **162 axes at 81 intersections**, all clear |
| Sealed ground base | **2,895,200 studs²**, exact containment proof |
| Ground domain | x **[-770,770]**, z **[-825,1055]**, top y=0 |
| District A spawn geometry | clear at **(136.75,-640)**, support top y=1.149994 |
| Station-concourse spawn geometry | clear at **(120,925)**, support top y=0.630005 |

Seal proof uses the actual closed collidable anchored `CollidableGround` box containing
all domain corners, therefore every interior x/z coordinate; it is not a grid of samples.
It does not prove every possible upper floor is hole-free. Analytic yawed-box clipping
requires a radius-1 supported footprint and a conservative radius-1, height-5 body envelope.
Unknown shapes/tilts fail. Cylinder obstacles are conservatively boxed, never used to prove
support. All actual sidewalk long axes are checked with 1-stud endpoint insets. Both axes
across every declared grid intersection are tested. No separate driveway inventory exists,
so semantic coverage of every driveway is not invented.

Lune does not simulate physics or automatically synchronize Position/Orientation/CFrame.
This builder uses explicit Position/Orientation; the exporter rejects unsupported part
classes or CFrame/PivotTo placement changes instead of silently fabricating proof.

## Coordinate defect handoff to WORLD · strata

### WALK-004 — station rear wall blocks two sidewalks (acceptance blocker)

Actual wall source:
`Workspace.CivitasWorld.City.DistrictA_HistoricCentreSlice.Stations.CentralStation_WalkablePlaceholder.StationRearWall`.
Solid footprint **x=[42,198], z=[962.25,970.25], y=[0,19]**.

| Sidewalk source suffix | Centre x | Blocked tested centreline z |
|---|---:|---|
| `Streets.Sidewalk_z_120_1` | **136.75** | **[961.25,969]** |
| `Streets.Sidewalk_z_120_-1` | **103.25** | **[961.25,969]** |

The pedestrian envelope collides 1 stud before the wall. The actual sidewalks extend to
z=970; the test ends 1 stud before their endpoint. There are six partitioned findings for
these two continuous conflicts, not six different walls. **Every span, coordinate, source
path and blocker ID is in `docs/reports/walkability-geometry-defects.csv`** and both result
JSONs. The gold acceptance route ends at concourse z=925 and is clear, but the broader
sidewalk acceptance gate correctly fails. Resolve layout in the owning generator; WALK has
not cut the wall, removed collision, rerouted the street or added a rescue floor.

No gap, over-limit step or ground-hole coordinates are fabricated: none were detected.

### WALK-005 — 291 decorative collision policy findings

57 each `DisplayWindow_Left`, `DisplayWindow_Right`, `RecessedShopDoor`; 60 each
`EntryLintel`, `RecessedDoor`. All have CanCollide=true over solid building massing.
Example: `Block 64 Plot 3-2.DisplayWindow_Right`, centre
**(578.576660,5.800003,552.474976)**, size **(9.520004,4,0.350006)** studs.
All exact source IDs, xyz and sizes: **`walkability-collision-defects.csv`**. These are policy
findings, not a claim they block the acceptance route. Strata must resolve collision flags.

### WALK-006 — station/platform and runtime checks missing

The actual station is `CentralStation_WalkablePlaceholder`; no platform or platform marker
exists in this city export. A clear station-concourse spawn check is not a platform-to-city
teleport test. Platform integration, streamed teleport readiness, landmark sight line and
first-frame grounded character physics remain unverified. No Studio/account/device test
was performed or claimed. The sidewalk SpawnLocation comes from strata's builder.

### WALK-007 — current spawn landmark-anchor rays occluded; alternative verified

At actual spawn **(136.75,-640)**, assumed eye **(136.75,5.649994,-640)**, all **17 tested
Crown/Lantern anchors across 12 actual landmarks** are blocked by constructed opaque massing.
Example: ray to Old Town Clock Tower Lantern target **(-570,130.8,-375)** first hits
`BuildingMassing.Block 25 Plot 3-1.UpperMassing` at
**(-74.250008,43.013492,-560.884327)**. Every target, first blocker and 3D hit point is in
**walkability-spawn-sightlines.csv/json**. Shapes/partial transparency are conservatively
boxed/opaque; an occluded anchor set is not a proof of total landmark invisibility. Rig eye
height, camera framing/FOV and the first-frame player view remain unverified.

Chosen alternative: **(136.75,-512)**, on the same actual District A sidewalk and route slab.
The pure **src/server/Spawn/RecommendedPlan.luau** records it and the Civic Archive Tower
bearing. Lune proves its full-footprint route has **1504.999280 studs and zero defects**.
At the geometry-supported eye point there are **two clear Crown/Lantern anchor rays** to
Civic Archive Tower. Actual support top is 0.554993 studs. All checks use existing parts;
no rescue paving, massing changes or spawn movement was performed. The alternative is
**not applied at runtime**, and is not presented as a successful engine spawn. Its route
proof and complete ray results are in **walkability-spawn-candidate.json**. The map marks
this unapplied point cyan; gold remains the actual original audit route.

Command: `python tools/walkaudit/sightlines.py` after the Lune check. It deliberately exits
1 for the current spawn's failed tested-anchor gate while recording the clear candidate.

## Streaming / mobile recommendation — corrected continuous maxima

Commands producing part count and geometry:
`lune run tools/walkaudit/check_world.luau` → **1817 constructed BaseParts**.

Commands producing the following numbers:
`python tools/walkaudit/streaming.py` and `python tools/walkaudit/audit_world.py`.

Each yawed rectangular bounding footprint is dilated by a disk of the chosen radius. Its
route intersection is solved analytically using two rectangular strips plus four corner
disks; per-part entry/exit events are swept along every segment. Contacts count. These are
**continuous bounding-footprint envelopes**, with cylinder bounds conservative. They are
not engine residency, retained streaming models, GPU calls or memory measurements.

| Radius | Min parts | Continuous peak | Former sampled peak | Peak player x,z |
|---:|---:|---:|---:|---|
| 64 | 7 | **38** | 38 | 136.75, -156.377685 |
| 256 | 27 | **317** | 315 | 198.639589, 73.503548 |
| 384 | 82 | **621** | 620 | 136.75, 12.453607 |
| 512 | 212 | **1005** | 998 | 136.75, 138.287866 |
| 1024 | 1023 | **1814** | 1813 | 136.75, -21.765634 |

Serialized configuration remains **min 64 / target 1024**, StreamingEnabled=true,
ModelStreamingBehavior=Improved, StreamingIntegrityMode=PauseOutsideLoadedArea,
StreamOutBehavior=Opportunistic. Rojo assembles these settings. Actual movement-related
stream-in/out, retention, pause duration and client memory remain unmeasured. A part/model
can remain resident beyond the target radius: the envelope is not a runtime residency cap.

**Mobile recommendation: profile min 64 / target 384**, with the existing integrity and
stream-out settings. Its 621-part envelope leaves substantially more headroom than 512,
whose continuous peak is now **1005**, already over the 1000-submission target under a
one-submission-per-part main-pass proxy before adding characters or trains. At configured
1024 the same proxy is **1814**. These are **estimates, not measured draw calls or an upper
bound on all GPU passes**: batching/occlusion reduce calls; shadows/multipass rendering may
increase them. Actual draw calls and triangles stay unknown. Validate the 384 candidate's
landmark visibility, stream pauses and low-memory phone frame time before adopting it.
Architecture-default 1024 remains committed pending device validation.

Static Rojo Workspace BaseParts = **0**, because the city is generated at runtime. This is
not the city part count and is not a low-performance-cost claim. Source content SHA-256
hashes in `walkability-metrics.json` pin the exact audited code even when evidence precedes
its final commit. Full audits and envelope analysis remain offline; no per-frame phone
client scans, player-model or training scheduler was added.

## Collision policy

Ground, sidewalks, crossings, floors and simplified building massing: anchored collidable
solids. Crossings require continuous support and dropped kerbs/ramps, no curb fence; path
steps must stay <=1.2 studs. Canopies, support posts and meaningful street furniture get
simplified collision with clear walking space/headroom. Decorative trim, windows, lettering,
handles and visual strips do not get render-detail collision. No audit silently changes
CanCollide, ignores transparent obstacles or repairs geometry. Use built-in materials,
reused meshes and local spatially coherent models; never make the entire city Persistent.

## Verification and artifacts

Run **`bash tools/walkaudit/verify.sh`**. Current expected exit **1**: two blocked sidewalks and the current spawn tested-anchor gate.
Full command output is committed at `tools/walkaudit/evidence.log`.

* Selene owned Luau paths: **0 errors, 0 warnings, 0 parse errors**.
* StyLua owned Luau paths: exit 0.
* Scoped luau-lsp standard analysis: both pure audit kernels, spawn validator and specs;
  exit 0, no diagnostics, warning that no definitions file was supplied. Lune bindings are
  runtime-executed/validated; no blanket whole-project static-analysis claim.
* **18 Luau + 11 Python geometry + 9 Python streaming + 9 Python sightline + 6 strata = 53 regression tests pass**.
* `rojo build default.project.json -o docs/reports/walkability-milestone.rbxlx`: success;
  assembly evidence only, not engine execution.
* `lune run tools/walkaudit/check_world.luau`: actual geometry assertions; fails on sidewalks.
* `python tools/walkaudit/audit_world.py`: independent geometry + sampled/continuous metrics.
* `python tools/walkaudit/compare.py`: Lune/Python parity on geometry, all 48 sidewalks and
  162 crossings; direct streaming report and integrated audit envelopes agree.
* `python tools/walkaudit/sightlines.py`: actual-spawn and unapplied-candidate anchor rays,
  using an assumed eye offset; current spawn fails.
* `python tools/walkaudit/measure.py`: configured streaming, static/actual counts, code hashes.
* `python tools/walkaudit/render_world.py`: real footprint map, gold route, red blocked axes,
  crossing summary and corrected 384-radius envelope peak.

Main visual: **`docs/reports/renders/walkability-route.svg`**. Results:
`walkability-lune-results.json`, `walkability-live-results.json`, `walkability-results.json`,
`walkability-streaming-exact.json`, `walkability-metrics.json`, `walkability-spawn-candidate.json`,
`walkability-spawn-sightlines.json` and coordinate CSVs.

**Remaining blockers:** working push authentication; strata's WALK-004/005 resolutions;
platform/station integration and engine/device acceptance. Freeze is not claimed.

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

