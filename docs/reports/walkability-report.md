# WALK · pave — manual-sweep sidewalk repair

**2026-11-02 · branch `walk/audit` · GEOMETRY CONTINUITY PASS · NOT FROZEN**

## Preserved checkpoint and cleanup

Before editing geometry, recovered the committed 7a12330 history and ran the exact requested
range: `git bundle create /home/user/walk-audit-7a12330.bundle origin/main..walk/audit`.
**Verified path: `/home/user/walk-audit-7a12330.bundle`; size: 995,099 bytes.** This preserves
the original checkpoint unchanged. Git bundle verification succeeds. The fixed branch is
also packaged separately as `/home/user/walk-audit-sidewalk-fix.bundle`.

Deleted the stale `/home/user/walk-audit.bundle` only after verifying its replacement.
No `install*.log` or `*.bak` files existed outside Git metadata at cleanup. Reinstallable
executables accounted for **68,617,912 bytes** in the saved workspace; moved them to excluded
`~/.cache/civitas/toolchain` and retained only symlinks in `~/bin`. The committed
`bootstrap_tools.py` reinstalls exact, SHA-256-pinned releases if that excluded cache is lost.
The missing-cache installation path was tested with Selene. No user asset was deleted or
changed; the unrelated dirty Blender installer remains outside WALK commits.

No token was used or pasted during this manual sweep. Bundle delivery is used instead of
retrying rejected authentication. Git metadata may be restored from the preserved bundles.

## Authorized local geometry repair — WALK-004 resolved

The Director assistant explicitly requested this local World fix, overriding the original
read-only handoff for this narrow repair. Base World revision: **329d358**, whose source
matches **8ae4bb0** before this change. The local branch now intentionally differs from it.

The former monolithic StationRearWall blocked x=**103.25 / 136.75**, tested z=**961.25–969**.
Replaced it with **three full-height collidable wall piers and two collidable headers**,
creating real rear pedestrian doorways through the existing facade:

| Door centre x | Clear x interval | Clear y interval | Wall-depth z interval |
|---:|---|---|---|
| **103.25** | **[99.75,106.75]** | **[0,8]** | **[962.25,970.25]** |
| **136.75** | **[133.25,140.25]** | **[0,8]** | **[962.25,970.25]** |

Each opening is **7 studs wide / 8 studs high**. Above concourse top y=0.630005 the headroom
is **7.369995 studs**, exceeding the 5-stud audit body. Piers remain y=[0,19]; headers
remain y=[8,19]. All five facade parts remain anchored and collidable. No collision was
silently disabled, no base slab/domain was changed, and no rescue surface was added.

Scoped edits: CityConfig exit offsets/width/height, CityBuilder piers/headers, CityGenerator
part-recipe count, and the associated existing generator test assertions. The actual builder
export now asserts that generated count equals the recipe estimate. The pure geometry audit
kernels and their thresholds/exclusions were not weakened to obtain a pass.

## Rerun results

Same actual CityGenerator + CityConfig + CityBuilder executed under Lune. Independent Python
clipping agrees with Lune. This is headless geometry evidence, **not Roblox engine testing**.

| Check | Result after fix |
|---|---|
| Actual BaseParts / generator estimate | **1821 / 1821**, +4 for real wall segmentation |
| Main route length | **1632.999280 studs** |
| Route geometry defects | **0** |
| Entire sidewalk axes | **48 checked, 48 clear, 0 blocked** |
| Grid crossing axes | **162 at 81 intersections, all clear** |
| Gaps, including gaps >0.5 studs | **0** |
| Steps >1.2 studs | **0** |
| Intended noncollidable walk surfaces | **0** |
| Max route / sidewalk / crossing step | **0.595001 / 0.75 / 0.254997 studs** |
| Ground base sealing | **2,895,200 studs²**, exact closed-solid containment proof |
| Ground domain | x=[-770,770], z=[-825,1055], base top y=0 |

`walkability-geometry-defects.csv` is now **header-only**; no finding was suppressed. The
original six spans remain preserved in the original 7a12330 bundle. The top-down route
render is regenerated from actual repaired parts; the rear facade gaps are visible.

## Tests and exact commands

