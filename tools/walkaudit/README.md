# WALK geometry handoff (proposed adapter, not a shared contract change)

Run from repo root: `bash tools/walkaudit/verify.sh`.
Needs lune, rojo, selene, stylua and luau-lsp on PATH (`$HOME/bin` also searched).
The command is deliberately **red** when World is absent, even when fixtures pass.

## WORLD · strata integration request

No World module exists at baseline `aea670197fea6d24e5fde7b7e2a576a5ed4a0a09`.
Provide a **pure** module `src/server/World/Geometry.luau` with
`generateAuditData()` returning the following export. Alternate module path can be passed
as the first argument to verify.sh (resolved relative to tools/walkaudit/run.luau).
Do not maintain an independent simplified mock: derive this export from the same data
used by the runtime generator. Each box needs a stable source-part ID.

```lua
{
  schema = "walk-boxes-v1",
  boxes = {
    {id="source part ID", x0=0, x1=100, z0=0, z1=100,
     bottom=-2, top=0, collide=true, walk=true},
  },
  bounds = {x0=0, x1=100, z0=0, z1=100},
  route = {{x=5,z=5}, {x=95,z=5}}, -- actual ordered route >=1500 studs
  citySpawn = {x=5,z=5},
  stationSpawn = {x=95,z=5},
}
```

This is a local consumer format, not a change to Manager-owned GeometryContract.
Only exact anchored axis-aligned solid boxes are supported. Do not export rotated parts,
ramps, wedges, mesh bounding boxes, cylinders or Terrain as boxes: that would create false
proof. A future adapter must support their true surfaces or explicitly block acceptance.
`walk` marks actual intended support surfaces, not roofs or decoration. Bounds declare a
rectangular, continuously grounded area, including building footprints. Nonrectangular
coastlines/holes require a proper domain extension; do not hide holes by shrinking bounds.
Export ALL collision obstacles, including transparent ones. State source provenance in PR.

The route must be independently checked for District A sidewalk -> grid -> public square ->
station forecourt -> concourse, with station platform -> city also covered. Current audit
cannot prove those semantic destinations, landmark visibility, avatar simulation or streaming.

## Algorithms / scope

* Seal: split the declared rectangle at every box x/z boundary. Each nonzero cell has
  constant box membership. Checking its interior proves rectangular union coverage, not
  just coverage at a regular grid of sample coordinates. Boundaries are closed.
* Route: split each segment at every surface and expanded obstacle boundary. Detect any
  unsupported interval (stricter than the 0.5-stud contract), height changes >1.2, and
  overlap with a 2-wide, 5-high conservative body box. Unknown geometry must not enter.
* Spawn: requires a flat supported 2x2 footprint and body clearance. A plan validator,
  **not runtime spawn wiring**, streamed availability or a first-frame physics test.
* Complexity is intentionally headless: seal is O(B^3) worst case, route O(R*B^2).
  Do not execute these full audits per frame or use them on a full 25k-part scene without
  spatial indexing/union optimization. Report overhead separately from gameplay cost.
* Route currently proves centerline support, not the full swept foot/body support width;
  diagonal corner clipping and partial edge support remain acceptance blockers.

Outputs: results JSON (including geometry on successful load), metrics JSON, SVG render,
and Rojo-built milestone place. Render script shows an explicit blocker instead of drawing
an invented route when there is no real geometry. Draw calls require engine measurement;
part counts are not draw calls.
