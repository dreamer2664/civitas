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
blender -b assets/trains/EMU-1/EMU-1.blend --python-exit-code 1 -P assets/trains/EMU-1/verify_geometry.py
blender -b assets/trains/EMU-1/EMU-1.blend --python-exit-code 1 -P assets/trains/EMU-1/verify_roof.py
blender -b assets/trains/EMU-1/EMU-1.blend --python-exit-code 1 -P assets/trains/EMU-1/verify_gangway.py
blender -b --factory-startup --python-exit-code 1 -P assets/trains/EMU-1/verify_livery.py
blender -b --factory-startup --python-exit-code 1 -P assets/trains/EMU-1/verify_vehicle_bridges.py -- --gltf
```

The builder regenerates the source and renders; set `CIVITAS_SKIP_RENDERS=1` to save the source without producing a render batch. Exporter reads the source in memory and writes FBX, GLB and `mesh-stats.json`, leaving the source unchanged. The shared `../tools/export_common.py` is required. GLB verifier imports the export into Blender and checks six root/bogie positions; it is not a Roblox import. Use `--python-exit-code 1` to fail on script exceptions.

## Scale, axes and pivots

Body-envelope measurements below exclude roof equipment, the raised pantograph, the separate footboards and boarding bridges. Fixed footboards reach 1.60 m from the centreline, within the ratified 3.20 m structural clearance envelope. Source units are metres, Blender Z-up and car-forward +X; the exporter multiplies the root transforms by 1/0.28 = 3.5714286 to write studs and uses FBX forward -Z / up Y, or glTF Y-up. Scene origins are preserved. Manager must verify importer axis, pivot, scale and materials. Studs in the measurements below are axis-aligned *evaluated visual geometry*, Blender X/Y/Z, not declared target envelopes.

| Car | Measured length × width × height, studs | Contract target, studs |
|---|---|---|
| Cab | 75.000 × 10.179 × 14.643 | 75.000 × 10.179 × 14.643 |
| Intermediate | 71.429 × 10.179 × 14.643 | 71.429 × 10.179 × 14.643 |

Trailing ends have been brought to the coupling datum. `CAB_ROOT` is at (0,0,0) and `INTERMEDIATE_ROOT` at (-76.786,0,0) studs in the source frame, i.e. 21 m + 0.5 m between leading coupling datums. `CAB_BOGIE_0_PIVOT`, `CAB_BOGIE_1_PIVOT` are 10.714 and 64.286 studs behind their root; the intermediate pivots are 10.714 and 60.714 studs behind its root. Door pivots are named `*_door_*_PIVOT` at outboard leaf edges, with 1.35 m outward slide after a 0.24 m lateral plug-out. The GLB contains a `Door_open` animation with 16 channels; four reproducible render frames show the motion after rebuilding (not kept in the repository). Blender BVH checks found no leaf/body surface intersections in integer frames 1–24; this does not test other obstacles, continuous time or Roblox runtime collision. Apertures are 1.30 m wide × 1.95 m high per source.

The intermediate car has bespoke HVAC boxes, insulators and a fixed raised pantograph. Contact height is 5.65 m / 20.179 studs above rail top, HVAC max is 4.41 m / 15.750 studs. `verify_roof.py` checks contact height and pantograph/HVAC mesh surface overlap; it does not establish wire contact, power collection or animation. The proposed central station bridge underside is 6.88 m, but actual overhead wiring and clearance remain untested.

The 0.5 m inter-car gap now has bespoke bellows, open end portals and a separate floor collision proxy. `verify_gangway.py` samples the floor and three unobstructed visual rays in the straight pose; the bellows is rigidly parented to the cab, not a flexible/animated joint, so curves, moving collision and boarding remain unverified.

Eight vehicle-mounted bridge pivots, one per door, are included in the car hierarchy in a stowed pose; see `INTEGRATION.md` for controls, dimensional reconciliation and safety caveats. They are not an operational boarding solution without runtime integration.

The car-floor collision proxies now align with the 0.76 m platform floor. Fixed 1.20 m-wide footboards at each door extend the support proxy to 1.60 m from track centre, within the 1.60 m half-width clearance envelope. In a representative, static, aligned Blender test with Central platform 2, the open doorway is visually clear and the unsupported proxy gap is approximately 0.10 m (0.357 studs, sampled in 0.01 m increments), down from approximately 0.40 m. This is not proof of boarding: actual avatar steps, train placement, station gaps and collision groups must be tested in Studio.

## Geometry and collision

`mesh-stats.json` lists evaluated triangles, bounding dimensions and non-manifold edge counts per mesh, including collisions. Latest: 20,452 visual triangles, 396 collision triangles; largest mesh 2,808; zero non-manifold edges. A manifold-edge test alone does not establish absence of self-intersection, correct normals, visual quality or Roblox compatibility. There are 94 source meshes including proxies: 47 cab and 47 intermediate, down from 171 combined in the original study (before interiors were added). Static objects sharing a material are consolidated; each animated door leaf retains its pivot, each bogie and centred wheelset axle pivot is separate, and couplers and collision proxies remain separate. Door meshes have multiple materials and may split into additional glTF/Roblox primitives, so source-mesh counts do not establish draw calls or imported MeshPart count. Mobile profiling and Studio inspection remain required. Train meshes are not suitable for automatic static SLIM assumptions.

Objects whose names contain `COLLISION` are separate simple proxy meshes. Wall proxies are segmented around door apertures; visual meshes should be made non-colliding by the integrator, and proxy visibility/collision must be set in Studio. This is not yet a complete collision solution: cab and car ends need properly designed proxies, and moving-door collision must be integrated and tested. Keep train unanchored per contract; vector determines runtime assembly.

Nine purpose-named materials, including a blue waist belt and door surrounds, share `assets/trains/textures/rail_palette.png`, a reproducibly generated 1024×1024 base-colour swatch atlas. Each face has nondegenerate UVs within the appropriate swatch. This is a flat-colour atlas, not a detailed paint/weathering texture set; there are no normal, metallic or roughness texture maps. Roughness is 0.38 for stock materials and 0.12 for cab glazing. GLB contains one embedded image; FBX embeds the same atlas. `verify_livery.py` reimports the GLB into Blender and checks 432 blue triangles across all four car sides, with 1,296 UV loop samples inside the blue atlas swatch and belt/surround height coverage. This is not a visual-quality, FBX or Studio import test. Import appearance requires Studio validation.

| Render material | Triangles | Share |
|---|---:|---:|
| body_porcelain | 4,708 | 23.02% |
| cab_windscreen_glazing | 36 | 0.18% |
| door_vermilion | 1,728 | 8.45% |
| headlamp | 648 | 3.17% |
| interior | 72 | 0.35% |
| livery_blue | 432 | 2.11% |
| metal | 3,168 | 15.49% |
| undercarriage | 4,152 | 20.30% |
| window_smoked | 5,508 | 26.93% |

Shares use 20,452 render triangles; rounding may affect totals. No reference photos or third-party assets were used; original procedural geometry.

Renders: `renders/gangway.png` shows the car joint; `renders/roof-equipment.png` documents the raised pantograph. The build regenerates the four `renders/door-*.png` motion frames on demand. Main views: `renders/front-three-quarter.png`, `renders/side.png`, `renders/cab-interior.png`. Exterior and door views are headless Blender Workbench previews; the cab view is headless Cycles, with a striped render-only target outside to show the sightline. The target is not included in the source asset or exports. None are Studio screenshots.

Studio must validate importer axis, scale and pivots; glazing transparency; collisions, boarding and moving doors; and LOD transitions and runtime performance. Blender checks do not replace these tests.

## Far LOD candidates

`CAB_LOD1` and `INTERMEDIATE_LOD1` are static, frame-1 visual meshes regenerated on demand (their BLEND/FBX/GLB outputs are not committed) and produced by a 20% collapse of evaluated source geometry, omitting bridge plates stowed inside their footboards. Cab: 1,720 triangles; intermediate: 2,350; total 4,070; non-manifold edges 0. `lod1-mesh-stats.json` contains the audit; `renders/lod1.png` is regenerated by the LOD build. They contain no collision or usable door/pantograph animation and should not be substituted while nearby players interact. Material splits may produce multiple imported MeshParts. There is **no implemented runtime LOD switching**, no Roblox LOD transition test and no performance claim.

```sh
blender -b assets/trains/EMU-1/EMU-1.blend --python-exit-code 1 -P assets/trains/EMU-1/build_lod.py
blender -b assets/trains/EMU-1/EMU-1-LOD1.blend --python-exit-code 1 -P assets/trains/EMU-1/export_lod.py
```