* **All 53 regression tests pass:** 18 Luau + 11 Python geometry + 9 streaming + 9 sightline
  + 6 strata generator tests. Existing generator assertions now verify the exit alignment,
  opening dimensions and adjusted recipe; the test count was not replaced or reduced.
* `lune run tools/walkaudit/check_world.luau` → **exit 0**, parts=1821, sidewalks=48,
  blocked=0, sealed=true, main route defects=0, crossings=162, blocked=0.
* `python tools/walkaudit/audit_world.py` → **exit 0**, GEOMETRY_CHECKS_PASS.
* `python tools/walkaudit/compare.py` → independent parity PASS across all geometry checks.
* `selene src/server/World tools/world/test_city.luau` → 0 errors, 0 warnings; owned WALK
  paths also clean. StyLua checks pass for both sets.
* `luau-lsp analyze --platform=roblox --definitions @roblox=$HOME/.cache/civitas/globalTypes.d.luau
  --sourcemap $HOME/.cache/civitas/sourcemap.json src/server/World/*.luau` → exit 0, no
  diagnostics; real Roblox API definitions and Rojo sourcemap used. Scoped pure WALK
  analysis also passes. Informational watcher/definitions warnings are not diagnostics.
* `rojo build default.project.json -o docs/reports/walkability-milestone.rbxlx` → success.
* `lune run tools/world/export_plan.luau` → refreshed plan, 1821 estimated parts.
* **`bash tools/walkaudit/verify.sh` still exits 1**, solely because the current spawn's
  separately documented tested-landmark-anchor gate remains red. The two geometry
  commands above now pass. Full output: `tools/walkaudit/evidence.log`.

## Streaming and mobile numbers

Command: **`python tools/walkaudit/streaming.py`**. Continuous analytic rounded-footprint
interval sweep over the whole route, not a sampled maximum. Cylinder bounds remain
conservative. This is not actual stream residency, retained models, memory or GPU profiling.

| Radius | Continuous min parts | Continuous peak parts |
|---:|---:|---:|
| 64 | 7 | **38** |
| 256 | 31 | **317** |
| 384 | 86 | **621** |
| 512 | 216 | **1005** |
| 1024 | 1027 | **1818** |

The two real doorways add four parts. At configured 1024 the peak increases from 1814 to
**1818**, while the mobile candidate peak remains **621 at 384**. Recommend profiling
**min 64 / target 384** with Improved, PauseOutsideLoadedArea and Opportunistic stream-out.
Current serialized settings remain **64/1024** pending device/visibility validation.

One-submission-per-part main-pass proxy is 1818 at 1024 or 621 at 384. These are estimates,
not measured draw calls or an upper bound on total GPU passes; batching/culling may reduce
calls, shadows/multipass rendering may increase them, and streaming may retain parts beyond
target radius. 512 already reaches 1005 before characters/trains. Baseline-phone frame time,
memory, landmark view and streaming pause tests are still required. Triangles remain unknown.
Static Rojo Workspace parts are 0 because the city is generated at runtime, not because the
city has no parts. Full audits remain offline; no per-frame client scan was introduced.

## Remaining gates, deliberately not patched in this task

* **WALK-005:** 291 collidable facade-detail policy findings remain in the collision CSV.
* **WALK-007:** actual spawn (136.75,-640) has **0/17 clear tested anchor rays**, using an
  assumed eye offset of 4.5 studs. This does not prove every landmark pixel is hidden and
  is not a camera test. Full target/blocker/hit coordinates remain in sightline CSV/JSON.
* Unapplied candidate (136.75,-512) retains **1504.999280 route studs**, clear geometry and
  two clear Civic Archive Tower anchor rays. No live SpawnLocation was moved.
* **WALK-006:** the placeholder station lacks a platform; platform exit, first-frame rig
  grounding, landmark camera framing, streamed teleport and mobile hardware are unverified.
* Publication authentication remains unresolved; this sweep delivers verified Git bundles.

## Collision policy

Ground/pavements/floors and simplified massing stay collidable. Real openings or dropped
kerbs provide access; audit flags are not a substitute. Canopies/posts/furniture use simple
collision with body clearance. Decorative trim/windows/lettering do not need detail-mesh
collision. Do not hide transparent obstacles or repair ground gaps with silent rescue slabs.
Keep built-in materials, reused meshes and spatially local streaming units; no city-wide
Persistent model or full-city per-frame scans.

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

