# Civitas Central — station envelope and two platforms

**Status: geometry and sampled Blender route checks, not a Roblox place or a proven walkable city.** This is an original procedural asset, no sourced models. It imports the existing `platform-kit.blend` and instances its mesh datablocks; the kit source and shared export script are required to rebuild. The central roof has a cutaway only in `renders/overview.png`, never in the exported geometry.

## Coordinate handoff to strata and pave

World convention X east, Y up, Z south. **Nominal core footprint:** X 3700–4300, Z 3300–3500 studs; small facade details/eaves project beyond this core. Place `CENTRAL_ROOT` at `(4000, 0, 3400)` studs. This assumes world rail-top Y=0; **strata must confirm square and rail elevations**. Blender Z-up source metres convert at 1 m = 3.571428571 studs; Blender +X→world +X, +Y→world -Z, +Z→world +Y. Import with explicit Y-up and verify the actual transform in Studio.

| Interface | Proposed world coordinates, studs |
|---|---|
| Concourse and platform top | Y = 2.714286, assuming rail top Y=0 |
| North frontage, toward square | Z = 3300; doorway X-centres 3930, 4000, 4070 |
| Each clear opening | X width 20; floor-level threshold; no door leaf |
| Platform centres | Z 3360 and 3420, X 3857.143–4142.857 |
| Rail centre lines | Z 3376.786 and 3403.214, through east–west |
| Bridge deck | Y 25.000, centred at X 4133.714, spans platform centres |

`placement.json` is the machine-readable proposal. The ramp starts on each platform at X≈3863.071 and rises east at 1:12 to X≈4130.500, where it meets the bridge flush. Its walking width is 1.8 m (6.429 studs); deck underside is 6.88 m (24.571 studs) above rail top. Overhead wire is not modeled; actual clearance must be coordinated. Same-level north concourse overlaps platform 1; two ramps plus bridge connect platform 2 without a track crossing. No lift is provided. The canopy is an instance of the kit stretched vertically to clear the ramps; confirm the proportions at review.

**Coordinate conflict:** `docs/rail/NETWORK.md` describes Central at (0,0), underground, in its own provisional frame. Manager's explicit (4000,3400) request is followed here, but neither railway alignment nor actual world Y is confirmed. Coordination request: https://github.com/dreamer2664/civitas/issues/4. Do not place this as a validated railway interchange until Manager, vector, strata and pave resolve it. A later inspection of strata branch `world/historic-core-blockout` at `65a69b0` found its station entry at (120, 858), width 176, depth 150, concourse top Y=0.63: it does not match this 600 × 200 station or Y=2.714286 floor. Aligning entry centres alone would require X/Z translation (-3880, -2442), clearance for the larger footprint, and a 2.084286-stud elevation transition. No connected city route is claimed.

## Rebuild and verify

From repository root, Blender 4.3.2:

```sh
blender -b --factory-startup --python-exit-code 1 -P assets/stations/civitas-central/build_station.py
blender -b assets/stations/civitas-central/civitas-central.blend --python-exit-code 1 -P assets/stations/civitas-central/export_station.py
blender -b assets/stations/civitas-central/civitas-central.blend --python-exit-code 1 -P assets/stations/civitas-central/export_platform_module.py
blender -b assets/stations/civitas-central/civitas-central.blend --python-exit-code 1 -P assets/stations/civitas-central/export_reflected_module.py
blender -b --factory-startup --python-exit-code 1 -P assets/stations/civitas-central/verify_reflected_module.py
blender -b --factory-startup --python-exit-code 1 -P assets/stations/civitas-central/verify_module_export.py
blender -b --factory-startup --python-exit-code 1 -P assets/stations/civitas-central/verify_module_export.py -- --fbx
blender -b assets/stations/civitas-central/civitas-central.blend --python-exit-code 1 -P assets/stations/civitas-central/verify_instances.py
blender -b assets/stations/civitas-central/civitas-central.blend --python-exit-code 1 -P assets/stations/civitas-central/verify_station.py
blender -b --factory-startup --python-exit-code 1 -P assets/stations/civitas-central/verify_station.py -- --gltf
blender -b --factory-startup --python-exit-code 1 -P assets/stations/civitas-central/verify_walkway.py -- --gltf
blender -b --factory-startup --python-exit-code 1 -P assets/stations/civitas-central/verify_passenger_route.py -- --gltf
blender -b --factory-startup --python-exit-code 1 -P assets/stations/civitas-central/verify_boarding.py -- --gltf
blender -b --factory-startup --python-exit-code 1 -P assets/stations/civitas-central/verify_seam.py -- --gltf
```

Four separate 40 m × 6 m module roots (two per platform), each containing the exact same local 81-mesh assembly and ten 4 m kit bays. Platform 2 reflects the same assembly via a negative Y scale. `verify_instances.py` checks all child transforms and shared mesh datablocks; Blender GLB reimport also preserves the reflection. Studio may handle reflected transforms or normals differently, so check the imported platform before relying on it. `platform-module.fbx` and `platform-module.glb` export the unreflected assembly at a base-centre origin of zero. `platform-module-reflected.fbx/.glb` is a separate alternative that bakes the reflection into its mesh vertices with winding flipped and retains positive object transforms; `verify_reflected_module.py` compares all 81 mesh counts and 18,120 triangle-centre surface and winding samples in both directions against the mirrored unreflected GLB in Blender, within 0.002 stud. These samples do not prove full surface, shading or material equivalence. This alternative is not automatically substituted into the main station GLB and still needs Studio normals, materials and collision checks. Each standalone assembly has 8,552 visual and 528 collision triangles; its visual and proxy surfaces measure 142.857 × 21.429 studs with tops at Y=0 after Blender GLB round-trip. Each type shares one mesh datablock in Blender: 40 each of edge, coping, tactile and canopy; the tactile mesh is a station-specific 20% decimation of the original kit, preserving the original source; four each of bench, bin, lamp and gantry. A surface and separate collision proxy are added to each module; coping/edge/tactile visual collisions are omitted in favour of surface proxies. Export hierarchy and actual Roblox asset sharing must be checked in Studio.

