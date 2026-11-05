# City interface integration — Pericles

2026-11-05. Follow-up to the facade collision fix, on `pericles/facade-walkability`.

## Delivered

- `CityInterface.client.luau` now creates a city sign and a map button on start. The existing generated network diagram can be opened by button, M, or gamepad View/Select. The diagram is clearly marked as a non-operational plan. The stock Roblox movement controls are not replaced by an unconnected prototype joystick.
- The map is built when opened and destroyed when closed, with its listeners disconnected. Buttons provide zoom, and the existing drag handler pans. The drag handler now tracks the initiating touch so a second finger cannot hijack or end a drag. Pinch zoom is not implemented.
- Map resize now retains the relative zoom and centre position, within the existing visibility clamp. Label decluttering suppresses labels that overlap other labels or station markers, or extend beyond the canvas; zooming can reveal more. The text-width estimate is conservative, not a measurement of Roblox's font.
- `tools/world/render_interface.py` makes desktop and landscape-phone concept images from the existing city concept and network source. They approximate the interface; they are not screenshots, do not reproduce all Roblox effects/badges/underground styling, and cannot verify actual text metrics or input. The first phone concept had overlapping station labels; the revised version suppresses conflicting labels. This is sufficient for a provisional preview, not evidence of production-quality visual polish.

## Verification and limits

`tools/verify.sh` passes: 125 Lune tests (including label and resize tests), seven city acceptance checks, formatting, lint, strict analysis, network and enum checks, regenerated city concepts, and Rojo place build. The map interaction and visual components are not covered by those pure tests. Studio is required for live GUI rendering, gamepad focus, touch drag, dynamic resize, label metrics, respawn, streaming, and movement-control interaction. The platform kit and train are still not integrated, and this is not a completed railway game.

## Next

Import the place in Studio and use the updated `PLAYTEST.md` interface checklist. Resolve the Central station datum/footprint with the city plan before attaching platforms and railway infrastructure. Implement an authoritative train service and a complete operating/passenger loop; the network diagram must remain labelled provisional until real routes and services exist.
