# Publishing the restored WALK checkpoint

Branch: `walk/audit`. All WALK changes are committed, not merely present in a patch.
Public remote: `https://github.com/dreamer2664/civitas.git`.

Push has been attempted before analysis and at checkpoint end. The supplied credential
was rejected by GitHub: `Invalid username or token` (exit 128). Repeating that token cannot
publish the branch. A working repository write credential/connected write-capable session
is the remaining publication requirement. Do not put credentials in a source file, remote
URL or committed script. Revoke the exposed token and configure authentication securely.

## Portable artifacts (workspace root, outside checkout)

* `/home/user/walk-pave.patch`: binary-capable diff of committed WALK work against
  `origin/world/historic-core-blockout` at 329d358. It must be applied on that base, not main.
* `/home/user/walk-audit.bundle`: committed WALK branch history, excluding the already
  published strata ancestry; verify prerequisites with `git bundle verify`.

With working authentication, publish the current local branch:

```sh
cd /home/user/civitas
git push -u origin walk/audit
```

If restoring from the patch in a separate clean checkout instead:

```sh
git fetch origin world/historic-core-blockout
git switch -c walk/audit 329d358
git apply --index /home/user/walk-pave.patch
git commit -m 'walk: integrate headless continuity audit and evidence'
git push -u origin walk/audit
```

The full audit command is `bash tools/walkaudit/verify.sh`. Exit 1 is currently the correct
result: two actual sidewalk axes hit StationRearWall. Do not skip the failing assertions
or replace the output with a fixture pass in order to publish.

An unrelated dirty `assets/trains/tools/install_blender.sh` file is deliberately excluded
from WALK commits and artifacts. Preserved pre-integration World files remain in a local
stash; they were not used to overwrite the authoritative fetched World branch.
