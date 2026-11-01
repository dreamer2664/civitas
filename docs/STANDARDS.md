# STANDARDS — code, commits, evidence

## Luau
- `--!strict` on every new module. No `any` unless the boundary genuinely is dynamic — and then it is
  validated immediately.
- One ModuleScript per system, PascalCase filenames for modules, camelCase for locals/functions.
- Services live in `src/server/Services` and expose an API table; no cross-service reaching into
  another service's internals.
- Remotes: names in `RemoteContract`, validated server-side, rate-limited per player.
- Errors: `error()` with a message a stranger can act on; no silent `pcall` swallowing.
- No `wait()`; use `task.wait`. No unbounded `while true do` without a documented exit.
- Comment **why**, not what. A 200-line module with no comment explaining its model is rejected.

## Formatting and static analysis
- `stylua` formatting (config committed), `selene` clean, `luau-lsp analyze` clean before a PR.
- Unit tests with `lune` for anything pure: splines, scheduling, scoring, validation.

## Blender assets
- `.blend` source committed **plus** a non-destructive build/export script.
- Metres, real-world scale, +Y up in Blender → Roblox expects studs: **1 m = 3.571 studs** at
  Roblox's default 0.28 m/stud; document the conversion used, per asset.
- Named pivots, applied transforms, clean UVs, materials named by purpose, tri budget declared.
- Collision: a separate simplified mesh, not the render mesh.
- Every asset folder contains `README.md`: purpose, dimensions in studs, tri count, materials,
  collision strategy, licence/originality statement.

## Commits
- `<area>: <what changed>` — e.g. `rail: add spline sampling + tests`, `assets/trains: EMU body blockout`.
- One logical change per commit. No "wip", no "fix", no "update files".
- Every PR body states: what it does, how it was verified (exact commands + output), what it does
  **not** do, and what it needs from another agent.

## Evidence rule
A deliverable is not done because you say it is. Attach the command and its output:
```
$ selene src/            → 0 errors, 0 warnings
$ luau-lsp analyze ...   → 0 diagnostics
$ lune run tests/run     → 42 passed, 0 failed
$ blender -b … -P tools/build_train.py → tri=48,213 files=14
```
Honest limits are required and are not penalised: "no Studio, so multiplayer is unverified" is a
correct statement; "tested in Studio" is impossible and a lie.

## What gets a PR rejected on sight
Broken scripts · unverified free models · placeholder art presented as final · CPU work in a
per-frame loop without justification · a new 5,000-part model with no streaming story · touching a
file you do not own · a contract change without Manager approval · inflated progress claims.
