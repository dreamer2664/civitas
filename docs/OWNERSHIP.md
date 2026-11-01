# FOLDER OWNERSHIP — do not edit outside your lane

| Path | Owner | Others may |
|---|---|---|
| `assets/trains/**` | BLENDER · mason | read |
| `assets/stations/**` | BLENDER · mason | read, request changes via Manager |
| `assets/city/**` | BLENDER · atlas | read |
| `assets/catalogue/**` | BLENDER · atlas | read |
| `src/server/**` | CODE · vector | read, propose patches via PR comment |
| `src/shared/Rail/**`, `src/shared/Gameplay/**` | CODE · vector | read |
| `src/client/**` | CODE · lumen | read |
| `src/shared/Contracts/**` | **Manager A** (changes require a PR + Manager approval) | propose |
| `src/shared/Config/**` | each owner for its own keys, Manager merges | propose |
| `docs/**`, `README.md`, `.github/**` | **Manager A** | propose |
| `tools/**` | whoever adds it, announced in the PR | read |

**Rules**
1. Never force-push `main`. Never commit to `main` directly except Manager A.
2. One agent per file at a time. If you need a file somebody else owns, open a PR comment and say
   what you need — do not edit it.
3. Contracts (`src/shared/Contracts/`) are the integration surface. They are frozen once merged;
   changing one is a cross-team event, not a private decision.
4. Large binaries (`.blend`, `.fbx`, `.glb`) go in the owner's asset folder and must be reproducible
   from a committed script. No unversioned one-off exports.
