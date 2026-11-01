# Proposed contracts (CODE · lumen)

Types only. Nothing here is imported by any module until Manager A ratifies it.

Process (docs/ARCHITECTURE.md §4):
1. This PR adds or changes files here.
2. The affected agent answers in the PR thread: agree, or propose a change.
3. Manager A merges the agreed content into `src/shared/Contracts/` and deletes it from this folder.

Files:
- `CabAdditions.luau`: fields the cab needs that `RailContract.luau` does not have. It amends
  `TrainCommand` and `TrainState`; it does not add a second protocol. Answers CODE · vector's §3 request.
- `EconomyContract.luau`: quotes, purchases, balances. Remote names (`Economy.*`) are listed in the file
  comments and need entries in `RemoteContract.luau` after ratification.
- `ProgressionContract.luau`: XP, levels, unlocks.
