"""Read-only PR wait -> untouched merged-main audit -> labelled camera proxies.

Never approves/merges a PR, changes main, or pushes anything. Writes only owned
WALK evidence on walk/audit and a disposable main worktree. WALK verifies/pushes
outputs after completion. --wait observes an authorized merge, it does not cause one.
"""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import urllib.request

ROOT=Path(__file__).resolve().parents[2]
WORK=ROOT.parent/'civitas-main-audit'
EXPECTED_FIXES='3e370261bc8f744464eb64643301e0b2bc5e8e37'


def run(args,cwd=ROOT,check=True):
    return subprocess.run(args,cwd=cwd,check=check)


def output(args,cwd=ROOT):
    return subprocess.check_output(args,cwd=cwd,text=True).strip()


def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path)
    result=importlib.util.module_from_spec(spec);spec.loader.exec_module(result)
    return result


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--wait',action='store_true');args=parser.parse_args()
    if args.wait:
        run([sys.executable,'-u','tools/walkaudit/watch_merge.py','15'])
    url='https://api.github.com/repos/dreamer2664/civitas/pulls/15'
    with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'CIVITAS-WALK-postmerge'}),timeout=20) as response:
        pr=json.load(response)
    if not pr['merged']: raise SystemExit('BLOCKED: PR #15 not merged; no merged-main audit or camera capture claimed')
    if pr['head']['sha']!=EXPECTED_FIXES: raise SystemExit('PR head changed: Manager/strata review of new head required')
    run(['git','fetch','origin','main'])
    main_sha=output(['git','rev-parse','origin/main'])
    run(['git','merge-base','--is-ancestor',pr['merge_commit_sha'],main_sha])
    if WORK.exists():
        # This exact disposable worktree was created by WALK for the saved
        # main-before-fixes control; never delete any other directory/worktree.
        run(['git','worktree','remove','--force',str(WORK)])
    run(['git','worktree','add','--detach',str(WORK),main_sha])
    evidence=ROOT/'audit';evidence.mkdir(exist_ok=True)
    codes={}
    environment=os.environ.copy()
    environment["PATH"]=str(Path.home()/"bin")+":"+environment.get("PATH","")
    for label,command in [('main',['bash','tools/verify.sh']),('walk',['bash','tools/walkaudit/verify.sh'])]:
        log=evidence/f'merged-main-{label}-verify.log'
        with log.open('w') as stream:
            process=subprocess.run(command,cwd=WORK,stdout=stream,stderr=subprocess.STDOUT,env=environment)
        codes[label]=process.returncode
        print('MERGED_MAIN_CHECK',label,'exit',process.returncode,flush=True)
    # The auditor must execute actual main World modules, never substitute WALK source.
    run(['git','diff','--exit-code','HEAD','--','src/server/World'],cwd=WORK)
    reports=WORK/'docs/reports'
    lune=json.loads((reports/'walkability-lune-results.json').read_text())
    streets=json.loads((reports/'walkability-street-fixes.json').read_text())
    live=json.loads((reports/'walkability-live-results.json').read_text())
    sight=json.loads((reports/'walkability-spawn-sightlines.json').read_text())
    before=json.loads((evidence/'main-before-fixes.json').read_text())
    after=dict(mainRevision=main_sha,partCount=lune['partCount'],routeLength=lune['mainRoute']['length'],
        routeDefectCount=len(lune['mainRoute']['defects']),blockedSidewalks=lune['blockedSidewalks'],
        blockedCrossings=lune['blockedCrossings'],failedSidewalkAlignedCrossings=streets['failedCrossings'],
        failedWidths=streets['failedSidewalkWidths'],failedCurbReturns=streets['failedCurbReturns'],
        curbReturnCount=streets['curbReturnCount'],groundSealed=lune['groundSealed'],
        runtimeSpawnClearAnchors=sight['visibleAnchorCount'])
    geometry_pass=all(after[k]==0 for k in ('routeDefectCount','blockedSidewalks','blockedCrossings',
        'failedSidewalkAlignedCrossings','failedWidths','failedCurbReturns')) and after['groundSealed']
    if not geometry_pass or codes['main']!=0:
        raise SystemExit('Merged-main geometry/static gate failed; inspect logs; no camera pass claimed')
    world=json.loads((reports/'walkability-world.json').read_text())
    anchor_probe=module('main_anchor_probe',WORK/'tools/walkaudit/sightlines.py').audit(world,spawn_point={'x':200,'z':75})
    delta=dict(status='MERGED_MAIN_GEOMETRY_PASS',engineTested=False,fixesPR=15,
        fixesHead=EXPECTED_FIXES,mergedAt=pr['merged_at'],mergeCommit=pr['merge_commit_sha'],
        mainRevision=main_sha,mainWorldSourceUnmodified=True,commandsExitCodes=codes,before=before,after=after,
        partDelta=after['partCount']-before['partCount'],canonicalAnchor=dict(id='SC-01',x=200,surfaceY=.575,z=75,
            visibleTestedAnchors=anchor_probe['visibleAnchorCount'],runtimeRelocationApplied=False),
        cameraStatus='QUEUED_HEADLESS_PREVIEWS_NOT_ENGINE',
        limitations=['Actual old runtime spawn is distinct from the Manager-selected anchor',
                     'No Studio/rig/physics/streaming/device evidence'])
    destination=ROOT/'docs/reports/merged-main';destination.mkdir(parents=True,exist_ok=True)
    for path in reports.glob('walkability-*'):
        if path.suffix in ('.json','.csv'): shutil.copy2(path,destination/path.name)
    for name in ('PARKS.json','meanGrade-summary.md'):
        shutil.copy2(WORK/'audit'/name,destination/name)
    (destination/'sc01-sightlines.json').write_text(json.dumps(anchor_probe,indent=2)+'\n')
    (evidence/'merged-main-delta.json').write_text(json.dumps(delta,indent=2)+'\n')
    lines=['# Actual merged-main WALK delta',f'\nPR #15 merged at {pr["merged_at"]}; merge `{pr["merge_commit_sha"]}`.',
        f'Audited main **`{main_sha}`** with its actual, unmodified World modules. No merge by WALK.',
        '\n| Metric | Before main eaad19c | Actual merged main |','|---|---:|---:|']
    for label,key in [('Parts','partCount'),('Blocked sidewalks','blockedSidewalks'),
        ('Failed sidewalk-aligned crossings','failedSidewalkAlignedCrossings'),('Failed physical widths','failedWidths'),
        ('Curb-return solids','curbReturnCount'),('Curb-opening violations','failedCurbReturns')]:
        lines.append(f'| {label} | {before[key]} | {after[key]} |')
    lines.extend([f'\nFull route: **{after["routeLength"]:.6f} studs**. Original 70 sidewalks / 162 axes and',
        'the additional 324 crossings, physical widths and curb openings pass. Main checks pass.',
        f'WALK command exit: **{codes["walk"]}**; actual runtime clear landmark anchors: **{sight["visibleAnchorCount"]}/17**.',
        f'Canonical SC-01 at **(200,0.575,75)** has **{anchor_probe["visibleAnchorCount"]}/17** clear anchor rays.',
        'Naming/anchor decision is binding, but **runtime relocation has not been applied by this audit**.',
        '\nMachine record: `audit/merged-main-delta.json`; raw actual-main evidence: `docs/reports/merged-main/`.',
        'Camera output is a headless perspective box-geometry proxy, never an engine screenshot.'])
    (ROOT/'docs/reports/merged-main-delta.md').write_text('\n'.join(lines)+'\n')
    # User order: actual merged-main audit FIRST, then camera evidence.
    run([sys.executable,'tools/walkaudit/camera_pass.py','--world',str(reports/'walkability-world.json'),
         '--out','docs/reports/renders/route-stills','--main-sha',main_sha])
    delta['cameraStatus']='TEN_HEADLESS_PREVIEWS_COMPLETE_ENGINE_CAPTURE_UNVERIFIED'
    (evidence/'merged-main-delta.json').write_text(json.dumps(delta,indent=2)+'\n')
    print('POST_MERGE_AUDIT_AND_TEN_GEOMETRY_PREVIEWS_READY main='+main_sha,flush=True)


if __name__=='__main__': main()
