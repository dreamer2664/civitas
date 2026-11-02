# WALK real-builder audit

`bash tools/walkaudit/verify.sh` from repo root runs lint, format and scoped Luau static
analysis, 18 pure Luau regression tests, 11 Python clipping/geometry regression tests,
9 continuous streaming-envelope regression tests, 9 conservative sightline tests,
strata's 7 generator tests, Rojo assembly, actual builder export and exact geometry audit.
It returns nonzero for route, sidewalk, crossing or actual-spawn tested-anchor failures. This is NOT an engine test.

`lune run tools/walkaudit/check_world.luau` is the direct real-geometry Lune assertion gate.
It loads the actual builder/exporter and runs the strict pure `OrientedAudit` kernel.
`python tools/walkaudit/compare.py` requires the independent Python results to agree with
Lune on seal, length, steps and every sidewalk/crossing defect. Both currently pass city continuity; the two station-wall conflicts are now repaired by real rear doorways. Noncollidable intended surfaces are explicitly
rejected even over an otherwise solid fallback ground slab.

## Manual-sweep geometry repair and tool-cache budget

The Director assistant explicitly authorized a local fix outside the original World lane.
Two 7-wide / 8-high rear doorways now align with x=103.25 and x=136.75. Three solid wall
piers and two solid headers replace the monolithic wall; all remain collidable. No audit
exclusions or ground changes were used. Both real geometry audits now pass all 70 sidewalk pieces;
part count is now 1924 after the latest superblock/pocket-square integration. The full pipeline still exits 1 for the original spawn tested-anchor gate.

`bootstrap_tools.py` keeps 68,617,912 bytes of pinned, SHA-256-checked executables in excluded
`~/.cache/civitas/toolchain`, with only small symlinks in `~/bin`. If the cache is missing in
a later snapshot, verify.sh reinstalls those exact versions automatically. Existing binaries
were relocated, not discarded. The missing-cache download path was tested with Selene.

## Provenance

`export_world.luau` loads the **unmodified** CityBuilder source with `@lune/luau`, supplying
Lune's Instance, Vector3, Enum and Color3 as the globals. It loads the same CityGenerator
and CityConfig modules used by WorldBootstrap. This executes the real construction loops
and exports the actual 1924 constructed BaseParts, including all collision obstacles.
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
* Streaming envelopes at 64/256/384/512/1024 studs use an analytic continuous sweep of
  bounding-footprint/disk intersection intervals over the entire route, not 16-stud
  samples. A rounded rectangle is decomposed into two strips and four corner disks;
  clip each primitive, merge the convex interval and sweep per-part entry/exit events.
  Cylinder bounds remain conservative. Closed-boundary contacts count. The previous
  sampled numbers are retained separately for comparison. The new peak at radius 512
  is 1005 (not sampled 998), and 384 peaks at 621 (not 620).
  These are NOT engine residency, GPU calls, retained models or memory measurements.
* Unbatched main-pass estimate assumes one submission per resident part, no batching or
  culling. This is a risk proxy, not a guaranteed upper bound on total GPU draw calls
  (shadows/multipass effects can add calls; batching/occlusion can reduce calls).

The old `run.luau` proposed box adapter remains available but is no longer the main city
check. It must not overwrite the current evidence with a synthetic fixture pass.

## Spawn anchor sightlines and candidate (not runtime applied)

`python tools/walkaudit/sightlines.py` casts 3D rays through actual constructed bounding
solids from an explicitly assumed eye offset. It skips fully transparent parts, but treats
partial transparency and cylinders conservatively. No rig, FOV, camera or pixel visibility
is simulated. The current spawn has no clear tested Crown/Lantern anchor (17 rays across
12 landmarks). This is not a proof that all landmark pixels are invisible.

The pure `src/server/Spawn/RecommendedPlan.luau` chooses (136.75,-512), Civic Archive Tower,
and a 4.5-stud assumed eye offset. Lune proves the modified-first-waypoint route is clear
and remains 1504.999280 studs; Python finds two clear landmark-anchor rays from existing
support. This plan is not wired to runtime or applied to the existing SpawnLocation.
`walkability-spawn-candidate.json` records that distinction explicitly. The original spawn
still fails the anchor gate; no geometry or spawn is silently patched by the audit.

## Outputs

`docs/reports/walkability-world.json`: actual part export and source waypoints.
`walkability-live-results.json` and `walkability-results.json`: results, spawn checks,
all sidewalk findings, policy findings and streaming envelopes.
`walkability-geometry-defects.csv`: all coordinate/span findings across route, sidewalks and crossings.
`walkability-collision-defects.csv`: all 291 decorative-collision IDs, coordinates and sizes.
`walkability-spawn-sightlines.csv/json`: actual-spawn target/blocker/hit coordinates.
`walkability-spawn-candidate.json`: unapplied candidate route and anchor proof.
`walkability-streaming-exact.json`: continuous bounding-footprint extrema and peak coordinates.
`walkability-metrics.json`: configured properties, part counts and source SHA-256 manifest.
`renders/walkability-route.svg`: actual footprints, gold audited route, red blocked sidewalks.
`walkability-milestone.rbxlx`: Rojo assembly evidence, not simulated runtime geometry.

No source geometry or collision flags are changed by these tools. Forward findings to strata.
Full audits stay offline; no Heartbeat scan is introduced.

## Latest strata integration (2900231)

Retains both real rear exits and includes strata's superblocks and two pocket squares.
Actual builder count is 1924; 70 sidewalk pieces and 162 crossing axes pass. Split pieces
reuse FullName, so the export now retains sourcePath/sourceIndex and assigns export-local
@pieceN IDs for duplicates. Every exported ID is asserted unique; comparisons no longer
conflate distinct pieces with identical source paths. Geometry algorithms are unchanged.
Continuous peaks: radius 384 -> 650; radius 1024 -> 1921. Original spawn tested-anchor
gate still fails. The 54 unit/regression tests pass; the full slice is not frozen.
