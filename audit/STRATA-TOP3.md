# WALK · pave — top-three strata merge follow-ups

Strata merge PR: https://github.com/dreamer2664/civitas/pull/5
**PR #5 is already merged**, at main `5a5deeb`. Treat this as a post-merge follow-up,
not a request to edit or re-open that historical merge. World source is `c015646`.

## Coverage delivered

`audit/PARKS.json`: all 50 parcels, all 64 original grid cells exactly once, all four
explicitly declared superblocks with matching names and cell memberships; zero missing or
unexpected. Three actual public squares are included. `audit/meanGrade-summary.md` is the
canonical table. meanGrade is physical slope %, not a quality score: every certified
support face is horizontal (0%); steps and obstacles are evaluated separately. We do not
claim every parcel's free-space connectivity from that statistic or invent semantic parks.

There are no detected >0.5-stud gaps, >1.2-stud steps, or base holes in the current WALK
geometry audit. The three follow-ups below are ranked by acceptance impact, NOT meanGrade.
No defect is fabricated merely to fill a top-three list.

## 1 — P0: land the real rear pedestrian exits in main

**Main still has the monolithic StationRearWall.** Verified in main `5a5deeb` after PR #5:
`src/server/World/CityBuilder.luau` creates one rear wall; station config lacks rear exits.

- Blocked sidewalk centres: **x=103.25 and x=136.75**, tested z **[961.25,969]**.
- Existing wall solid: x **[42,198]**, z **[962.25,970.25]**, y **[0,19]**.
- WALK fix already implemented/published: two real **7-wide / 8-high** openings at those x
  centres, retaining three collidable piers and two collidable headers, no rescue ground.
- Clear openings: x **[99.75,106.75]** and **[133.25,140.25]**, y **[0,8]**.
- Carry the current `walk/audit` station builder/config/recipe changes into a follow-up
  merge. Keep both the upstream pocket-square count and the +4 facade-part count; blindly
  cherry-picking the older recipe can lose one side of that arithmetic.
- Verification: direct real Lune audit must show **70 sidewalk pieces clear / 162 crossings
  clear**, actual/estimated **1924/1924 parts**, route **1632.999280** studs. Do not disable
  wall collisions or exclude these coordinates from the audit.

Evidence: `docs/reports/walkability-lune-results.json`, `walkability-live-results.json`,
World source diff on `walk/audit`, and the actual-geometry route render.

## 2 — P1: integrate a spawn with a demonstrable landmark view

- Actual current spawn: **(136.75,-640)**. At an assumed 4.5-stud eye offset, **0 of 17 tested
  Crown/Lantern rays** across 12 landmarks are clear. This does not prove all pixels are
  invisible or simulate the camera.
- Example target: Old Town Clock Tower Lantern **(-570,130.8,-375)**. First blocker:
  `BuildingMassing.Block 25 Plot 3-1.UpperMassing`, hit
  **(-74.250008,43.013492,-560.884327)**.
- Chosen, geometry-verified but **unapplied** candidate: **(136.75,-512)** on the same actual
  sidewalk. It retains **1504.999280 studs** of clear route and two clear landmark-anchor
  rays to Civic Archive Tower. Plan: `src/server/Spawn/RecommendedPlan.luau`.
- Integrate the spawn/entry marker and camera bearing; ensure streamed support before
  releasing the character. Keep the >=1500-stud route gate. A Manager-run engine test must
  verify first-frame grounding and visible landmark framing; headless rays cannot do that.
- Coordinate World marker integration with WALK-owned Spawn; do not carve massing to fake
  visibility or claim the existing runtime spawn has already moved.

Evidence: `walkability-spawn-sightlines.csv/json` (every target/blocker/hit),
`walkability-spawn-candidate.json`, and the pure RecommendedPlan module.

## 3 — P2: remove collision from 291 confirmed facade details

- **57 each** DisplayWindow_Left, DisplayWindow_Right, RecessedShopDoor; **60 each**
  EntryLintel and RecessedDoor are collidable over solid building massing.
- Example: `Block 64 Plot 3-2.DisplayWindow_Right`, centre
  **(578.576660,5.800003,552.474976)**, dimensions **(9.520004,4,0.350006)**.
- Update the owning facade helper for these five detail classes only. Preserve collision
  on simplified building massing, canopies/awnings, ground and meaningful street furniture.
- Do not claim this reduces part count or GPU calls: it fixes collision policy. Actual
  draw calls remain unmeasured. Rerun body/crossing/ground gates after changing flags.
- Evidence: `docs/reports/walkability-collision-defects.csv`, all **291 exact IDs/coordinates**.

## Reproduction / remaining limits

`bash tools/walkaudit/verify.sh` runs all unit tests, real builder export, independent
geometry checks, full-parcel grade inventory, streaming sweep, static analysis and Rojo
build. Geometry passes, but the combined pipeline still exits 1 for the actual spawn's
unresolved anchor gate. No Studio, physics, rig, device, camera or GPU test is claimed.

For mobile, profile **min 64 / target 384** (650-part continuous envelope) rather than
assuming configured target 1024's 1921-part envelope fits a 1000-call budget. These are
geometric residency/main-pass proxies, not measured engine draw calls.
