# WALK · pave — latest strata integration audit

**2026-11-02 · `walk/audit` · GEOMETRY CONTINUITY PASS · overall slice NOT FROZEN**

## Publication and provenance

At the first push attempt, restored the public remote configuration (excluded from workspace
snapshots), then authenticated without storing a credential in source or remote URL.
`git push -u origin walk/audit` returned **Everything up-to-date**. Remote verification:

```
89edb247844602465bb0f40da45451c04469a1da refs/heads/walk/audit
```

Thus the earlier audit and sidewalk repair were already published. This checkpoint integrates
strata's newer **29002314a6a42b9930e9bba6c910ced417a67a23**, through merge **0a46a27**,
retaining WALK's real rear pedestrian doorways. The resulting city has **302 ordinary
buildings, 12 landmarks, 50 blocks including 4 irregular superblocks, 2 pocket squares and
35 street segments**. Final published checkpoint SHA is verified after commit/push in the
session response; publication is no longer blocked by the earlier rejected credential.

Merge conflicts were limited to the part-count recipe and generated plan. Resolution counts
both the two new pocket squares and the rear facade piers/headers; no geometry was omitted.
The generated plan was regenerated from the merged modules, not hand-edited. The actual
builder export asserts its constructed part count equals the recipe estimate.

## Real geometry audit results

The same unmodified runtime construction loops in CityGenerator/CityBuilder execute under
Lune's Roblox data model. Pure strict Luau and independent Python geometry checks agree.
No Roblox engine, physics, mobile hardware or camera execution is claimed.

| Metric | Current result |
|---|---|
| Actual BaseParts / estimated recipe | **1924 / 1924** |
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

The new clipped streets reuse instance names: the 1924 parts contain **119 duplicate full
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
* `lune run tools/walkaudit/check_world.luau` → **1924 actual parts**, 70 sidewalks clear.
* `python tools/walkaudit/streaming.py` → continuous bounding-footprint envelopes below.
* `python tools/walkaudit/audit_world.py` → independent geometry and integrated same envelopes.

| Radius | Continuous minimum | Continuous peak |
|---:|---:|---:|
| 64 | 7 | **46** |
| 256 | 31 | **337** |
| 384 | 88 | **650** |
| 512 | 222 | **1065** |
| 1024 | 1084 | **1921** |

The analytic rounded-rectangle entry/exit sweep spans the whole route and includes closed
contacts; no 16-stud sampling is used to claim a maximum. Cylinder footprints remain
conservative. These are not observed stream residency, retained models or GPU draw calls.

**Recommend profiling min 64 / target 384**, whose continuous envelope is now 650 parts
(up from 621). 512 reaches 1065 before characters/trains under a one-main-pass-submission-
per-part proxy. At configured 1024 the same proxy is 1921. These are estimates, not an upper
bound on total GPU passes: batching/culling reduce calls; shadows/multipass work may add them.
Streaming can retain models beyond the target radius. Actual phone memory, frame time,
draw calls, triangles and pause behavior remain unmeasured.

Committed architecture defaults remain **StreamingEnabled=true, 64/1024, Improved,
PauseOutsideLoadedArea, Opportunistic** pending device/visibility validation. Static Rojo
Workspace BaseParts are 0 because geometry is generated at runtime; that is not the city
count. No full-city per-frame scan or other phone-client analysis was introduced.

## Verification

Run `bash tools/walkaudit/verify.sh`. All **54 regression tests pass**: 18 Luau + 11 Python
geometry + 9 streaming + 9 sightline + **7 upstream generator tests** (one added by strata).
The full pipeline still returns **1** for the separate current-spawn tested-anchor gate.

* Direct Lune real-world geometry check: **exit 0**, 1924 parts, 70 sidewalks clear, sealed
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

