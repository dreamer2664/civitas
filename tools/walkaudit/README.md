# WALK real-builder audit

`bash tools/walkaudit/verify.sh` from repo root runs lint, format and scoped Luau static
analysis, 18 pure Luau regression tests, 11 Python clipping/geometry regression tests,
strata's 6 generator tests, Rojo assembly, actual builder export and exact geometry audit.
It returns nonzero for route, sidewalk or crossing continuity defects. This is NOT an engine test.

`lune run tools/walkaudit/check_world.luau` is the direct real-geometry Lune assertion gate.
It loads the actual builder/exporter and runs the strict pure `OrientedAudit` kernel.
`python tools/walkaudit/compare.py` requires the independent Python results to agree with
Lune on seal, length, steps and every sidewalk/crossing defect. Both currently fail city continuity
for the same two station-wall conflicts. Noncollidable intended surfaces are explicitly
rejected even over an otherwise solid fallback ground slab.

## Provenance

`export_world.luau` loads the **unmodified** CityBuilder source with `@lune/luau`, supplying
Lune's Instance, Vector3, Enum and Color3 as the globals. It loads the same CityGenerator
and CityConfig modules used by WorldBootstrap. This executes the real construction loops
and exports the actual 1817 constructed BaseParts, including all collision obstacles.
No separate formula-based mock or hand-maintained part estimate is used.

Lune stores properties but does not simulate Roblox. The inspected builder revision writes
Position and optional Orientation, never CFrame/PivotTo. Export therefore uses Position
and Orientation directly, with zero default yaw. A future builder using CFrame or dynamic
placement needs an adapter update; do not silently keep this assumption. No physics,
streaming, Humanoid state, render submission or character grounding is simulated.

## Actual geometry audit

`python tools/walkaudit/audit_world.py`:
* Exact base-solid containment: the actual closed CollidableGround box contains all corners
  of the full rectangular slice. This proves every x/z coordinate is sealed at its top,
  not just a sample grid. It does not prove every possible upper level is hole-free.
* Analytic line/rotated-box clipping, including non-axis-aligned route links and diagonals.
* Support uses a 1-stud inward margin: a radius-1 footprint must fit a true support rectangle
  at every route interval. This is conservative; it can reject a valid union-supported edge.
* Obstacles use a 1-stud outward margin, 5-stud headroom and 1.2-stud step threshold. Cylinder
  obstacles are conservatively enclosed; cylinder support cannot establish a pass. Unknown
  shapes and tilted surfaces fail. Future true ramps/meshes need exact surface support.
* Both crossing axes at all 81 declared grid intersections are checked (162 crossings).
  The current largest crossing step is 0.254997 studs with no gaps/body blockers. No
  driveway inventory exists; this does not invent semantic driveway coverage.
* Every actual sidewalk's long axis is independently audited (48, including diagonals),
  with 1-stud endpoint inset. Results identify source-part IDs and exact blocked spans.
* District A and station-concourse spawn locations receive support/clearance checks. This
  is not a runtime teleport or first-frame physics test. No platform is present to test.
* Streaming envelopes at 64/256/384/512/1024 studs count footprint/circle intersections
  at 114 route positions, max 16-stud spacing. These are sampled conservative residency
  envelopes, NOT engine residency, true streaming maxima, GPU calls or memory measurements.
* Unbatched main-pass estimate assumes one submission per resident part, no batching or
  culling. This is a risk proxy, not a guaranteed upper bound on total GPU draw calls
  (shadows/multipass effects can add calls; batching/occlusion can reduce calls).

The old `run.luau` proposed box adapter remains available but is no longer the main city
check. It must not overwrite the current evidence with a synthetic fixture pass.

## Outputs

`docs/reports/walkability-world.json`: actual part export and source waypoints.
`walkability-live-results.json` and `walkability-results.json`: results, spawn checks,
all sidewalk findings, policy findings and streaming envelopes.
`walkability-geometry-defects.csv`: all coordinate/span findings across route, sidewalks and crossings.
`walkability-collision-defects.csv`: all 291 decorative-collision IDs, coordinates and sizes.
`walkability-metrics.json`: configured properties and static/constructed part counts.
`renders/walkability-route.svg`: actual footprints, gold audited route, red blocked sidewalks.
`walkability-milestone.rbxlx`: Rojo assembly evidence, not simulated runtime geometry.

No source geometry or collision flags are changed by these tools. Forward findings to strata.
Full audits stay offline; no Heartbeat scan is introduced.
