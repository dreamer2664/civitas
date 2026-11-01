# RESOURCES — study yours before you produce anything

Every agent must read its own section **and** the "all agents" section, then write a short
`docs/reports/<agent>-phase1-report.md` that proves it read them: quote at least five specific facts
and say how each one changes your plan. A report that could have been written without opening the
links will be sent back.

## All agents
- Roblox Creator Documentation — the whole site is the spec of the engine:
  https://create.roblox.com/docs
- Luau language basics and types: https://create.roblox.com/docs/scripting
- Performance, design for performance (draw call and triangle budgets):
  https://create.roblox.com/docs/performance-optimization/design
- Improve performance (streaming, LOD, SLIM, memory):
  https://create.roblox.com/docs/performance-optimization/improve
- Instance streaming properties and script patterns:
  https://create.roblox.com/docs/workspace/streaming/techniques
- Rojo (file-based workflow, this repo's build system): https://rojo.space/docs/v7/
- Community/marketplace rules for anything you download: https://create.roblox.com/docs

## BLENDER · mason (trains + station architecture)
- Blender manual (start at modelling, then UV, then materials):
  https://docs.blender.org/manual/en/latest/
- Roblox Importer — supported formats, presets, transform, pivots, "Set Pivot to Scene Origin",
  "Anchored", LOD and collision settings: https://create.roblox.com/docs/studio/importer
- Meshes in Roblox — MeshPart, SurfaceAppearance for PBR, collision fidelity, LOD:
  https://create.roblox.com/docs/parts/meshes
- Roblox mesh requirements and limits — **read the size/triangle limits before modelling**:
  https://create.roblox.com/docs/art/modeling/specifications
- Reference study, not to copy: real EMU/DMU cab ergonomics, platform heights, bogie proportions,
  pantograph geometry. Any photo you work from must be recorded with its source in `assets/trains/README.md`.
- Deliverables must be reproducible headless: `blender -b file.blend -P tools/export_*.py`.

## BLENDER · atlas (city + asset research)
- Roblox Importer and Meshes (as above) — you will assemble thousands of instances, so pay attention
  to LOD, collision and instancing rather than to hero-level detail.
- Creator Store (Roblox's own asset library): https://create.roblox.com/store
- Performance budgets and streaming — your job is where a big city either flies or dies:
  https://create.roblox.com/docs/performance-optimization/design
- Instance streaming techniques: https://create.roblox.com/docs/workspace/streaming/techniques
- Urban reference: study real European coastal cities for street grids, block sizes, building
  heights, harbour edges, station approaches. Record every reference URL in
  `assets/catalogue/REFERENCES.md`.
- **Asset vetting is mandatory.** For any downloaded model: open it, list its scripts, read them,
  check for `require` of remote assets, HTTP calls, obfuscated code, `loadstring`; record asset id,
  creator, licence and your verdict in `assets/catalogue/ASSETS.md`. Suspicious → reject and say why.

## CODE · vector (server, railway systems)
- Luau type system and strict mode: https://create.roblox.com/docs/luau
- Remote events/functions security — server authority, validation, rate limiting:
  https://create.roblox.com/docs/scripting/events/remote
- DataStore, session locking, `UpdateAsync`, retries, and binding to close:
  https://create.roblox.com/docs/cloud-services/data-stores
- Instance streaming implications for server and client scripts:
  https://create.roblox.com/docs/workspace/streaming/techniques
- Parallel Luau / actors, and when **not** to use them: https://create.roblox.com/docs/scripting/multithreading
- Tooling: `selene`, `stylua`, `luau-lsp`, `lune` (unit tests outside Roblox):
  https://github.com/Kampfkarren/selene · https://github.com/JohnnyMorganz/StyLua ·
  https://github.com/JohnnyMorganz/luau-lsp · https://lune-org.github.io/docs
- Railway domain: signalling block principles, timetable recovery margins, braking curves. Cite what
  you adopt in `docs/DECISIONS/train-movement.md`.

## CODE · lumen (client, UI, progression, economy)
- All Roblox UI classes and their performance characteristics:
  https://create.roblox.com/docs/ui
- Input across keyboard, gamepad and touch (ContextActionService, UserInputService, touch UI):
  https://create.roblox.com/docs/input
- Client-server boundary and what replicates: https://create.roblox.com/docs/scripting/events/remote
- Streaming-aware client code (nothing distant exists): https://create.roblox.com/docs/workspace/streaming/techniques
- Mobile performance reality check: https://create.roblox.com/docs/performance-optimization/improve
- Design references: real transit signage systems (London Underground, DB, SNCF), departure boards,
  cab desk layouts. Record references in `src/client/UI/REFERENCES.md`.
- No default Roblox GUI look. Typography, spacing, colour and motion must come from an art bible that
  you and BLENDER · atlas agree on.
