# UI-SPEC — Civitas Signal interface

Owner: CODE · lumen (Agent 4). Status: **Phase 1 draft, provisional**. Maintained with
`src/client/UI/Theme.luau`, which is the source for every token quoted here. If this document and
the code disagree, one of them is a bug, and the test that should have caught it is named in §14.

**Verification status, stated once:** nothing in this document has been seen running in Roblox Studio,
on a device, or on a screen. Layout maths, colour maths, formatting, navigation and bindings are
tested with `lune`. Roblox-side components are type-checked only. Every visual claim below is
a design intent until the Manager checks it in Studio on a baseline phone (§13).

---

## 1. Principles

1. **Railway first.** The interface reads like railway information: departure boards, signal
   aspects, platform signs, dial gauges. It is not a game HUD.
2. **Grounded modern European.** Quiet surfaces, one typeface family for words, one condensed face
   for signs, one mono face for numbers. No neon, no glow, no cartoon proportions, no oversaturated colour.
3. **Information before decoration.** Every colour, shape and motion carries a meaning or it is removed.
4. **Never colour alone.** Each status is also written as text, shown as a shape, or shown as a number.
5. **Three inputs are first-class.** Keyboard, gamepad and touch each reach every action (§7). The
   game must work on a phone, in both orientations for menus and in landscape for the cab.
6. **The server decides.** The client shows the last state the server sent and sends requests that may be refused (rule 1, rule 2).
7. **No Workspace references.** UI reads network data from the client's own modules, never from Workspace instances,
   because streaming can remove them (rule 4). Screens tolerate missing data and show "no data", not stale numbers.

## 2. Visual language (provisional — reconcile with BLENDER · atlas)

The art bible that BLENDER · atlas is writing is **not on any branch as of 2026-11-01** (checked on
`origin/main` `8b6bae1`, `origin/mason/emu-1` `66f7044`, `origin/vector/rail-core` `aaf3e2b`). This section is my
draft. Reconcile in a PR comment when it lands; where it conflicts, the art bible wins for world art and this
section is amended for UI.

- **Dark, low-glare default.** Interfaces sit on a dark ink base because a cab interior is dim. Light
  surfaces are not offered in Phase 1.
- **Sign panels** use a deep slate-teal `sign` with warm white `signText`, the enamel-sign convention
  of European rail. Sign text is condensed and set in capitals for destinations.
- **Hairlines, not bevels.** Panels are flat fills with a 1 px `hairline` border and a 6 px radius.
  Controls use 4 px. Sign panels use 2 px, the sharpest corner, because signs are rectangular.
- **No gradients, no drop shadows, no glow.** The only depth cue is a fill change (`raised`, `pressed`).
- **Iconography:** none in Phase 1. Labels are text. Icons arrive with the art bible, not before.
- **Not a default Roblox look.** Every component sets its own fill, font and border. No
  `Frame` is left with the engine default fill or font.

## 3. Typography

Font faces are the Roblox built-in families. Each token maps to an `Enum.Font` through the explicit
table in `UI/Style.luau`; a face that is not in that table fails in `tests/` and in `tools/check_enums.py`.

| Token | Face | Size (px) | Used for |
|---|---|---|---|
| `display` | BuilderSansExtraBold | 36 | main menu wordmark only |
| `title` | BuilderSansBold | 24 | screen titles |
| `heading` | BuilderSansMedium | 18 | section headings, card titles |
| `body` | BuilderSans | 16 | body text, option descriptions |
| `label` | BuilderSansMedium | 14 | buttons, chips, tab labels |
| `caption` | BuilderSans | 12 | smallest permitted text; units, hints |
| `sign` | RobotoCondensed | 22 | station and destination signs |
| `signLarge` | RobotoCondensed | 40 | platform numbers |
| `numXL` | RobotoMono | 56 | cab speed readout |
| `numL` | RobotoMono | 28 | throttle and brake numeric readouts |
| `numM` | RobotoMono | 18 | departure times |

Rules:
- Numbers that change every frame or every second use the mono face, so digits do not jitter.
- Minimum text size is **12 px** (`Theme.size.minTextSize`). Roblox documents values below 9 as unreadable; 12 is the
  floor chosen for legibility on a phone. Every text object styled through `Style.applyType` gets a `UITextSizeConstraint` with
  `MinTextSize = 12` and `MaxTextSize = 72`.
