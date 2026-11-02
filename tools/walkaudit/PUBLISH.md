# Manual-sweep bundle delivery

Branch: `walk/audit`. No token is stored or required for this delivery.

## Current artifacts

* `/home/user/walk-audit-7a12330.bundle`: original checkpoint, 995099 bytes, created with
  `git bundle create /home/user/walk-audit-7a12330.bundle origin/main..walk/audit` before edits.
* `/home/user/walk-audit-sidewalk-fix.bundle`: updated committed branch, including the real
  rear doorway repair and fresh evidence. Same `origin/main..walk/audit` range.

Both are current deliverables, not stale backups. The old generic `walk-audit.bundle` and
stale patch are removed after replacement verification. Git bundle verify must succeed.

Restore in a repository containing the public main prerequisites:

```sh
git fetch origin main
git bundle verify /home/user/walk-audit-sidewalk-fix.bundle
git fetch /home/user/walk-audit-sidewalk-fix.bundle refs/heads/walk/audit:refs/heads/walk/audit
git switch walk/audit
bash tools/walkaudit/verify.sh
```

Do not force-update an existing unrelated branch. Use a fresh destination branch if needed.
With working authentication, the manager can publish `git push -u origin walk/audit`.
The earlier supplied token was rejected; do not paste credentials into chat or source files.

The 53 regression tests pass. Both direct real-geometry commands now exit 0 (48 sidewalks,
162 crossings clear), but the combined pipeline still exits 1 on the actual spawn's
untouched tested-anchor sightline gate. Do not skip that gate to claim full acceptance.

Tool executables are relocated into excluded cache with small ~/bin symlinks. verify.sh
uses bootstrap_tools.py to fetch exact, SHA-256-pinned versions if the cache was omitted by
a snapshot. The missing-cache path was tested. An unrelated dirty Blender installer is
excluded from WALK commits; preserved restored files remain in a local stash.
