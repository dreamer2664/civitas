# Norman — inspected render decisions

6 November 2026. All final images were opened in the file viewer and visually inspected.

**Question asked for each: “is this good enough?”** The acceptance level is honest prototype review, not final production artwork or a claim that Roblox runtime works.

| Final image | Observations | Decision |
|---|---|---|
| 01 Central arrival | Train, canopy and new rear station articulation read together. Consistent restrained palette. Sparse ground and simple roof remain obvious. | Accept for prototype; curated |
| 02 West Gardens | Platform-side sign is readable after lowering the camera; tactile strip, canopy and rail datum visible. Surroundings are very empty and the world ends abruptly. | Diagnostic only; excluded from beauty selection |
| 03 Historic core | First camera was obstructed by a blank wall; replaced with a pedestrian-axis view. Street corridor and layered massing now readable. Windows remain crude and side walls blank. | Accept for prototype; curated, not final city art |
| 04 District context | Honest overview reveals repetitive blocks, sparse station approaches and hard map edges. It does not conceal unfinished world scope. | Diagnostic only; excluded from beauty selection |
| 05 Shuttle detail | Door leaf divisions, livery and separate car geometry visible. Very basic glazing/body and no production cab detail. | Accept as geometry detail; curated |
| 06 Central forecourt | Lower camera shows station lettering, retained walking opening, columns and train beyond. Layered walkway intersections still look provisional; interior is bare and dark. | Accept as shell review; curated, not final architecture |
| 07 Service telemetry | Position and speed cycles show both stops and repeated dwells; measured snap caveat and non-runtime label present. | Accept as simulation evidence, separate folder |
| 08 Service interface study | Live board and replacement seated panel shown separately; action remains above stock thumb areas; authority and screenshot limitations labelled. | Accept as layout study only; actual GUI remains untested |

## Rejected iterations and fixes

- Initial physically based sky overexposed geometry; rejected. Replaced with controlled review lighting, and source sRGB colours converted for Blender materials.
- Initial multi-camera Cycles process exceeded the 2 GiB machine memory. Replaced with one camera/process and a reproducible shell runner. All final renders completed successfully.
- Initial street camera obscured useful context with a nearby blank façade. Reframed on the pedestrian route.
- Coplanar overlapping road/sidewalk/route surfaces caused artifacts. Added small deterministic authored surface offsets and reviewed again. These are not proof that every seam is correct in Roblox.
- Initial west-ramp rise/run exceeded 1:12, and a rear-promenade connection entered halfway up the ramp. Replaced with a forecourt path, a west access leg and a 34.5-stud ramp; sampled support/clearance now passes. The first layout was never represented as accepted.
- Added station roof, portico, rear articulation and train wheels to address overly bare shell/blockout presentation; render-only substitutions were not used.

The source geometry remains deliberately visible as unfinished. A flattering render would not justify claiming the game is complete.