Latest evaluated audit: **39,656 visual + 2,268 collision triangles**, largest mesh 1,236 triangles, zero non-manifold edges; **198 visual and 157 collision mesh objects** in the Blender scene. Tactile studs account for 28,880 visual triangles (40 × 722), reduced from 144,480 by the shared station-specific decimation. Confirm tactile appearance at walking distance in Studio before acceptance. These are not draw calls, imported part counts, or mobile performance measurements. Collision boxes intentionally remain separate to preserve door apertures, not merged into a convex hull. Render meshes should be non-colliding; proxy meshes invisible, colliding and anchored when integrated, with actual settings verified in Studio. Static architecture grouped by material and spatial zone; very long roof/rail objects are still a streaming concern.

`verify_station.py` samples floor and head-height rays at three doors, samples both ramps and the bridge, and checks collision-proxy and visual headroom. It also probes 24 lengthwise lines through each nominal track envelope and one centreline at the raised pantograph height; these sparse rays are not a swept volume or a wire-contact test. With `--gltf` it first reimports the exported GLB in Blender, verifies the four scaled module transforms and repeats those sampled checks against the reimported geometry; this is a Blender round-trip, not a Studio import. `verify_walkway.py` additionally tests 4,735 sampled positions, including a connected 1.2 m-wide path from the west doorway across the concourse to the first ramp, both ramps and the bridge. The bin was moved off the entrance corridor and the ramp now meets the bridge without the earlier 0.075 m vertical overlap. A further 420-point, 0.56 m-wide sampled corridor connects a representative platform-2 point to its ramp foot. A separate Blender round-trip positions the intermediate car at one representative door: closed/open visual rays behave as expected and the remaining unsupported collision-proxy gap is approximately 0.10 m (0.357 studs, 0.01 m sample resolution). `verify_seam.py` combines both GLB checks at the same representative platform point, forming a sampled chain from an open train doorway to the inside of the north concourse threshold; the open doorway corridor is 0.56 m wide, with a 0.10 m unsupported gap. The exact train service stop is not defined, and the exterior street is not part of this scene. These remain sampled rays, not a continuous path certification or a Roblox boarding test. It does **not** sweep a humanoid, prove continuous collision, prove accessibility, test moving trains, or validate imported physics/streaming. Caveat: outside sidewalk and streets are not provided here, and terrain connection is not tested. Renders: `renders/facade.png`, `renders/overview.png`, `renders/concourse.png`; Blender Workbench images, not Studio screenshots.

## Experimental deployable boarding bridge — NOT integrated

The actual exported station/train remain unchanged and retain their roughly 0.10 m boarding gap. As a candidate, `build_boarding_bridge.py` generates **two separate static poses**, not an animated or operational step: a 1.10 m wide, 0.26 m deep, 0.04 m thick plate and matching collision proxy. The root is at a door's track centre/rail top and the plate faces local -Y. Stowed it reaches 1.60 m from track centre; deployed it reaches 1.78 m, overlapping both the 1.60 m train footboard and 1.70 m nominal platform edge by 0.08 m. It must never project into the platform while the train is moving, and the proxy must not be collidable except in a safely aligned, stationary, doors-open, deployed state. This is a conceptual geometric study only, **not a safe operating design**: there is no train attachment, articulation, deployment, door interlock, alignment tolerance handling, emergency control, physical strength, pinch-point review or runtime control. Vector and the safety/integration owners must design and approve these before use; do not place either pose into live service.

Reproduce (outputs stay outside the repository to save space):

```sh
blender -b --factory-startup --python-exit-code 1 -P assets/stations/civitas-central/build_boarding_bridge.py -- /tmp/civitas-boarding-bridge
blender -b --factory-startup --python-exit-code 1 -P assets/stations/civitas-central/verify_boarding_bridge.py -- --gltf
```

The second command imports the existing station/train GLBs and generated pose GLBs into Blender at one hypothetical aligned intermediate-car doorway. Along three sample lines and 141 points each across a 0.56 m corridor, the stowed pose leaves 30 support points absent; the deployed pose leaves zero. This is static point sampling, not continuous support, a humanoid crossing, motion envelope or Studio collision verification. The deployed geometry intentionally overlaps existing footboard/platform support at the same height; actual physics handling of overlaps remains untested. It closes the gap **in that test only**, not in the delivered operational train.

## One-module Studio import handoff (not yet performed)

Roblox Studio and a Roblox account are unavailable in this workspace. The closest available check is Blender's independent FBX and GLB reimport of `platform-module.*`: root at zero, 81 Blender meshes, 10 repeated edge/coping/tactile/canopy visuals and one each bench/bin/lamp/gantry, surface and proxy top Y=0, and surface 142.857 × 21.429 studs. This does not establish Studio scale, axes, mesh splitting, collision or appearance.

A Studio operator should import **one** `platform-module.fbx` with unit/axis and scene-origin settings recorded; check the surface measures 142.857 × 21.429 studs and top is at mounting Y=0; inspect the named visual and collision objects and kit count (imported MeshPart count may differ); set visuals non-colliding and proxies anchored/colliding/invisible as appropriate; then walk the length and inspect canopy clearance, tactile detail, material/UVs and clipping. Record import settings, actual hierarchy/counts, dimensions, collision fidelity, route result and screenshots. Do not import both proxy and visual as collidable. Reflection handling is a separate check; the main station's second platform still uses negative scale.
