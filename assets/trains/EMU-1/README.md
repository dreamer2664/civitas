# EMU-1 — preliminary two-car geometry study

**Status: incomplete / not for production integration.** This is reproducible geometry, not the finished European EMU requested. The cab nose now has an aperture with raked glazing; its appearance and transparency in Studio still need validation. The cab has a seat, desk and controls; the intermediate car has basic seat rows, racks and stanchions. Interior and exterior materials and silhouette still need refinement. Further asset revisions and validation remain required before acceptance. No Studio import or gameplay testing has been done.

## Build and inspect

On Debian trixie with sudo access, from repository root:

```sh
assets/trains/tools/install_blender.sh
blender -b --factory-startup --python-exit-code 1 -P assets/trains/EMU-1/build_emu.py
blender -b assets/trains/EMU-1/EMU-1.blend --python-exit-code 1 -P assets/trains/EMU-1/export_emu.py
blender -b --factory-startup --python-exit-code 1 -P assets/trains/EMU-1/verify_emu.py
blender -b assets/trains/EMU-1/EMU-1.blend --python-exit-code 1 -P assets/trains/EMU-1/verify_doors.py
```

The builder regenerates the source and three workbench renders. Exporter reads the source in memory and writes FBX, GLB and `mesh-stats.json`, leaving the source unchanged. The shared `../tools/export_common.py` is required. GLB verifier imports the export into Blender and checks six root/bogie positions; it is not a Roblox import. Use `--python-exit-code 1` to fail on script exceptions.

## Scale, axes and pivots

Source units are metres, Blender Z-up and car-forward +X; the exporter multiplies the root transforms by 1/0.28 = 3.5714286 to write studs and uses FBX forward -Z / up Y, or glTF Y-up. Scene origins are preserved. Manager must verify importer axis, pivot, scale and materials. Studs in the measurements below are axis-aligned *evaluated visual geometry*, Blender X/Y/Z, not declared target envelopes.

| Car | Measured length × width × height, studs | Contract target, studs |
|---|---|---|
| Cab | 75.000 × 10.179 × 14.643 | 75.000 × 10.179 × 14.643 |
| Intermediate | 71.429 × 10.179 × 14.643 | 71.429 × 10.179 × 14.643 |

Trailing ends have been brought to the coupling datum. `CAB_ROOT` is at (0,0,0) and `INTERMEDIATE_ROOT` at (-76.786,0,0) studs in the source frame, i.e. 21 m + 0.5 m between leading coupling datums. `CAB_BOGIE_0_PIVOT`, `CAB_BOGIE_1_PIVOT` are 10.714 and 64.286 studs behind their root; the intermediate pivots are 10.714 and 60.714 studs behind its root. Door pivots are named `*_door_*_PIVOT` at outboard leaf edges, with 1.35 m outward slide after a 0.24 m lateral plug-out. The GLB contains a `Door_open` animation with 16 channels; four render frames show the motion. Blender BVH checks found no leaf/body surface intersections in integer frames 1–24; this does not test other obstacles, continuous time or Roblox runtime collision. Apertures are 1.30 m wide × 1.95 m high per source.

## Geometry and collision

`mesh-stats.json` lists evaluated triangles, bounding dimensions and non-manifold edge counts per mesh, including collisions. Latest: 16,344 visual triangles, 168 collision triangles; largest mesh 124; zero non-manifold edges. A manifold-edge test alone does not establish absence of self-intersection, correct normals, visual quality or Roblox compatibility. There are 220 separate meshes including proxies, so draw calls and runtime costs are **not** established by triangle totals. A material/mesh consolidation pass and mobile profiling are required. Train meshes are not suitable for automatic static SLIM assumptions.

`*_COLLISION_*` objects are separate simple proxy meshes. Wall proxies are segmented around door apertures; visual meshes should be made non-colliding by the integrator, and proxy visibility/collision must be set in Studio. This is not yet a complete collision solution: cab and car ends need properly designed proxies, and moving-door collision must be integrated and tested. Keep train unanchored per contract; vector determines runtime assembly.

Purpose-named materials are porcelain body, smoked window, door vermilion, undercarriage, metal, headlamp and interior. These are preliminary solid materials, not final PBR or clean finished UV artwork. No reference photos or third-party assets were used; original procedural geometry.

Renders: `renders/door-01.png`, `door-06.png`, `door-15.png`, `door-24.png` show the motion. Main views: `renders/front-three-quarter.png`, `renders/side.png`, `renders/cab-interior.png`. They are headless Blender Workbench previews, not Studio screenshots.
