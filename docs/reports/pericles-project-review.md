# Civitas — Pericles review and handoff

Review date: 2026-11-05. Baseline: main `eaad19c`. This is a partial delivery, not a completed game.

## Current state

Civitas is a Roblox passenger-rail and walkable-city project. The repository currently contains a deterministic District A historic-core blockout, a placeholder station shell, an EMU-1 train model, a platform kit, shared rail maths, and client UI components. The place file contains scripts; the server builds the city at runtime. The world plan reports 302 ordinary buildings, 12 landmarks, a 1,633-stud acceptance route and 1,920 estimated parts. These are generated-plan measurements, not live Studio measurements. The placeholder station has no integrated rails or platforms. The train and platform models are assets, not proof of a functioning service in the place.

## Work delivered in this pass

- Facade overlays built by `facadePart` (windows, door cues, lintels and awnings) no longer collide or participate in queries. The underlying building mass remains collidable; door cues remain visual, not openings. This addresses the facade portion of WALK-005, not the entire decorative audit.
- Added `tools/world/check_facade_collision.py` to the verification pipeline. It statically checks the helper and the seven known facade call sites; it is not a runtime physics test.
- Updated the playtest guide to distinguish this partial fix from the outstanding audit.
- Rebuilt and reviewed the existing three generated city concept renders. They are useful evidence of the current blockout, but the city views are sparse, boxy and not production-quality; they should not be mistaken for final Roblox art. The existing train and platform renders show simple model assets, not integrated gameplay. The collision change has no intended visual difference, so a render cannot validate it.

## Verification

`bash tools/verify.sh` passed on 2026-11-05: formatting, lint, type analysis, network/enums/streaming and facade static checks; 122 Lune unit tests; seven city acceptance checks; plan export, three concept renders and a Rojo place build. Tool versions: luau-lsp 1.70.1, Selene 0.32.0, Lune 0.11.1, Rojo 7.7.1, StyLua 2.6.0. Roblox API dump SHA-256: `334a77ca58d9562851fabfa61086a61c170adc01d01097af5fb7b9dc3ddb4648`.

No Roblox Studio, live collision or humanoid traversal, multiplayer, import, mobile performance or streaming test was performed. Automated plan clearance does not establish any of those.

## Highest-priority remaining work

1. Import and playtest the place in Studio, walk the entire documented route and measure collision, streaming and mobile performance. Verify facade snagging is gone and audit other decorative objects (WALK-005).
2. Resolve the city/station footprint, elevation and rail datum mismatch (issue #4 / station PR #6); integrate an actual station, platforms and track and prove access to them (WALK-006).
3. Implement and integrate the end-to-end server-authoritative railway loop and client controls; test passenger boarding, operating, services and multiplayer. Existing maths and art assets do not establish a complete playable railway.
4. Resolve spawn landmark sightlines (WALK-007). Expand city beyond District A, and add traffic, crowds, jobs, progression and the other planned districts.
5. Develop production-quality architecture, street furniture, environment and lighting, and make in-engine renders. Existing Python city images are diagrams/concepts, not Studio screenshots. Audit all sourced assets and licences before integration.

Consult `PLAYTEST.md`, `docs/MASTER-DIRECTIVE.md`, `docs/ARCHITECTURE.md`, and open issues/branches before scheduling or merging further work. Completion requires substantial additional implementation and a real Studio test environment.