- Text is never shorter than its meaning. Truncation is avoided by wrapping or by a larger container, not by an ellipsis on a
  safety-relevant word such as "STOP" or "EMERGENCY".
- Sentence case for labels; capitals only for sign text and status words in the cab.

## 4. Colour

All colours are in `Theme.palette` (hex, no `#`). Contrast ratios below were computed with the WCAG 2.x
relative-luminance formula and are re-checked by `tests/client/theme.spec.luau`.

| Token | Hex | Role |
|---|---|---|
| `ink` | 0E1216 | behind everything; world shows only through a dimmed backdrop |
| `surface` | 161C22 | panels |
| `raised` | 1F262E | cards, buttons at rest |
| `pressed` | 29323C | pressed and selected rows |
| `hairline` | 3A4550 | 1 px borders; decorative only |
| `text` | EEF1F3 | primary text |
| `textMuted` | AEB8C1 | secondary text. 6.45:1 on `pressed` |
| `textFaint` | 949FA9 | captions and units. 4.82:1 on `pressed`, 5.67:1 on `raised` |
| `accent` | 5B8DB8 | platform blue: **fills and focus rings only, never text** |
| `accentText` | 84ADD2 | the same blue lightened for text. ≥ 5.08:1 on every surface |
| `proceed` | 4E9A6B | signal green: running normally, on time |
| `caution` | D9A441 | signal amber: late, restriction ahead |
| `stop` | D46B5E | signal red: emergency, door fault, danger. 5.43:1 on `ink`, 4.96:1 on `surface` |
| `sign` | 1E3A46 | station sign panel |
| `signText` | F3EFE4 | warm white on sign. 10.45:1 on `sign` |

**Why `accent` is not used for text:** 5B8DB8 measures 4.86:1 on `surface` but 4.33:1 on `raised` and
3.68:1 on `pressed`, which fails 4.5:1. The lighter `accentText` is used wherever blue carries words.

**Line colours (network map only).** Six colours, in `Theme.lineColours`. Each line is also identified by
a text code (for example "A1") in ink on the line colour. Badge text is ink on every line colour at ≥ 5.07:1.
Every line colour reaches ≥ 3:1 against `surface` for the line stroke.

| Line | Hex | Ink-on-colour ratio |
|---|---|---|
| teal | 2A9696 | 5.28 |
| ochre | C99A2E | 7.29 |
| plum | B47BAF | 5.72 |
| slate | 5C8AC8 | 5.30 |
| brick | C46E5E | 5.14 |
| moss | 6F8F3A | 5.07 |

**Rule: status colours never appear beside a line.** `proceed`, `caution` and `stop` are reserved for signals,
the cab and alerts. Brick is close to `stop`, so the map never shows a status colour next to a line, and
the cab never shows a line colour as a status.

**Colour is never the only signal.** Signal aspect in the cab is a word plus colour. Throttle and brake show a
notch number as well as lit segments. Delay shows "+4 min" as well as a tone.

## 5. Space, shape, size, motion

- **Space** (`Theme.space`, 4 px grid, enforced by tests): 4, 8, 12, 16, 24, 32, 48.
- **Radius:** sign 2, control 4, panel 6.
- **Sizes:** hairline 1, focus ring 2.
- **Touch targets:** smallest tappable control **48 px** (`touchMin`) on any device; cab controls and primary actions
  **56 px** (`touchComfort`). Controls below the minimum grow to it; they never shrink below design size.
- **Motion** (`Theme.motion`, seconds): instant 0, fast 0.12, base 0.2, slow 0.32. Easing Quad Out.
- **Reduced motion** (Settings → Motion) sets every duration except `instant` to 0. It is read through
  `Style.duration`, so components cannot bypass it.
- Motion is client-side only. No server-side TweenService: it replicates every frame (performance guidance in
  `docs/RESOURCES.md`). Tweens target scale-based `UDim2` values so layouts stay resolution-independent.

## 6. Layout and responsive rules

**Viewport classes** (`Layout.classify`, measured on the **short side**, so a phone is a phone in both orientations):

| Class | Short side | Layout |
|---|---|---|
| phone | < 500 px | single column menus; cab uses thumb zones |
| tablet | 500–799 px | two-column menus; cab panels at edges |
| desktop | ≥ 800 px | side panels; cab dashboard across the top |

