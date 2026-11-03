# lumen — Phase 1 technical report

Status: proposal, 2026-11-01. Nothing in this report is a claim of Studio testing, multiplayer testing, or on-device testing. No Roblox Studio or Roblox account is available to this agent. Sources were read on 2026-11-01; the Roblox doc pages are dated by their own `last_updated` fields (2026-10-30).

## 1. Resources read: facts and what they change

1. **[Position and size](https://create.roblox.com/docs/ui/position-and-size):** "Scale values represent a percentage of the container's size … additive of any Offset values." Studio also infers `UDim2` from a bare number (`0.5` → Scale, `20` → Offset).
   *Change:* every layout is resolved as `scale × parentPx + offset`. I will put that resolution in a pure function with lune tests for phone portrait, phone landscape, and desktop sizes, rather than tuning pixel offsets by eye. Bare-number inference is banned in our code; every `UDim2` is written explicitly.

2. **[Size modifiers and constraints](https://create.roblox.com/docs/ui/size-modifiers):** `UISizeConstraint` and `UIAspectRatioConstraint` "will override the layout" when they sit on an object under a layout structure. `UITextSizeConstraint`: "Do not use `MinTextSize` values lower than `9`."
   *Change:* a given element gets either a layout parent or a constraint, never both. Text is clamped with `UITextSizeConstraint` (phone minimum 12, body 14 px-equivalent) so that scaled text cannot become unreadable on a small screen.

3. **[On-screen UI containers](https://create.roblox.com/docs/ui/on-screen-containers):** `ScreenGui.ScreenInsets` defaults to `CoreUISafeInsets`, "recommended if the ScreenGui contains interactive UI elements"; `None` is for "non-interactive content like background images". Also: `ResetOnSpawn` defaults to `true`, and "Disable default UI" via `StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.…)`. Touch devices get a virtual thumbstick and jump button; `GuiService.TouchControlsEnabled = false` hides them.
   *Change:* every interactive ScreenGui uses `CoreUISafeInsets`. The decorative cab backdrop alone uses `None`. Persistent HUD containers set `ResetOnSpawn = false`. Default Health and Backpack are disabled. The default thumbstick stays on for on-foot play and is turned off in the cab, where the train controls use the thumb zones instead.

4. **[Mobile input](https://create.roblox.com/docs/input/mobile):** "By default, Roblox games run in landscape mode"; `ScreenOrientation` offers `LandscapeSensor`, `Sensor`, `Portrait` and two landscape locks. `UserInputService.PreferredInput` (`Touch`, `Gamepad`, `KeyboardAndMouse`) "changes based on … the player's most recent interaction with a connected gamepad or keyboard/mouse."
   *Change:* menus and the map must work in portrait, so the orientation is `Sensor` rather than a lock. The cab is landscape-first. Input glyphs and prompts are driven by a pure `InputMode` function of `PreferredInput`, not by checking `TouchEnabled`, which would be wrong for a phone with a Bluetooth gamepad attached.

5. **[Streaming techniques](https://create.roblox.com/docs/workspace/streaming/techniques#script-patterns):** "Indexing into `Workspace` descendants with the `.` operator throws an error if any instance in the path isn't currently streamed in." `FindFirstChild` returns `nil` in the same situation. The docs give the same failure for a character's descendants: `character.Humanoid` indexed directly inside `CharacterAdded` fails, because the character is parented before its children have streamed in.
   *Change:* no UI code caches a Workspace instance at startup, as ARCHITECTURE rule 4 requires. Station and map data comes from `Config` tables and Remotes, keyed by ID. Interaction prompts resolve their target at the moment of use and tolerate `nil`. The map never scans the world.

6. **[Design for performance](https://create.roblox.com/docs/performance-optimization/design#scripting):** "At 60 FPS, the total budget for each frame is 16.67 milliseconds … If a piece of code takes 100 ms … and you run it every frame, your game can only run at 10 FPS." It also says "Don't store everything in ReplicatedStorage. The client loads everything that is in this container."
   *Change:* map construction is chunked across frames with a time budget (`task.wait()` between chunks). Nothing does layout per frame. Client-only UI code stays under `StarterPlayerScripts`; ReplicatedStorage only receives the small pure modules that both sides need.

7. **[Improve performance: network](https://create.roblox.com/docs/performance-optimization/improve#networking-and-replication):** "Server-side TweenService … the tweened property is replicated to each client every frame." and "for a character's state, replicate it when it changes rather than every frame."
   *Change:* all UI motion is client-side only. I will ask vector for train telemetry that is pushed on change and at a capped rate; the client interpolates between samples (see §3).

8. **[Improve performance: load times](https://create.roblox.com/docs/performance-optimization/improve#load-times):** "Defer non-essential startup work — Load content that a player hasn't reached yet, such as UI panels they haven't opened, only when it's first needed."
   *Change:* the map, progression, and station panels are built on first open and are not built at join time.

9. **[Input Action System](https://create.roblox.com/docs/input/input-action-system):** an `InputAction` is mapped to several hardware inputs through child `InputBinding`s, and its read-only `PreferredBinding` "returns the child `InputBinding` best matching the player's current input device."
   *Change:* this is the right long-term model for cab controls on keyboard, gamepad and touch. Phase 1 still keeps a plain, pure binding table that the UI reads, because the cab action list depends on vector's controls, which are not settled. Migration to the Input Action System is a Phase 2 decision, recorded here so it is not forgotten.

10. **Font enumeration (verified against the official Roblox API dump, `Enum.Font`):** `BuilderSans`, `BuilderSansMedium`, `BuilderSansBold`, `BuilderSansExtraBold`, `RobotoCondensed`, `RobotoMono`, `Roboto`, `Arimo` and `ArimoBold` are present.
    *Change:* the typography is built on these. `GothamBold` and `GothamMedium` are rejected because they are the default-looking Roblox type the directive warns about. Because the enum name is confirmed, a Studio glyph check for European characters (é, ü, ß, ø) is the remaining question, and I list it as unverified.

Sources for facts 1–10 are the URLs above. The API dump is `https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/Full-API-Dump.json`, a community mirror of Roblox's API. I will verify enum and property names against it with a committed script (`tools/check_enums.py`), not from memory.

## 2. Proposed design, and the alternatives rejected

**Architecture.** The client is thin. Four layers, each with one job:
- `Input/` — pure device-mode and binding tables.
- `UI/` — theme tokens, pure layout maths, components. Components are plain factory functions that return `Instance`s. They hold no game state.
- `UI/Map/` — map model and projection (pure), and the Roblox view.
- `Controllers/` — one per feature, the only layer that touches Remotes. Phase 1 creates none. I will not add empty stubs.

Pure modules (no `game`, no `Instance`, no `task`) are the only code that carries a rule, and each has a lune test. This follows ARCHITECTURE §6 and the standards' "anything with a rule in it belongs where a test can reach it."

**Visual identity: "Civitas Signal".** Graphite and ink surfaces; warm off-white for signage text; a muted signal palette (proceed green, caution amber, stop red, info blue) that is never neon. Corner radius is 4 px, which reads as signage, not toy UI. Borders are 1 px hairlines, not drop shadows. Spacing is a 4-point grid. The UI spec states the full token set, and I will reconcile it with atlas's art bible when that is committed.

**Typography.** `RobotoCondensed` for signage and headings. `BuilderSans` for body and labels. `RobotoMono` for times, speeds and timetable digits, because monospaced digits do not jitter when values change. This is a decision for legibility, not decoration.

**Rejected alternatives:**
- *Roact or Fusion.* Rejected for Phase 1. ARCHITECTURE specifies plain Luau UI, a third-party dependency would be replicated, and the reactive binding it buys is not needed yet. Trade-off accepted: manual updates. Revisit if the screen count grows past about ten.
- *Default Roblox GUI styling.* Rejected by directive. Default grey `TextButton`s and Gotham type are exactly the look the directive forbids.
- *Pixel-offset layouts.* Rejected. Scale-first layout with `UIAspectRatioConstraint` and `UIScale` for phone portrait, so one design holds across screen sizes.
- *Map as a pre-rendered image.* Rejected for Phase 1. The network will change as lines are added, and a baked image cannot be tested or regenerated from data. Cost: many small `Frame`s. Mitigation: a hard element budget (≤ 300 map elements), built lazily, hidden when closed.
- *Map from Workspace (CollectionService scan of stations).* Rejected. It breaks under streaming (§1 fact 5) and it is a scan of the whole city, which ARCHITECTURE rule 4 forbids. The map reads the network data table.
- *Full-rate train telemetry to the client.* Rejected. The cab needs fresh-looking numbers, not 60 Hz server traffic. The client interpolates from change-driven samples.
- *Using the Input Action System now.* Deferred to Phase 2 (§1 fact 9).

**Screen set (detail in the UI spec):** main menu; pause and settings; train cab HUD (landscape-first); passenger HUD; station panel; map; progression; wallet and transactions; world interaction prompts; notifications. Navigation: a single router with a stack, a back action on every platform, and gamepad focus order defined per screen.

## 3. Interfaces I need, named concretely

**From CODE · vector (RailContract / RemoteContract):**
- *Cab snapshot* (server → owning driver only), change-driven plus a rate cap of 10 Hz. Fields: `speedMps` (SI, the client converts to km/h or mph), `throttleNotch`, `brakeNotch`, `emergencyBrake`, `reverser` (-1, 0, 1), `doorsOpen` per side, `signalAspect` for the next signal, `nextStopId`, `distanceToNextStopM`, `speedLimitAheadMps`, `timetableDeltaS`, `destinationText`, `hornActive`. Units and sign conventions must be agreed in the PR.
- *Network data* — `MapData` (see the schema in `UI-SPEC.md` §8): lines (`id`, `colourToken`, polyline of world XZ points), stations (`id`, `name`, XZ position, `interchange`), junctions and depot nodes, and a segment kind (`surface`, `elevated`, `underground`) for dashed rendering. This should come from `docs/rail/NETWORK.md`, which is not yet in the repository. Until it arrives I use a clearly labelled test fixture.
- *Station departures* (StationContract, proposed): a list of `{serviceId, lineId, destinationId, scheduledS, expectedS, platformId}` for each station, sent when the player opens the panel, plus a change push.

**From CODE · vector (Economy / Progression, proposed in `docs/contracts/proposals/`):**
- `Wallet` snapshot and transaction result; `FareQuote` before a purchase; progression snapshot with rank, XP to next rank, unlocks and achievement IDs. The server is authoritative; the client only displays and sends intent.

**From BLENDER · atlas:** the art bible (palette, typography, signage style, colour temperature), district names and map coordinates from `docs/world/WORLD-MAP.md`, and icon style. I will reconcile my tokens with theirs in a PR comment. I have not seen their art bible in the repository yet.

**From BLENDER · mason:** dimensions of the in-world destination display aperture (SurfaceGui size and aspect ratio), so that the destination and platform sign text fits. Mason's report already asks lumen for this.

**From the Manager:** a ruling on the default `ScreenOrientation` (I propose `Sensor`), the disabled default core GUI list, and the proposal folder (see §4).

## 4. File plan (exact paths)

Created in Phase 1, all under lumen ownership unless noted:
- `docs/reports/lumen-phase1-report.md` (this file)
- `docs/ui/UI-SPEC.md`
- `docs/contracts/proposals/README.md`, `EconomyContract.proposed.luau`, `ProgressionContract.proposed.luau` — the proposals live under `docs/` (Manager-owned) rather than `src/shared/Contracts/`, so that no Manager file is touched. On ratification they move into `src/shared/Contracts/`.
- `src/client/README.md` (replace placeholder text)
- `src/client/UI/REFERENCES.md`
- `src/client/UI/Theme.luau`, `src/client/UI/Layout.luau`
- `src/client/UI/Components/Button.luau`, `Panel.luau`, `SignText.luau`, `Meter.luau`
- `src/client/UI/Map/MapModel.luau`, `MapProjection.luau`, `MapView.luau`
- `src/client/Input/InputMode.luau`
- `tests/run.luau`, `tests/harness.luau`, `tests/client/*.spec.luau`, `tests/fixtures/network-sample.luau` (fixture only, labelled as not game data)
- `tools/install-tools.sh` (pinned toolchain, already created), `tools/verify.sh`, `tools/check_enums.py`
- `.luaurc` at repo root (for luau-lsp; shared with others — announced in the PR)

No file under `src/server/`, `src/shared/Rail/`, `src/shared/Gameplay/`, `assets/`, or `src/shared/Contracts/` is touched.

## 5. Risks, and the one most likely to go wrong

- **Unverified visuals.** Nothing I build will have been seen on a screen. Layout maths tests prove the arithmetic, not that the result looks right. Mitigation: a written spec with measured spacing and touch sizes, and a checklist for the Manager's device-emulator pass.
- **Glyphs and fonts.** The font names are verified; coverage of European diacritics in each font is not. Place names (Mühlbach, Søndergård) would render as boxes if a font lacks them. Unverified until Studio.
- **Contract drift.** If vector ships cab fields with different units or names, the cab breaks silently. Mitigation: the proposal freezes names and units before implementation, and the fields are checked by a validation test on the client side.
- **Phone cab ergonomics (most likely to go wrong).** The default thumbstick and the throttle and brake controls compete for the same thumb zones in landscape. I cannot touch-test. The spec gives explicit thumb zones and sizes (minimum 48 px targets), but this is the item most likely to need redesign after Manager device testing.
- **Draw calls and elements.** The map, the cab and the station panel all create many small `Frame`s. Mitigation: element budgets, lazy construction, and hiding closed panels with `Enabled = false`. Measured draw-call counts are unverified.

## 6. What I will not do in Phase 1

- No Remotes, no server calls, no economy or progression logic. Those wait for vector's contracts.
- No finished screens, only the spec and the reusable components. No clickable prototype.
- No icons or image assets. Atlas or mason supply them; until then the UI uses type and shape, not placeholder art presented as final.
- No audio.
- No claim that anything works in Studio, on a phone, or in multiplayer. Those tests belong to the Manager.
- No edits to `src/shared/Contracts/`, `src/server/**` or any asset folder.

## 7. Requests to the Manager for acceptance

1. Confirm the proposal folder (`docs/contracts/proposals/`) until ratification.
2. Rule on the default `ScreenOrientation` and the disabled core GUI list (§2, fact 3).
3. Confirm that `tools/` may hold `verify.sh` and `check_enums.py`, announced in the PR.
