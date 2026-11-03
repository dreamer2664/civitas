# WALK · pave — latest strata integration audit

**2026-11-03 · `walk/fixes` · GEOMETRY CONTINUITY PASS · overall slice NOT FROZEN**

## Publication and provenance

Rebased WALK history onto `main` **ce23e4d**, preserving both upstream pocket squares
and WALK's station rear exits/count recipe. Published `walk/audit` is left intact. No HUD
conflicts occurred; lumen's `src/client` matches main exactly. PARKS (b0d542b) and handoff
(0ffb8e6) are closed; new changes are isolated to crossing, width, and curb-return commits.

A new exact curb-opening gate reproduced **104 failing pieces / 428 prior curb pieces**.
Clamping both gap endpoints to each clipped street run removes those overshooting solids:
**324 curb pieces, zero opening violations; 1820 actual/estimated parts**. Pocket squares,
station exits, all 302 ordinary buildings and 12 landmarks are retained. See
`audit/WALK-FIXES.md`, `audit/curb-return-before.json` and the current street-fixes JSON.

## Real geometry audit results

The same unmodified runtime construction loops in CityGenerator/CityBuilder execute under
Lune's Roblox data model. Pure strict Luau and independent Python geometry checks agree.
No Roblox engine, physics, mobile hardware or camera execution is claimed.

| Metric | Current result |
|---|---|
| Actual BaseParts / estimated recipe | **1820 / 1820** |
| Spawn → grid → public square → forecourt → concourse | **1632.999280 studs** |
| Route geometry defects | **0** |
| All constructed sidewalk pieces | **70 checked, 70 clear** |
| Declared grid crossing axes | **162 checked, 162 clear** |
| Unsupported intervals, including gaps >0.5 studs | **0** |
| Steps >1.2 studs | **0** |
| Intended noncollidable walk surfaces | **0** |
| Maximum route / sidewalk / crossing step | **0.595001 / 0.75 / 0.399994 studs** |
| Sealed base area | **2,895,200 studs²** |
| Ground domain | x=[-770,770], z=[-825,1055], base top y=0 |

Ground sealing is exact containment by the actual closed collidable base solid, not a
sampling grid. It does not assert every possible upper floor is hole-free. Route support
uses a radius-1 footprint and conservative radius-1 / height-5 body envelope. Unsupported
shapes/tilts fail; cylinders are conservatively boxed as obstacles, never support witnesses.
No separate driveway inventory exists, so semantic coverage of every driveway is not invented.

**No gap, over-limit step or ground-hole coordinates exist to report.** The complete
coordinate finding CSV is header-only, not suppressed. Actual constructed parts, geometry
and every sidewalk/crossing result are committed in the world/result JSONs.

### Split-street export identity correction

The new clipped streets reuse instance names: the 1820 parts contain **71 duplicate full
paths**. The old parity comparison incorrectly conflated distinct sidewalk pieces under
one dictionary key. The exporter now keeps `sourcePath` and `sourceIndex`, and adds an
export-local `@pieceN` suffix only where needed. IDs are asserted unique for all constructed
parts. No coordinates, collision flags or audit thresholds were changed. The independent
audits now agree on every one of the 70 distinct pieces. Render summaries use actual counts
and step results instead of stale constants.

## Previously blocked sidewalks remain fixed — WALK-004 resolved

Retained the manual-sweep-authorized real openings through the station rear facade:

| Centre x | Clear x | Clear y | Wall depth z |
|---:|---|---|---|
| **103.25** | [99.75,106.75] | [0,8] | [962.25,970.25] |
| **136.75** | [133.25,140.25] | [0,8] | [962.25,970.25] |

Three wall piers and two headers remain anchored/collidable. Each doorway is 7 studs wide,
8 high, with 7.369995 studs of headroom above the concourse. No collision disabling, ground
repair slab, domain shrink or audit exclusion was used. Former conflicts at x=103.25/136.75,
z=961.25–969 remain absent in the new 70-piece audit.