**Orientation.** `StarterGui.ScreenOrientation = Sensor`, so the device may be held either way. Menus, Settings,
Map, Station and Progression support **portrait and landscape**. The cab is designed for **landscape**: in portrait
the cab shows a single card, "Turn your phone sideways to drive", with a Menu button. The cab never runs in portrait.
(§14, D5.)

**Safe area.** Every `ScreenGui` uses `ScreenInsets = CoreUISafeInsets`, which is the recommended value for
interactive UI. Background-only layers may use `None`. Core UI is not hidden; `GuiService.TouchControlsEnabled` stays
`false` in the cab so the default thumbstick does not compete with the thumb zones.

**Anchoring rules.**
- Position and size use `UDim2` with **Scale** for proportional layout and **Offset** only for fixed minimums
  (`touchMin`, `touchComfort`, hairline). Scale and Offset add on each axis, so `Layout.resolve` is the single place
  that resolves them in tests.
- Text blocks use `AutomaticSize = Y` only; cards with fixed structure use fixed sizes. (Intent; not yet set by any component.)
- Sign panels hold their proportion with `UIAspectRatioConstraint`, not by hard-coded sizes.
- Padding and spacing are tokens (§5), never literals.

**Cab thumb zones** (`Layout.cabThumbZones`). The bottom 45 % of the safe area is the control band; each thumb owns 40 %
of the width at its edge, leaving the centre clear for the view.
- Left thumb: reverser (up, down), horn, doors.
- Right thumb: throttle, brake, emergency.
- Worked example: 844 × 390 landscape phone, with the given insets, gives a 2 × 2 grid of cells 146 × 79 px. Every cell
  is above `touchComfort` (56 px). This is tested in `tests/client/layout.spec.luau`.

**Gutters.** `Layout.gutter` returns a phone, tablet or desktop gutter from the spacing tokens; the caller chooses the value.

## 7. Input

Input is written once as data in `src/client/Input/Bindings.luau` and read by the Roblox layer. Contexts:
`cab`, `onFoot`, `menu`. Conflicts are checked only inside a context, because Escape means "pause" on foot and "back" in menus.

The Roblox side maps each context to an `InputContext` with an `InputAction` per action (the Input Action System, which
Roblox recommends for cross-platform bindings). Cab and on-foot contexts use the normal priority. The `menu` context
is the one that **sinks** Escape and ButtonB while a menu is open, so a menu cannot leak a press into the cab.
This mapping is a design intent until it is run in Studio (§13).

| Action | Keyboard | Gamepad | Touch control | Context |
|---|---|---|---|---|
| Throttle up | W | ButtonR2 | throttle slider | cab |
| Brake service | S | ButtonL2 | brake slider | cab |
| **Emergency brake** | Backspace | ButtonB | red "Emergency" button, 56 px | cab |
| Reverser up / down | Q / Z | DPadUp / DPadDown | "Reverser" up and down | cab |
| Horn | H | ButtonL3 | "Horn" | cab |
| Doors | C | ButtonL1 | "Doors" | cab |
| Map | M | ButtonSelect | "Map" | cab and on foot |
| Pause / menu | Escape | ButtonStart | "Menu" | cab |
| Interact | E | ButtonX | "Interact" | on foot |
| Back (menus) | Escape | ButtonB | back control | menu |

**Safety rules, enforced by `tests/client/bindings.spec.luau`:**
- Every cab action that matters while moving has a binding on keyboard, gamepad and touch.
- The emergency brake is never on Space or Enter, which people press by accident.

**Deliberate deviation.** Gamepad guidance says ButtonB cancels. In the **cab only**, ButtonB is the emergency brake,
because it is the largest, least-accidental face button on a controller. In menus ButtonB still cancels. The conflict
is scoped to a context, so it cannot reach a menu. (D6.)

**Prompts** (`InputMode.promptFor`): the text a player reads depends on the **preferred input**, read from
`UserInputService.PreferredInput` (Touch, Gamepad, KeyboardAndMouse) and changes with the last device used. A prompt
shows "E", "X" or "Interact" as the mode requires. A binding with no label for a mode returns nil, and a missing prompt
fails in tests rather than appearing as an empty label on screen.

