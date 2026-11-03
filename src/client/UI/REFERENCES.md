# UI references (CODE · lumen)

Where each design or engineering choice in `src/client/UI/` and `src/client/Input/` comes from. Every
Roblox claim here was read from the Creator Hub page listed, on 2026-11-01. Pages marked *partial* were
only read in part; the rest is not relied on.

## Roblox Creator Hub (read)

| Topic | URL | Used for |
|---|---|---|
| UI overview | https://create.roblox.com/docs/ui | GuiObject types; Position, Size, AnchorPoint, ZIndex; layout structures (*partial*: chunk 0 of 2) |
| On-screen containers | https://create.roblox.com/docs/ui/on-screen-containers | `ScreenInsets` default `CoreUISafeInsets`; `ResetOnSpawn`; `Enabled` behaviour |
| Position and size | https://create.roblox.com/docs/ui/position-and-size | Scale is additive to Offset, so `Layout.resolve` is tested in `lune` (*partial*: chunk 0 of 3) |
| Size modifiers and constraints | https://create.roblox.com/docs/ui/size-modifiers | `UITextSizeConstraint` (minimum must not go below 9), `UIAspectRatioConstraint` |
| UI animation / tweens | https://create.roblox.com/docs/ui/animation | Tween scale-based `UDim2` targets |
| 9-slice design | https://create.roblox.com/docs/ui/9-slice | Read in full. Not used in Phase 1 (decision D1 in UI-SPEC) |
| Input | https://create.roblox.com/docs/input | `UserInputService.PreferredInput` drives prompt choice |
| Input Action System | https://create.roblox.com/docs/input/input-action-system | `InputContext`, `Priority`, `Sink`; mapping of `Bindings.luau` (*partial*: chunk 0 of 6) |
| Mouse and keyboard | https://create.roblox.com/docs/input/mouse-and-keyboard | Generic `InputBegan`; `PreferredInput` changes with last device (*partial*) |
| Gamepad | https://create.roblox.com/docs/input/gamepad | Common control schema (ButtonA accepts, ButtonB cancels, triggers for primary actions); haptics via `HapticEffect` (*partial*: chunk 0 of 2) |
| Mobile | https://create.roblox.com/docs/input/mobile | Five orientation modes; default `LandscapeSensor`; `Sensor` chosen (UI-SPEC §6) (*partial*: chunk 0 of 2) |
| Streaming techniques | https://create.roblox.com/docs/workspace/streaming/techniques | Direct Workspace indexing fails if not streamed in; `FindFirstChild` returns nil; rule 4 |
| Performance: design | https://create.roblox.com/docs/performance-optimization/design | 16.67 ms frame budget; memory limits on low-end mobile |
| Performance: improve | https://create.roblox.com/docs/performance-optimization/improve | Chunk large trees; avoid server-side TweenService |

Local copies (`.md` versions) were fetched to `/tmp/civ` during the session and are not in the repository.
*Unread:* list-flex-layouts, text-filtering, appearance-modifiers (downloaded, not yet read).

## Standards and external specifications

| Source | Used for |
|---|---|
| WCAG 2.x relative luminance and contrast ratio (W3C) | Every contrast figure in `Theme.luau`, `tests/client/theme.spec.luau` and UI-SPEC §4. Text 4.5:1; non-text 3:1 |
| WCAG 1.4.1 Use of colour | Rule that colour is never the only signal (UI-SPEC §4) |
| Unicode code point ranges (Basic Latin U+0020–U+007E, Latin-1 Supplement U+00A0–U+00FF) | The claimed glyph coverage in `FontCoverage.luau`. Ranges are standard; the claim that each Roblox face covers them is not measured (UI-SPEC D17, Q9) |

## Repository documents

| Document | Used for |
|---|---|
| `docs/ASSET-INTERFACES.md` and `src/shared/Contracts/GeometryContract.luau` (Manager, ratified) | Car dimensions for the cab layout (UI-SPEC Q7) |
| `docs/reports/vector-phase1-report.md` (on `main`) | Client input and dashboard fields requested by CODE · vector (§3). Answered in `src/shared/Contracts/Proposed/CabControl.luau` (contract branch `lumen/contract-proposals`) |
| `docs/ARCHITECTURE.md` | Seven rules; contract-first workflow; budgets |
| `docs/RESOURCES.md` | Roblox pages assigned to CODE · lumen |
| `docs/STANDARDS.md` | Luau style, commit rules, evidence rule |

## Not relied on

- The `Font` set in `Theme.type` is the Roblox built-in family. Its names are checked against the Full API Dump; the look is
  not checked in Studio.
- Glyph coverage of BuilderSans and Roboto: no Roblox page publishes it, and an unofficial search returned no coverage
  table. The claim in `FontCoverage.luau` is therefore unverified.
- Platform touch-size figures (44 pt, 48 dp) in UI-SPEC D9 are general guidance, not re-read this session.
