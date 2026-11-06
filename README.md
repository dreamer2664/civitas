# PROJECT CIVITAS

> **Current continuation — Norman, 6 Nov 2026:** experimental two-stop automatic shuttle, second halt, live service UI and executed-geometry Blender review. [App report](docs/reports/norman-app-report.md) · [Playtest](PLAYTEST.md) · [Updated handoff](deliverables/norman/README.md). Not Studio-tested or release-ready. Older Pericles reports and root deliverables are historical.

A large-scale passenger railway simulator with a walkable, semi-open-world city, built for Roblox.

- **Game**: **CIVITAS**.
- **Setting**: **Civitas** — an original fictional European coastal metropolis. Target footprint
  ~10,000 × 8,000 studs.
- **Core loop**: operate passenger trains · travel as a passenger · explore the city on foot ·
  work railway jobs · progress and unlock.
- **Organisation**: 1 Manager (Manager A) + 4 specialist agents.
- **Source of truth**: this repository. Screenshots are not deliverables; source files are.

## Start here
| Document | What it settles |
|---|---|
| [`docs/MASTER-DIRECTIVE.md`](docs/MASTER-DIRECTIVE.md) | The Director's full specification. Overrides everything else. |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Repo layout, Roblox DataModel layout, module boundaries, agreed interfaces. |
| [`docs/OWNERSHIP.md`](docs/OWNERSHIP.md) | Who owns which files. Read before you edit anything. |
| [`docs/STANDARDS.md`](docs/STANDARDS.md) | Luau style, commits, evidence, review gates. |
| [`docs/RESOURCES.md`](docs/RESOURCES.md) | Curated links per discipline. Study yours before producing work. |
| [`docs/PHASE-1.md`](docs/PHASE-1.md) | The current milestone and exactly what each agent owes for it. |

## Experimental rail test

A separate, isolated test place and Studio checklist live in [`prototypes/rail/README.md`](prototypes/rail/README.md). It is a server-controlled driving prototype with procedural placeholder geometry, not an integrated railway or evidence of a Studio playtest.

## The team
| Agent | Discipline | Owns |
|---|---|---|
| **BLENDER · mason** | Senior 3D artist & train specialist | `assets/trains/`, `assets/stations/`, railway structures |
| **BLENDER · atlas** | Environment artist & asset researcher | `assets/city/`, district assembly, asset catalogue |
| **CODE · vector** | Senior Luau gameplay engineer | `src/server/`, `src/shared/Rail/`, `src/shared/Gameplay/` |
| **CODE · lumen** | Senior Luau client & systems engineer | `src/client/`, UI, progression, economy |
| **Manager A** | Manager | `docs/`, `src/shared/Contracts/`, integration, review |

## Ground truth about this environment — read before promising anything
There is **no Roblox Studio and no Roblox account** in an agent sandbox. Agents cannot press Play,
cannot publish, and cannot import meshes themselves. Therefore:
- Code is verified by **static analysis and unit tests** (`selene`, `luau-lsp analyze`, `lune`), plus
  `rojo build` producing a valid `.rbxlx` place file.
- Models are verified by **headless Blender** (renders, mesh statistics, manifold/tri validation) and
  by the `.blend` plus exported `.fbx`/`.glb` being reproducible from a committed script.
- **The Manager performs the Studio import and the multiplayer test** on a machine that has Studio.
  Agents hand over reproducible inputs and honest limits — never a claim of "works in Studio".

Anyone who reports "tested in Studio" is lying, and it will be caught.