**Touch.** Five orientation modes exist; the game uses `Sensor` (§6). Touch-only controls are shown only when
`PreferredInput` is Touch, and keyboard hints are hidden then. Pinch and swipe are not used for anything in Phase 1,
so the map's zoom and pan are the only gesture code, and both have on-screen buttons as well.

**Mouse and keyboard.** Keys are read through the Input Action System. Mouse is used for buttons, sliders and map drag;
the custom mouse icon is not changed in Phase 1.

## 8. Network map

Source: `docs/rail/NETWORK.md`, written by CODE · vector, **not yet present**. The map module accepts only the data shape in
`tests/fixtures/network-sample.luau` until that file lands; the fixture is synthetic and is not game data.

**Rendering convention (assumption, to reconcile with `docs/world/WORLD-MAP.md`):**
- World **+Z is north**, drawn at the **top** of the map. Screen y is flipped against Z, so the map is not mirrored.
- X runs east, left to right.
- Coordinates are studs in the world frame. The frame must be stated in `NETWORK.md` §1 when it lands.

**Content rules:**
- Each line is a list of sections; each section is a list of points (64 maximum). Segments are straight pieces between points.
- Stations: 32 maximum. Names 40 characters maximum; codes 4 characters maximum.
- Limits, all enforced by `MapModel.validate`: 8 lines, 12 sections per line, 64 points per section, 300 drawn elements.
- **Data that fails validation is rejected whole, not truncated.** A partly drawn map would look correct and be wrong. The
  screen then shows "Network map unavailable" with a Close button.
- Underground sections are drawn at **50 % transparency**. This is the only kind distinction in Phase 1.
- The map is built from the network data only. It never reads Workspace, because streaming may have removed the
  geometry (rule 4).

**Build and interaction:**
- Build is chunked under a **4 ms budget per frame** (`os.clock`, `task.wait` between chunks). A map that is still building
  shows a loading state, not a half-drawn network.
- Zoom keeps the point under the pointer fixed and clamps the scale. Pan is clamped so at least a quarter of the view stays
  covered, so the network cannot be lost off-screen.
- The map shows the player's position only once `TrainDisplay` or the on-foot position is available; otherwise there is no
  marker, not a guessed one.

**Accessibility:** each line has its text code; stations have their names as labels; the map has Zoom in, Zoom out and Fit
buttons for players who cannot drag.

## 9. Screens, states and navigation

Each screen lists its states. "Blocked" means the screen needs a contract that is not yet ratified; those screens are
specified here so that the contract request is concrete, and they are not built until the contract exists.

### 9.1 Boot
- **Loading:** wordmark on `ink`, no controls, no text beyond the wordmark.
- **Ready:** replaced by the Main menu.
- **Failed:** message "Could not load Civitas." with **Retry**. No automatic infinite retry.

### 9.2 Main menu
- Options: **Play**, **Settings**, **About**. Wordmark `display`.
- **Ready.** **Joining:** Play shows "Joining…" and is disabled (`Button.setEnabled(false)`). **Join failed:** inline message
  "Could not join. Try again." with Play re-enabled.
- At root, Back does nothing. Escape does nothing at root.

