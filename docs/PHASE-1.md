# PHASE 1 — Technical foundation (current milestone)

No large-scale asset production until the architecture is approved. Phase 1 ends when the five
deliverable sets below are merged **and** the Manager has reviewed the reports.

## Everyone owes, first, before anything else
`docs/reports/<agent>-phase1-report.md`, committed and pushed, containing:
1. What you read from `docs/RESOURCES.md` — five specific facts and how each changes your plan.
2. Your proposed design for your area, with the trade-offs you rejected and why.
3. The interfaces you need from other agents, named concretely (not "some data").
4. Your file plan: exactly which paths you will create, so the Manager can confirm no collisions.
5. Your risks and the one thing most likely to go wrong.
6. What you will **not** do in Phase 1.

Deadline: this report is your first push. Nothing else from you is reviewed until it exists.

## BLENDER · mason — train + station architecture
- `assets/trains/EMU-1/` — the first passenger train: cab car + one intermediate car, modelled to
  real scale, `.blend` + export script + `.fbx`/`.glb` + `README.md` with tri counts, dimensions in
  studs, pivot list, collision strategy.
- A modular platform kit: platform edge, coping, tactile strip, canopy bay, bench, bin, lamp, sign
  gantry — each a separate reusable mesh with consistent scale.
- Headless renders (3/4 front, side elevation, cab interior) committed under `assets/trains/EMU-1/renders/`.
- Mesh statistics: tri count per asset, total, and the streaming/LOD story for each.

## BLENDER · atlas — city blockout + asset catalogue
- `docs/world/WORLD-MAP.md`: the 10,000 × 8,000 layout — districts A–E with coordinates, the road
  grid, coastline, terrain boundaries, and where the railway runs.
- `assets/city/blockout/` — a massing blockout of District A only: streets, blocks, sidewalk
  continuity, the central station's footprint and approach. Simple boxes are fine; **correct urban
  logic is not optional**.
- `assets/catalogue/ASSETS.md` — vetted Creator Store candidates (asset id, creator, licence,
  script audit result, verdict) and `REFERENCES.md` — urban reference sources.
- Art bible v0: material palette, building typology per district, colour temperature, signage style.

## CODE · vector — movement prototype + architecture
- `docs/DECISIONS/train-movement.md` — the A/B prototype (spline-driven server movement vs physics),
  measured, with a decision. **This gates the whole railway.**
- `src/shared/Contracts/RailContract.luau` + `RemoteContract.luau` — proposed, not merged until the
  Manager ratifies.
- `src/shared/Rail/Spline.luau` + `tests/rail/spline.spec.luau` — arc-length parameterised spline with
  passing tests (this is pure maths, testable without Studio).
- `docs/rail/NETWORK.md` — 2–3 lines, 12–16 stations, junctions, depot, elevated/ground/underground
  segments, drawn as an ASCII or SVG diagram mapped to world coordinates from atlas's map.

## CODE · lumen — UI architecture + map interface
- `docs/ui/UI-SPEC.md` — screens, states, navigation, typography, colour, motion; consistent with the
  art bible atlas is writing.
- `src/client/UI/` — theming module + a working component set (no default Roblox look), plus the map
  interface rendering the network diagram from vector's `NETWORK.md`.
- `src/shared/Contracts/` proposals for progression/economy interfaces you need from vector.
- A clickable prototype is *not* required; a clean spec plus themed, unit-testable components is.

## Manager acceptance for Phase 1
- All four reports exist, are specific, and reference the resources honestly.
- `docs/DECISIONS/train-movement.md` exists with a measured decision.
- Contracts are ratified and frozen; folder ownership confirmed with no collisions.
- `rojo build` produces a place file containing the blockout, and the Manager records the import
  result in `docs/MILESTONES.md`.
- Performance budget is written down and the blockout is inside it.
