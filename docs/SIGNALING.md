# Signalling — Phase 2

Block signalling for Line 1 ("Coastal Spine"): Airport Terminal → Harbour End.

## Signal placement

One stop signal per station, protecting the block from that station to the next.
Aspect logic lives in `src/shared/Rail/Signalling.luau` (pure, unit-testable under
lune). Remote publication via `Signal.Observe` at the fixed 30 Hz tick.

Backpressure per `src/shared/Contracts/RemoteContract.luau`:
`Signal.Observe` — rate 10/s burst 20, maxQueued=1, onOverflow=dropNewest,
muteIfBehind=false.

| Signal ID | Station | Protects block to | distanceStuds |
|-----------|---------|-------------------|---------------|
| L1-S-Airport | Airport Terminal | Hillside Halt | 0 |
| L1-S-Hillside | Hillside Halt | Riverside | 1649 |
| L1-S-Riverside | Riverside | Civitas Central | 3844 |
| L1-S-Central | Civitas Central | Old Town | 5137 |
| L1-S-OldTown | Old Town | Harbour Gate | 6286 |
| L1-S-HarbourGate | Harbour Gate | Container Terminal | 8033 |
| L1-S-Container | Container Terminal | Harbour End | 9521 |
| L1-S-HarbourEnd | Harbour End | — (terminus) | 10652 |

## Aspect rules

- **Red**: the protected block is occupied by any train.
- **Yellow**: the protected block is clear, but the next block ahead is occupied.
- **Green**: all blocks ahead are clear.

A train occupies the block whose `[start, end)` arc-length range contains its
`distanceStuds`. The train's own position counts as occupancy, so signals behind a
train show red for other trains.

## Enforcement

`TrainService.tick()` enforces red signals: when the next signal ahead is red and the
train is within service braking distance, the server applies service brake automatically,
overriding player intent. The train stops precisely at the signal's `distanceStuds`.

## Timetable headway

Minimum headway between departures on the same line: 120 seconds (`Timetable.MIN_HEADWAY_SECONDS`).
The scheduler defers (does not skip) a departure if the previous train on the same line
has not cleared this headway.

| Line | Min headway | Service pattern |
|------|-------------|-----------------|
| Line1 | 120s | one departure every 300s from each terminal |

## Files

- `src/shared/Rail/Signalling.luau` — pure aspect computation
- `src/shared/Config/Signals.luau` — signal placement config
- `src/shared/Config/Timetable.luau` — scheduled departures
- `src/shared/Scheduling/TimetableScheduler.luau` — pure dispatch logic
- `src/server/Services/TrainService.luau` — signal enforcement + publish
- `src/server/Services/TimetableService.luau` — tick-driven dispatcher
- `src/shared/Contracts/RemoteContract.luau` — rate limits + backpressure
