# EMU-1 boarding bridge integration

**Scope: vehicle-graph integration only, not operational boarding.** Each car has four independently parented, default-stowed bridge mounts, one per door. The delivered GLB/FBX has eight named `CAR_SIDE_BRIDGE_N_PIVOT` nodes, each directly under its car root and each with separate `..._VISUAL` and `..._COLLISION` meshes. Existing train roots, bogie/axle pivots and door animation are unchanged. These pivots are not animated and no runtime controller, collision gating or safety interlocks are supplied. Do not use as a live boarding solution until vector implements and validates them.

## Dimensions and mounting

`docs/DIMENSIONS.md` is absent in this branch and all fetched origin branches. The available ratified sources, `docs/ASSET-INTERFACES.md` §§1, 3–5 and `src/shared/Contracts/GeometryContract.luau`, were used instead; no shared contract was changed. If `DIMENSIONS.md` exists elsewhere or supersedes them, reconcile before acceptance. Blender uses metres/Z-up; 1 m = 3.5714286 studs, or 0.28 m/stud.

- Each plate/proxy: **1.10 × 0.26 × 0.04 m** (3.929 × 0.929 × 0.143 studs), within the 1.30 m door width.
- Pivots are car-local at each existing door centre, lateral ±1.47 m and height 0.70 m above rail. In default stow the plate top is 0.72 m, inside the fixed footboard; lateral extent is 1.60 m, matching the ratified 3.20 m structural clearance width. Collision proxy must be disabled while stowed/moving.
- For a manually tested deployed pose, move the pivot **0.18 m outward** and **0.04 m upward** in car-local axes; plate top is 0.76 m, flush with the specified platform datum. The deployed outer edge reaches 1.78 m from track centre, beyond the 1.60 m running envelope, overlapping a nominal 1.70 m platform edge by 0.08 m. This projection is permitted **only as a proposed stationary boarding pose**, not as a change to the running envelope; Manager/runtime safety approval is still required. Motion clearance, pinch points and platform interference are untested.
- The existing default stowed pose still has a 0.10 m unsupported gap at the representative station; no claim of runtime gap closure is made.

## Tests and handoff

```sh
CIVITAS_SKIP_RENDERS=1 blender -b --factory-startup --python-exit-code 1 -P assets/trains/EMU-1/build_emu.py
blender -b assets/trains/EMU-1/EMU-1.blend --python-exit-code 1 -P assets/trains/EMU-1/export_emu.py
blender -b --factory-startup --python-exit-code 1 -P assets/trains/EMU-1/verify_vehicle_bridges.py -- --gltf
blender -b --factory-startup --python-exit-code 1 -P assets/trains/EMU-1/verify_vehicle_bridges.py -- --gltf --fbx
```

Blender GLB and FBX reimports checked all 8 mounts and both mesh types in stowed and manually translated deployed poses, including parentage, dimensions and running/deployed extents. It also loaded station and train GLBs and found **0/423 unsupported samples** for one aligned intermediate-car door after manually moving that mount. The default stowed route still has the 0.10 m gap. Sampling is not a swept volume, avatar test, platform-tolerance test or Studio physics verification. The separate prototype FBX cutaway in `assets/stations/civitas-central/VERIFICATION.md` predates mounting and is honestly labeled Blender.

Required before service: vector must implement fail-safe attachment, train-stop and side/alignment detection, deployment/retraction, door and movement interlocks, collision toggling and recovery; prove the plate is retracted and non-colliding before motion. Visual meshes must be non-colliding; imported proxy collision must not be relied on to default safely. Validate variable stop positions, collision overlap, avatar traversal, accessibility and device performance in the Director device session. The station-to-city alignment remains unresolved.

Current audit: 20,452 visual + 396 collision triangles; largest mesh 2,808, zero non-manifold edges. GLB root/bogie/axle and door checks, door/body overlap sampling, pantograph/HVAC, gangway and livery checks pass. LOD1 excludes the stowed plates (concealed inside footboards), and regenerates at 4,070 visual triangles total. Import behavior, runtime physics and device checks remain unverified.
