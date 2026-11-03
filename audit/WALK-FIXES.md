# WALK fixes after PARKS/handoff close-out

Base: `origin/main` ce23e4d (CI place workflow and lumen HUD included). The WALK history was rebased on a new
`walk/fixes` branch, leaving published `walk/audit` intact; no force push required.
Conflicts were limited to station estimated-part arithmetic, its recipe regression test,
and generated plan count. Resolution retains BOTH upstream pocket squares and WALK rear
exits: 1924 actual/estimated parts. No HUD conflict occurred; `src/client` is unchanged
from main (lumen's version). PARKS and PR handoff are closed, not re-opened by these fixes.

These are fixes to audit blind spots, not invented physical defects or unrequested paving.
Existing geometry and the unresolved spawn/camera gate remain honestly distinguished.

## 1. Crossing

The old 162 tests crossed carriageway centres only. Add **324 sidewalk-aligned crossings**,
both sides of both axes at all 81 declared intersections. X span uses widthX, with its
sidewalk offset derived from widthZ, and conversely for Z. Real exported collidable support
and body-envelope checks apply, with no synthetic ground. Negative tests prove that a wall
off-centre can pass the former check yet fail this gate. Three regression tests pass;
324/324 real desire-line crossings pass. Original 162 checks remain intact.

Reproduce: `bash tools/walkaudit/verify.sh`; JSON: `docs/reports/walkability-street-fixes.json`.
Current total: 67 passing regression tests. Full command exits 1 only for the known actual
spawn anchor gate; no Studio, physics, rig, camera or device claim.

## 2. Sidewalk width

Enforce the independent **3.5-stud** District A physical slab floor, not merely the
config's declared value or the availability of sealed ground beneath a too-narrow slab.
Sweep both edge lanes plus centre (radius-1 body/footprint); all 70 actual slabs have
three passing lanes. Preserve yaw and use named street axis to distinguish true transverse
width from clipped length. Three new negative/boundary tests cover a 3.49-wide slab,
an edge-only obstruction hidden from the old centreline check, and a short yawed X slab.
Nominal width plus these edge sweeps is not a two-avatar passing or engine navigation claim.
Total now 70 passing regressions; full gate remains spawn-only exit 1.

## 3. Curb return — real builder repair

The new exact opening check found **104 violating pieces among 428**. Reproduced with the
actual pre-fix generator/builder at published `0ffb8e6`, not a synthetic substitute; baseline source
hashes and every failing source ID/opening are in `audit/curb-return-before.json`.

Root cause: curb gaps were one-sided-clipped. For gaps beyond a clipped street's finish,
`max(street.start,gap.start)` could exceed that finish; the builder emitted oversized curb
runs repeatedly. Clamp BOTH interval endpoints into `[street.start,street.finish]` in the
builder and matching estimated-part recipe/test. No road/superblock layout was changed.

Example before: `CurbReturn_x_455_1_9`, centre (505,0.18,465.325), length 178, invaded
opening x=[417.5,452.5] at intersection (435,455) by **35 studs**. All 104 offending parts
are removed, not collision-disabled: **324/324 remaining curb pieces pass**, total parts
**1820/1820** (down 104). Genuine pocket squares and both station rear exits are retained.
The gate validates real solids/offsets and a body-width apron, not merely the radius attribute.
It covers straight grid returns; it does not claim actual curved corner geometry exists.

Three regressions reject a low curb in an opening despite a passing step-height check,
0.01-stud intrusion at an exact boundary, and a misplaced curb borrowing a valid name.
A 0.0001-stud overlap tolerance handles float32 export only.

## Final verification

- `bash tools/verify.sh`: **PASS** including lumen HUD/client checks, 122 main + 23 rail
  tests, seven city tests, strict World/client analysis, export and Rojo build. Full log:
  `tools/walkaudit/main-rebase-verify.log`.
- `bash tools/walkaudit/verify.sh`: **73 regressions pass**, all geometry and independent
  parity PASS; **exit 1 solely for the previously recorded actual-spawn anchor gate**.
- New geometry: **324 crossing desire lines, 70 sidewalk widths / 210 swept lanes,
  324 curb-return solids; zero failures**. Original 70 sidewalks / 162 crossing axes clear.
- Continuous part-envelope peak at radius 384: **611**, at 1024: **1817**; not measured
  GPU calls or streaming behavior. No engine/physics/camera/mobile claim.
- Published audit/handoff remain immutable historical checkpoints, not newly reopened tasks.