## Part count, streaming and mobile recommendation

Commands:
* `lune run tools/walkaudit/check_world.luau` → **1820 actual parts**, 70 sidewalks clear.
* `python tools/walkaudit/streaming.py` → continuous bounding-footprint envelopes below.
* `python tools/walkaudit/audit_world.py` → independent geometry and integrated same envelopes.

| Radius | Continuous minimum | Continuous peak |
|---:|---:|---:|
| 64 | 7 | **38** |
| 256 | 31 | **312** |
| 384 | 86 | **611** |
| 512 | 216 | **999** |
| 1024 | 1024 | **1817** |

The analytic rounded-rectangle entry/exit sweep spans the whole route and includes closed
contacts; no 16-stud sampling is used to claim a maximum. Cylinder footprints remain
conservative. These are not observed stream residency, retained models or GPU draw calls.

**Recommend profiling min 64 / target 384**, whose continuous envelope is now 611 parts
(down from 650). 512 reaches 999 before characters/trains under a one-main-pass-submission-
per-part proxy. At configured 1024 the same proxy is 1817. These are estimates, not an upper
bound on total GPU passes: batching/culling reduce calls; shadows/multipass work may add them.
Streaming can retain models beyond the target radius. Actual phone memory, frame time,
draw calls, triangles and pause behavior remain unmeasured.

Committed architecture defaults remain **StreamingEnabled=true, 64/1024, Improved,
PauseOutsideLoadedArea, Opportunistic** pending device/visibility validation. Static Rojo
Workspace BaseParts are 0 because geometry is generated at runtime; that is not the city
count. No full-city per-frame scan or other phone-client analysis was introduced.

## New street acceptance checks

In addition to the original 162 axes: **324 sidewalk-aligned crossings clear**, **70/70
physical sidewalk widths pass at 3.5 studs**, with three swept lanes per slab, and **324/324
curb-return pieces preserve their promised openings**. This certifies the exported geometry,
not engine navigation or two-avatar passing. No paving was invented to satisfy a test.

## Verification

`bash tools/verify.sh` also **passes in full** after rebase: main/client formatting, lints,
strict analyses, 122 main tests, 23 rail tests, seven city tests, export and Rojo build.
Evidence: `tools/walkaudit/main-rebase-verify.log`.

Run `bash tools/walkaudit/verify.sh`. All **73 regression tests pass**: 18 original Luau + 9 street regressions + 11 Python
geometry + 9 streaming + 9 sightline + **10 full-parcel grade/coverage tests** + **7 upstream generator tests** (one added by strata).
The full pipeline still returns **1** for the separate current-spawn tested-anchor gate.

* Direct Lune real-world geometry check: **exit 0**, 1820 parts, 70 sidewalks clear, sealed
  base, 162 crossings clear. Independent Python geometry command: **exit 0**.
* `compare.py`: Lune/Python parity PASS on actual parts, seal, route, steps, all sidewalks
  and crossings; streaming report and integrated audit agree.
* Selene: owned WALK paths and World/generator tests **0 errors, 0 warnings**.
* StyLua: owned WALK and changed World files pass.
* Scoped pure luau-lsp analysis passes. World analysis with real Roblox API definitions
  and a Rojo sourcemap passes, no diagnostics; only an informational watcher warning.
* `rojo build default.project.json -o docs/reports/walkability-milestone.rbxlx`: success.
* Source SHA-256 manifest in metrics pins the exact audited source despite evidence being
  generated just before its final commit.

Full evidence: `tools/walkaudit/evidence.log`, `world-static.log`, result JSONs and
`docs/reports/renders/walkability-route.svg` (actual geometry and gold route).

## Full-superblock PARKS audit and meanGrade

The final coverage certificate compares every named superblock and its exact source cell
set against `config.blocks.superblocks`: **4 expected / 4 audited**, missing=[], unexpected=[],
membershipMatches=true. All **64 original cells** are covered exactly once across 50 parcels.
Two added negative tests reject omitted superblocks and incorrect membership. Ranked merge
follow-ups are documented in `audit/STRATA-TOP3.md` for strata's already-merged PR #5.

