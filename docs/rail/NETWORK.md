# CIVITAS Railway Network — Phase 1

**Status:** PROPOSED by CODE · vector. Coordinates are in studs in the frame defined below.
**Pending:** `docs/world/WORLD-MAP.md` (BLENDER · atlas) does not exist yet, so this document
**defines its own coordinate frame**. When atlas's map lands, convert coordinates to it and note
the change here.

## 1. Coordinate frame (provisional)

- Origin (0, 0, 0): centre of District A — Historic City Centre (site of Civitas Central).
- X axis: east, Z axis: south, Y axis: up. Units: studs.
- World bounds: X in [-5000, 5000], Z in [-4000, 4000] (10,000 × 8,000 studs; MASTER-DIRECTIVE §2).
- Districts (provisional footprints, pending atlas):
  - A Historic Centre: X [-1500, 1500], Z [-1500, 1500]
  - B Modern Business: X [2000, 4200], Z [-3200, -200]
  - C Residential: X [-2800, 600], Z [1400, 3600]
  - D Industrial Harbour: X [2600, 4800], Z [1000, 3400]; harbour edge (coastline) at Z ≈ 3800
  - E Airport & Outer Suburbs: X [-4600, -900], Z [-3400, 200]

## 2. Lines — 3 passenger lines, 14 stations

Line 1 — "Coastal Spine": Airport Terminal ↔ Harbour End (through C and A; central interchange at
Civitas Central). Express + local stopping patterns are a Phase 2 timetable concern.

Line 2 — "Business Cross": Civitas Central ↔ Exchange (A → B; interchange with Line 1 at Central).

Line 3 — "Residential Branch": Riverside ↔ Lakeside (entirely in C; diverges from Line 1 at
Riverside).

Stations (X, Z = studs; type = section the station sits on):

| # | Station | Line(s) | District | (X, Z) | Section |
|---|---------|---------|----------|--------|---------|
| 1 | Airport Terminal | 1 | E | (-4200, -1800) | ground |
| 2 | Hillside Halt | 1 | E | (-2600, -1400) | ground |
| 3 | Riverside | 1, 3 | C | (-1100, 200) | ground |
| 4 | Southgate | 3 | C | (-200, 1000) | ground |
| 5 | University Hill | 3 | C | (400, 2200) | ground |
| 6 | Lakeside | 3 | C | (-600, 3000) | ground |
| 7 | Civitas Central | 1, 2 | A | (0, 0) | underground |
| 8 | Old Town | 1 | A | (900, 700) | elevated |
| 9 | Harbour Gate | 1 | D | (2500, 1400) | ground |
| 10 | Container Terminal | 1 | D | (3600, 2400) | ground |
| 11 | Harbour End | 1 | D | (4400, 3200) | ground |
| 12 | Civic Plaza | 2 | A/B | (800, -800) | underground |
| 13 | Tower Station | 2 | B | (2400, -1800) | underground |
| 14 | Exchange | 2 | B | (3400, -2600) | elevated |

Z sign note: Civic Plaza at Z = -800 lies north of the centre, toward District B.

## 3. Track geometry (provisional waypoints, studs)

Line 1: (-4200,-1800) (-3400,-1600) (-2600,-1400) (-1800,-600) (-1100,200) (-400,400) (0,0)
(500,300) (900,700) (1600,1000) (2500,1400) (3100,1900) (3600,2400) (4000,2800) (4400,3200)

Line 2: (0,0) (400,-400) (800,-800) (1400,-1200) (2400,-1800) (2900,-2200) (3400,-2600)

Line 3: (-1100,200) (-500,700) (-200,1000) (200,1600) (400,2200) (-200,2600) (-600,3000)

These waypoints feed `src/shared/Rail/Spline.luau` control points (Catmull-Rom interpolates
them). Section types per segment are ground unless listed below.

## 4. Junctions (3)

| Junction | Location (X, Z) | Lines | Section | Notes |
|---|---|---|---|---|
| J1 Central throat | (0, 0) | 1 ↔ 2 | underground | Crossover/interchange under Civitas Central; the central interchange |
| J2 Riverside divergence | (-1100, 200) | 1 ↔ 3 | ground | Level divergence where Line 3 leaves Line 1 |
| J3 Harbour depot siding | (3800, 2700) | 1 ↔ depot | ground | Facing-point siding into Harbour Depot |

## 5. Depot

**Harbour Depot** at (4100, 3000), District D, connected via siding J3 off the Line 1 section
Container Terminal → Harbour End. Stabling for ~8 trains; light maintenance only in Phase 1.

## 6. Section types

- **Underground:** Civitas Central, Civic Plaza, Tower Station; tunnels Central ↔ Civic Plaza
  (under District A) and Old Town → Riverside (under the A/C boundary).
- **Elevated:** Old Town station; Exchange station; viaduct Exchange ↔ Tower Station over District
  B streets; embankment Harbour Gate → Container Terminal.
- **Ground:** everything else (Airport Terminal, Hillside Halt, Riverside, Harbour Gate,
  Container Terminal, Harbour End, all Line 3 stations).

## 7. Diagram (schematic, not to scale)

```
Z (south)
^
|  District B (business)          District D (harbour)
|    13 Tower u                   9 Harbour Gate
|   /                             |
| 12 Civic u      7 Central u-----8 Old Town e    10 Container
|   \        |   /   \             |               |
|    (Line 2)|  /  Line 1          | (Line 1)      11 Harbour End
|     14 Exchange e      \        |               (coast Z~3800)
|                          \      |
|                           \     v
|   District A (historic)    1---+---- Line 1 spine ----> X (east)
|        (0,0)  7 Central u
|
|  District C (residential)
|   4 Southgate   5 University Hill
|      \           /
|       (Line 3)  |
|        6 Lakeside
|
|  District E (airport & suburbs)
|   1 Airport Terminal   2 Hillside Halt
|
+-------------------------------------------------->
```

Key: `u` = underground, `e` = elevated, plain = ground. `---` Line 1, `~~~` Line 2, `...` Line 3
(conceptual; see waypoint lists in §3 for exact geometry).

## 8. Notes

- 14 stations (within the 12–16 target), 3 lines (within the 2–3 target), central interchange
  (Civitas Central), 3 junctions, 1 depot, mixed elevated/ground/underground — matching
  MASTER-DIRECTIVE §3.
- Express/local stopping patterns, timetable adherence and block sections are Phase 2 service
  scheduling/signalling concerns, not network geometry.
- When `docs/world/WORLD-MAP.md` exists: restate this section against atlas's coordinates and
  delete this frame-definition note.
