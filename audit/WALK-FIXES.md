# WALK fixes after PARKS/handoff close-out

Base: `origin/main` 6585239 (lumen HUD included). The WALK history was rebased on a new
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
