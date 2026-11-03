# Names, merge audit and camera execution status

NAMES.md is binding interim per Manager A. SC-01 is the nearest real plaza to the
arc-length centroid: (200,0.575,75); support/body checks pass and 5/17 tested landmark
anchors are clear. The old runtime spawn has NOT yet moved. SC-02 Harbour is reserved,
unbuilt and disabled; no unsafe distant teleport is implemented.

PR #13 already belongs to lumen. WALK PR **#15** targets main from requested head
**3e37026**, with strata's review explicitly requested in its body and comment. The
shared GitHub author account cannot request itself as a formal reviewer. See
`audit/walk-fixes-pr.json`. WALK has not approved or merged this PR.

Read-only merge watch: `python -u tools/walkaudit/watch_merge.py 15`.
Once an authorized merge is observed, merge main into walk/audit, rerun both main and
WALK verification, and publish the actual main SHA and delta. No post-merge success
is claimed before that happens.

## Before-merge main control

Actual untouched main World modules at eaad19c, measured with the 3e37026 WALK auditor:
1920 parts, 1632.999280-stud route, two blocked sidewalk/width checks, 104 violating curb
return pieces out of 428. Zero of 324 sidewalk-aligned crossings fail. See
`audit/main-before-fixes.json` and its complete log. This is MAIN, not the walk/audit
branch's already-retained rear-door repair.

## Camera pass prerequisite and limits

Ten camera poses are prepared: SC-01 first, then nine positions spanning the ENTIRE
original route, including south start and station concourse. Thus moving the spawn
anchor does not silently reduce route coverage below 1500 studs. Four recipe tests pass.

The renderer refuses final capture unless PR #15 is merged. It produces perspective,
depth-buffered previews of the actual exported main geometry, not screenshots from
Roblox. Every output is labelled HEADLESS / NOT ENGINE. Cylinders are boxed, colours
approximate, no rig/streaming/lighting/mobile simulation. A true ten-frame engine camera
capture still requires Roblox Studio/account access, which WALK does not have.

Prepared poses: `docs/reports/renders/route-stills/camera-manifest.json`.
Reproduction after merged-main audit:
`python tools/walkaudit/camera_pass.py --world docs/reports/walkability-world.json --out docs/reports/renders/route-stills --main-sha ACTUAL_MAIN_SHA`.

## Additional handoff guards

Names are delivered directly to lumen in PR #13 comment 6606868187. CanonicalPlan and
canonical-spawns.json are generated from NAMES.md; no alternate naming authority.
Four naming regressions pass (all four IDs, no false activation, missing district,
unsafe Harbour enabling and centroid-anchor drift); the separate four camera recipe
tests also pass. Neither suite implies an engine camera or runtime-spawn integration.