### 9.3 Settings
- Tabs: **Controls**, **Display**, **Motion**. (Audio is Phase 2 and is not designed here.)
- **Controls:** shows the current preferred input and the binding table in §7 for it; Reset to defaults.
- **Display:** text size Standard / Large (applies a scale to the caller's `UITextSizeConstraint` ceilings; the floor stays 12 px).
- **Motion:** Reduce motion on/off. Takes effect at once through `Style.setReducedMotion`.
- Back returns to the screen that opened Settings.

### 9.4 Pause (in-game)
- Opened by Escape, ButtonStart or touch **Menu**. Options: **Resume**, **Map**, **Controls**, **Settings**, **Leave**.
- **Important:** the simulation is server-authoritative, so **the train keeps running** while Pause is open. The pause sheet
  therefore never covers the emergency brake. On a phone it is a bottom sheet of at most half the height. The emergency
  control stays visible and enabled behind it. This is a requirement, not a styling choice (§14, D7).
- Back at the Pause root resumes the game.

### 9.5 Cab dashboard (HUD, landscape)
Elements, in reading order: speed readout (`numXL`, unit `caption`), reverser (F / N / R as text), throttle notch meter and brake
notch meter (each 8 notches, numeric `numL` value), signal aspect chip (word plus colour), next-station sign (`sign`, station code),
destination (`sign`), delay (`Format.delay`, text plus tone), doors state (text), emergency banner.

States:
- **Normal.** All values from the latest `TrainDisplay`.
- **Caution.** Signal aspect `caution`, or delay tone `late`: chip and delay text turn amber; the chip also says "CAUTION".
- **Stop.** Signal aspect `stop`: chip says "STOP" in red.
- **Emergency.** `emergencyBrake = true`: a full-width banner "EMERGENCY BRAKE" in `stop` on `ink`, and every throttle control is
  disabled. The banner does not depend on colour: it is the only full-width text in the cab.
- **Doors fault.** `doorsState = fault`: text "DOORS FAULT" in `stop`.
- **No data.** No `TrainDisplay` for more than **2 s**: values are replaced by "---" and the banner "NO SIGNAL". Stale
  numbers are never shown as current.
- **Portrait.** Replaced by the rotate card (§6).

Values are sent at `displayHz = 10` by the server; the view interpolates nothing in Phase 1 and shows the latest value.

### 9.6 Network map
- Opened by M, ButtonSelect, touch **Map**, or the Pause menu. Pushed on the navigation stack; Back or the same key pops it.
- **Loading:** progress text "Drawing network…" while chunks build.
- **Ready:** lines, stations, badges; Zoom in, Zoom out, Fit, Close.
- **Unavailable:** data failed validation or is absent: "Network map unavailable." with Close.
- **Empty:** a valid network with zero lines is not an error: "No lines yet."

### 9.7 Station board
- Shows the station sign (`signLarge` platform number, `sign` name) and a departure list: time (`numM`), destination (`body`),
  platform, status word (On time, +N min, Cancelled, Departed).
- **Blocked:** needs `StationContract` (not yet proposed by CODE · vector). Specified here so the request is concrete.

### 9.8 Ticket purchase
- Flow: **Choose** from station → **Quote** (price in `numL`, time left "Valid 0:58") → **Confirm** → **Result**.
- Results: **Bought** (balance updated); **Not enough money**; **Quote expired** (re-quote button); **Too many attempts,
  try again shortly**.
- Money is shown from integer minor units through a formatter; the client never does currency arithmetic.
- **Blocked:** `EconomyContract` proposal in `docs/contracts/proposals/`, awaiting ratification. Currency code is an open question (§15).

### 9.9 Progression and toasts
- **XP toast:** "+N XP · reason", queued, at most **two** visible, each 3 s, fades in `base` (instant under reduced motion).
- **Level up:** a card, "Level N", closed with Continue. Focus moves to Continue for gamepad.
- **Progress screen:** level, XP bar with the text "xp / xpToNext", unlocks as a list of at most 200 entries.
- **Blocked:** `ProgressionContract` proposal awaiting ratification.

### 9.10 Interaction prompts (on foot)
- A single prompt near the centre bottom: "E  Board train" (keyboard), "X  Board train" (gamepad), a button "Board train" (touch).
- Shown only when a target is in range. Hidden on any other state. Text comes from `InputMode.promptFor`.

### 9.11 Discovery
- Entering a new area shows "Area explored" as a toast (§9.9), and grants XP through progression. No separate screen.

### 9.12 Client effects
- Out of scope for this spec. Effects are not UI. Any effect that needs a message to the player goes through the toast.

## 10. Navigation model

`UI/Navigation.luau`: an immutable stack of screen ids.
- **Push** a screen; pushing the current top is a no-op; revisiting a screen already in the stack pops back to it, so the stack holds no duplicates.
- **Back** pops one screen. At root it returns `atRoot`, and the caller opens Pause (in game) or does nothing (menu root).
- **Replace** swaps the top, used when a flow finishes (purchase Result → Station board).

Paths:
- Boot → Main menu → **Play** → Cab HUD (driving) or on-foot HUD (walking).
- Main menu → Settings → (Back) Main menu. Main menu → About → (Back) Main menu.
- Cab HUD → Escape / ButtonStart / Menu → Pause → Map / Controls / Settings → (Back) Pause → (Back at root) Resume.
- Cab HUD → M → Map → (M or Back) Cab HUD.
- On foot → E at station → Station board → Ticket → Result → Station board.

## 11. Components (`src/client/UI/Components`)

| Component | Behaviour | Test coverage |
|---|---|---|
| `Button` | touch minimum; focus ring on `SelectionGained`; press tween; `setEnabled` sets `Active` and `Selectable` | logic-only; visual unverified |
| `Panel` | flat `surface` or `raised` fill, hairline border, panel radius | logic-only |
| `SignText` | `sign` panel, `signText` text, aspect-locked | logic-only |
| `Meter` | notch segments from `Gauge.notch`; value from `Gauge.fraction`; numeric readout supplied by caller | `Gauge` pure maths tested |
| `MapView` | chunked build, zoom, pan, destroy disconnects everything | `MapModel` and `MapProjection` tested; view unverified |

Every component reads colour, font and size through `Style` (never literals), has `--!strict`, and exposes `destroy`
where it owns connections.

## 12. Performance and streaming

- **Draw calls.** Proposed UI budget: **≤ 150 GUI draw calls** in the cab on the baseline device, out of the project's
  1,000 total. This is a proposal to be measured in Studio, not a measured value.
- **Triangles.** UI is 2D and adds no triangles.
- **Memory.** No images in Phase 1, so no texture memory for UI. Low-end phones run out of memory first (`docs/RESOURCES.md`),
  so the UI avoids large text buffers and long lists in the cab.
- **Frame time.** Map build is capped at 4 ms per frame. The 16.67 ms frame budget is shared with the world.
- **Streaming.** UI never caches Workspace instances at startup and never indexes Workspace directly (rule 4). Anything that
  looks up world objects uses tags or `CollectionService` and tolerates stream-out.
- **Lists.** Long lists (unlocks, departures) are capped and paged; they are not rebuilt every frame.

## 13. Accessibility and verification boundary

- Text contrast: 4.5:1 minimum for text; ≥ 3:1 for non-text graphics such as line strokes and focus rings (enforced by tests).
- Text size: 12 px floor; `UITextSizeConstraint` on text styled through `Style.applyType`; the Display setting scales the ceiling (not yet built).
- Motion: reduced-motion switch; no flashing; no motion is needed to read any status.
- Touch: 48 px minimum, 56 px for cab controls.
- Input: every action on three devices (§7), with the deliberate ButtonB deviation recorded.

**What has been verified, and how:**

| Claim | Evidence | Status |
|---|---|---|
| Tokens meet contrast rules | `lune run tests/run.luau` (theme spec) | verified, 85 of 85 tests pass in the last run |
| Layout maths, breakpoints, thumb zones, touch minimums | `lune` (layout spec) | verified in maths only |
| Bindings complete and conflict-free within contexts; safety rules | `lune` (bindings spec) | verified in data only |
| Roblox names exist (Enum.Font, KeyCode, classes) | `tools/check_enums.py` against Full-API-Dump | verified, 85 references checked |
| Roblox code type-checks | `luau-lsp analyze --definitions` strict | verified, 0 diagnostics |
| Place file builds | `rojo build` | verified |
| Any control works in Studio, on a device, on screen | — | **not verified**. No Studio, no device. |
| Visual look, legibility at 12 px, touch feel | — | **not verified** |

**Needed from the Manager:** a Studio pass on one baseline phone in both orientations, one landscape tablet and one
desktop. Specifically check the cab at 844 × 390, the 48 px and 56 px controls by thumb, and the emergency banner.

## 14. Decisions log

Each decision states what was chosen, why, and what was rejected. Decided here, not deferred, as directed.

| ID | Decision | Why | Rejected |
|---|---|---|---|
| D1 | Flat frames with a hairline; **no 9-slice images** in Phase 1 | No art assets exist yet. Flat frames have no image dependency and cannot look like the default Roblox skin. 9-slice is the right tool once the art bible supplies panel art (`docs/RESOURCES.md`). | 9-slice image panels now: needs assets that are not on any branch. |
| D2 | All values are tokens in pure modules; components read through `Style` | Keeps the written spec and the running code from drifting; lets `lune` test contrast. | Literals in components: review rejection. |
| D3 | Low-saturation palette; `accent` for fills only; `accentText` for text | 5B8DB8 fails 4.5:1 as text on raised and pressed surfaces. | Keeping one blue for both: fails contrast. |
| D4 | Status colours never beside lines on the map | Brick line colour sits near `stop`; a status colour next to a line reads as a service status. | Free use of the palette on the map. |
| D5 | Orientation `Sensor`. Menus and map work in both. The cab is landscape only, with a rotate card in portrait. | Menus and map must work on a phone in both orientations; the cab needs width for thumb zones. | `LandscapeSensor` only (a phone held upright would show a sideways game with no portrait layout); `Portrait` (cab unusable). |
| D6 | Emergency brake is ButtonB in the cab only; ButtonB stays Back in menus | ButtonB is the largest face button and hard to press by accident. The conflict is scoped to a context, so it cannot reach a menu. | ButtonL1 (doors); a shoulder button (pressed as often as throttle and brake). |
| D7 | The Pause sheet never covers the emergency control; the train keeps running while Pause is open | The simulation is server-authoritative; a menu that hides the brake would be a safety defect. | A modal pause that blocks the cab. |
| D8 | Text floor 12 px | Legibility on a phone at arm's length. Roblox calls values below 9 unreadable. | A 9 px floor (the platform minimum). |
| D9 | Touch minimum 48 px; cab comfort 56 px | Above common platform guidance (general figures of 44 pt on Apple and 48 dp on Android, not re-checked against a source this session), with the larger size for the controls players press while moving. | 44 px: at the edge of comfortable thumb use in a moving cab. |
| D10 | Reduced motion sets durations to 0 through `Style.duration` | One switch, read everywhere, so no component can bypass it. | Per-component settings. |
| D11 | No server-side UI tweens | They replicate every frame. | Server tweens for HUD. |
| D12 | "NO SIGNAL" after 2 s without `TrainDisplay`; never stale numbers | A dashboard showing old speed looks current and is wrong. | Holding the last value. |
| D13 | Times are 24-hour `HH:MM` | Standard on European railway boards. | 12-hour clock. |
| D14 | Delay within ±60 s is "On time"; above 300 s is `severelyLate`; exactly 300 s is `late` | Matches the tolerance most European operators publish; stops the board flickering. | No tolerance band. |
| D15 | Map drawn from network data only, +Z north at the top, data failing validation rejected whole | Streaming can remove Workspace geometry; a truncated map looks right and is wrong. | Reading Workspace; drawing a partial network. |
| D16 | Input through `Bindings.luau` as data, mapped to the Input Action System at runtime | One source for tests and for the running game; Roblox recommends the system; `Sink` prevents menu presses reaching the cab. | Hard-coded `UserInputService` checks scattered in components. |

## 15. Open questions and reconciliation

| # | Question | Owner | Blocks |
|---|---|---|---|
| Q1 | Art bible (`docs/art/` or similar) is not on any branch. Reconcile §2 when it lands. | BLENDER · atlas | §2 only |
| Q2 | `docs/rail/NETWORK.md` does not exist. Map uses the synthetic fixture until it does. Frame must be stated in §1 of that file. | CODE · vector | §8 real data |
| Q3 | `docs/world/WORLD-MAP.md` does not exist. The +Z-north convention in §8 is an assumption. | BLENDER · atlas | §8 convention |
| Q4 | Currency code: one currency for the place, or set per region? The proposal assumes one place currency. | Manager A | §9.8 |
| Q5 | `StationContract` (departures, platform, status) is not yet proposed. | CODE · vector | §9.7 |
| Q6 | Pause and emergency: a `menuDuringCab` context holding only the emergency brake, so the brake works with any menu open. Proposed in this draft; implemented once the Input Action System mapping is verified in Studio. | CODE · lumen | §7, §9.4 |
| Q7 | Cab car dimensions for the dashboard layout are in `GeometryContract` (§4 of `docs/ASSET-INTERFACES.md`, ratified). Not yet read into a layout; the cab layout here does not depend on car size. | CODE · lumen | none |
| Q8 | Notch count 8 (throttle and brake) is a lumen proposal in `CabControl.proposed.luau`. | CODE · vector | §9.5 |

## 16. Change log

- 2026-11-01: first draft, Phase 1 (CODE · lumen). Verification boundary in §13.