Command: `python tools/walkaudit/parks.py` after the real Lune export. Artifact:
**audit/PARKS.json**, with SHA-256 of the actual exported geometry. All **50 parcels / 64
source grid cells** are covered exactly once; this includes every one of the four
superblocks and three actual public squares. Domains are grid-centreline cell unions,
including former road corridors; missing L-shape cells are not filled by a bounding box.
No semantic park inventory exists, so the requested filename does not invent parks.

**meanGrade means physical surface slope percent, NOT a quality score.** Every intersecting
certified support face is horizontal, proving meanGrade=0 regardless of area overlap.
Steps remain separate; full free-space connectivity around buildings/obstacles is not
claimed by this grade statistic. This is headless data evidence, not engine profiling.

| Region | Kind | Domain area (studs²) | meanGrade (%) | Support step bound (studs) | Base sealed |
|---|---|---:|---:|---:|---|
| West Cloister Superblock | superblock | 111800.0 | 0.000 | 0.400 | yes |
| Northwest Irregular Court | superblock | 70300.0 | 0.000 | 0.400 | yes |
| East Guild Superblock | superblock | 143350.0 | 0.000 | 0.400 | yes |
| East Gate Superblock | superblock | 106750.0 | 0.000 | 0.565 | yes |
| Old Town Square | public_square | 11000.0 | 0.000 | 0.575 | yes |
| Crooked Lane Court | public_square | 896.0 | 0.000 | 0.565 | yes |
| Market Cut Square | public_square | 1292.0 | 0.000 | 0.565 | yes |

Uniform horizontal support proves meanGrade=0 without double-counting overlap. Step bounds are conservative max-minus-min of actual support tops, not a measured boundary transition. Buildings and obstacles remain excluded from any claim of free-space connectivity. No semantic parks or engine tests are invented.

No HTTP 403 was observed. The push endpoint is `https://github.com/dreamer2664/civitas.git`;
only the `walk/audit` branch is published.

## Remaining gates

* **WALK-005:** 291 collidable facade-detail policy findings remain in the collision CSV.
* **WALK-007:** actual spawn (136.75,-640) still has **0/17 clear tested landmark-anchor
  rays**, at an assumed 4.5-stud eye offset. This is not proof of total pixel invisibility
  and is not an engine camera test; exact blockers/hit coordinates are in the sightline CSV.
* Unapplied candidate (136.75,-512) still has **1504.999280 clear route studs** and two clear
  Civic Archive Tower anchor rays. No actual SpawnLocation was moved by the audits.
* **WALK-006:** the placeholder lacks platform geometry. Platform exit, first-frame grounded
  rig, camera framing, streamed teleport readiness and mobile hardware remain unverified.

## Saved workspace and archival bundles

The original 7a12330 and 89edb24 manual-sweep bundles remain archival deliverables; current
work is published on origin. Tool executables (68,617,912 bytes) live in excluded cache with
small ~/bin symlinks and a pinned hash-checked bootstrap installer. No user asset is deleted;
the unrelated dirty Blender installer remains excluded from WALK commits.

## Collision policy

Ground/pavements/floors and simplified massing stay collidable. Real openings/dropped kerbs
provide access, not audit flags. Canopies/posts/furniture use simple collision with body
clearance. Decorative trim/windows/lettering do not need detailed collision. Do not hide
transparent obstacles or silently patch ground gaps. Use reused meshes/materials and local
streaming units; never make the whole city Persistent or scan it every frame.

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


### Strata handoff receipt

The three ranked follow-ups were [posted to already-merged PR #5](https://github.com/dreamer2664/civitas/pull/5#issuecomment-6597577511)
as post-merge work, not as a claim that its merge is pending. The immutable audit revision
is `a1bf937a684b82e7c147b951773f4651f3c11f81`; machine-readable delivery receipt:
`audit/strata-pr-handoff.json` (HTTP 201).
