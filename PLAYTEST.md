# Civitas — Norman's two-stop prototype playtest

**6 November 2026. This checklist has NOT been run in Roblox Studio.**

Open `deliverables/norman/civitas-norman.rbxlx` in Studio, or build from `norman/civitas-integration` using `bash tools/verify.sh`. Older `v0.1-city` release artifacts and the root `deliverables/` files describe historical baselines, not this updated build. The isolated rail-test place is not the integrated city.

## Boot and inspect

- Start one player. Record Studio version, device/emulation mode and Output errors. Expect a generated city count of 10,362 and a separate railway count of 771. These are expected recipe counts, not performance measurements.
- Verify stock walking/jump/camera controls remain available. Test map open/close, pan and zoom; it is a **planned network**, not a live S1 map.
- Check that service/passenger panels hide while the map is open. Walkers see the service board; seated passengers see the alight panel instead. Check portrait and landscape layouts, safe areas and gamepad focus.

## Walk the primary route

World coordinates are studs: X east/west, Y up, Z along the streets. Follow these X/Z anchors on actual surfaces, without teleports:

`(136.75,-640) -> (136.75,20) -> (150,20) -> (200,75) -> (150,130) -> (136.75,130) -> (136.75,810) -> (120,858) -> (120,925) -> (120,1010.5)`.

The planned horizontal route is 1,718.5 studs, not an observed humanoid walk. Inspect sidewalk/road crossings, all diagonal joints, the fountain, station portico clearance, doorway, concourse, ramp and platform seams. Report every snag, visible overlap, unsupported step and streaming pause. Decorative station trims should not collide. Verify roof/lettering appearance in Roblox rather than assuming Blender matches it.

## Walk to West Gardens

From the forecourt, use `(120,810) -> (-450,810) -> (-450,965.5) -> (-450,1000) -> (-450,1010.5)`. The route is separately sampled at 2,328 corridor points; it has not been swept by a humanoid. Check the 1:12-or-shallower ramp, path turns, ground support, canopy clearance and platform edge. Do not walk across the running rail to shortcut the route.

## Ride the automatic service

1. At either platform, wait for S1. It should travel automatically when the driver seat is empty.
2. At a stop, check the 18-second dwell countdown, platform-side door opening, closed offside leaves and enabled passenger prompt. Board as passenger, not driver.
3. Observe departure after door closing and a 1.5-second closing interval. Test actual character carrying as the anchored train pivots. If the seat does not carry passengers reliably, stop and treat transport as broken.
4. On arrival at the other stop, verify the HUD stop name and alight button. Use the button; verify the seat weld releases and the player lands on the **current** platform, not always at Central or in the track.
5. Repeat in both directions with two clients. Test last free seat contention, death, reset, leaving/rejoining, streaming and rapid repeated boarding/alighting requests.
6. Try Roblox's ordinary seat exit while moving. It is not blocked and can bypass the button; document behavior. This prototype does not claim safe physical boarding or protected exit.

The pure simulation used a small docking snap (guarded to 0.6 studs at <=0.12 m/s). Do not interpret that as measured physical stopping accuracy. Door leaves are visual/non-colliding; prompts and seat checks, not physical doors, control admission.

## Drive and hand back

- Only board the driver seat at a stopped, aligned, doors-open platform. Occupied cab means manual control; no cab occupant means automatic service.
- Test throttle, service brake, reverse only at rest, doors only at a stop and emergency track-end intervention. Driver inputs should time out to brake after loss of fresh commands.
- Leave/disconnect/reset the driver at rest and in motion. Verify old commands are cleared, automatic recovery brakes rather than reversing a moving train, and passengers remain attached. Check the status board never presents a stale manual timetable as an automatic arrival prediction.
- With two clients, attempt to drive from outside the seat and spam malformed/non-finite/control/alight requests. Verify no unauthorized position, door or occupancy changes.

## Performance and release gates

Measure actual frame time, memory, draw calls, part stream-in/out and network traffic on a representative ordinary phone and multiple clients. The 11,133 combined recipe parts are **not** a mobile performance result. Confirm script-generated models have suitable streaming behavior. Record screenshots/video and exact source commit, device and failures.

The final station/EMU-1/network integration, loop, signalling, multi-train operation, wider world, progression and persistence are not supplied here. Do not publish as finished. Current assessment: `docs/reports/norman-app-report.md`.
