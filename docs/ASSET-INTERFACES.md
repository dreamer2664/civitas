# ASSET INTERFACES — the numbers that let artists and engineers work in parallel

Manager-owned. These are **ratified**: build to them. If one is wrong, propose a change in a PR with
evidence and I will decide — do not silently diverge, because every other agent's work depends on it.

## 1. Units and conversion
- Roblox works in **studs**. We model in **metres** and convert with the engine default:
  **1 m = 3.5714286 studs** (0.28 m per stud). State the conversion in every asset README.
- Rounding: keep full precision in source, round to 3 decimals in documentation.
- Axes: Blender is **Z-up**, Roblox is **Y-up, -Z forward**. Export with an explicit transform
  (FBX: Y-up conversion on) and record it. Never rely on an implicit axis assumption.

## 2. Permanent way (rail)
| Parameter | Value (metric) | Value (studs) |
|---|---|---|
| Track gauge (rail centre to rail centre) | 1.435 m | **5.1257** |
| Rail head width (visual) | 0.07 m | 0.25 |
| Rail top datum | `y = 0` in track space | — |
| Sleeper spacing | 0.60 m | 2.1429 |
| Minimum curve radius (running lines) | 120 m | **428.571** |
| Minimum curve radius (depot/sidings) | 60 m | 214.286 |
| Maximum gradient | 2.5 % | — |
| Track centre spacing (double track) | 3.400 m | **12.1429** |

## 3. Platforms
| Parameter | Value (metric) | Value (studs) |
|---|---|---|
| Platform top above rail top | 0.760 m | **2.7143** |
| Platform edge setback from track centre | 1.700 m | **6.0714** |
| Platform width (island, minimum) | 6.0 m | 21.4286 |
| Canopy underside above platform | 3.2 m | 11.4286 |
| Tactile strip width from edge | 0.60 m | 2.1429 |

## 4. Rolling stock envelope
| Parameter | Value (metric) | Value (studs) |
|---|---|---|
| Body width | 2.850 m | 10.1786 |
| Rail top to roof | 4.100 m | 14.6429 |
| Structural clearance envelope (width × height) | 3.20 m × 4.60 m | 11.4286 × 16.4286 |
| Car length (cab / intermediate) | 21.0 m / 20.0 m | 75.0 / 71.4286 |
| Inter-car gap (coupling face to face) | 0.50 m | 1.7857 |
| Door aperture (width × height), platform side | 1.30 m × 1.95 m | 4.6429 × 6.9643 |
| Door pocket / leaf travel | 1.35 m | 4.8214 |
| Bogie centres from car end | 3.0 m | 10.7143 |
| Wheel diameter (new) | 0.840 m | 3.0 |

## 5. Pivots, origins and ownership
- **Car root pivot**: at rail top level (`y = 0`), on the car centreline, at the **leading** coupling
  face. All car parts are children of this pivot. This is the transform the server drives.
- **Bogie pivot**: at bogie centre, rail-top level. Wheelsets rotate locally.
- **Door pivot**: hinge on the outboard edge; leaf travels inward/outward per the 1.35 m travel above.
- **Kit modules**: origin at the **base centre** of the module, footprint on `y = 0` of the platform
  surface, facing +X along the platform. 4.0 m repeat length = **14.2857 studs**.
- Static architecture (stations, canopies) is anchored and non-colliding on visual meshes, with
  separate simple collision proxies. Rolling stock is unanchored and driven by CODE · vector.

## 6. Who is blocked by what
- **mason** needs 2, 3, 4, 5 → all here. Not blocked.
- **atlas** needs 2, 3, 5 plus the world coordinate frame in `docs/world/WORLD-MAP.md` → it owns that.
- **vector** drives car roots (§5) and reads §2 for the spline; it owns the runtime side.
- **lumen** needs the car/report dimensions in §4 for the cab dashboard layout and door UI.

## 7. Change process
Open a PR touching this file or `src/shared/Contracts/GeometryContract.luau`, state which agents are
affected, and tag me. I merge it or reject it with a reason. Nobody edits these numbers privately.
