"""Conservative headless landmark-anchor visibility, NOT an engine camera test.

Rays use actual constructed opaque bounding solids and an explicitly assumed
4.5-stud eye offset. A blocked set of anchors does not prove every landmark pixel
is invisible. Full cylinders and partially transparent solids are conservatively
boxed/opaque. Character rigs, camera FOV and first-frame camera are unverified.
"""
import csv
import json
import math
from pathlib import Path


def ray_interval(part, origin, target):
    angle=math.radians(part['ry'])
    cosine,sine=math.cos(angle),math.sin(angle)
    x,z=origin['x']-part['x'],origin['z']-part['z']
    dx,dz=target['x']-origin['x'],target['z']-origin['z']
    origins=(x*cosine-z*sine,origin['y']-part['y'],x*sine+z*cosine)
    deltas=(dx*cosine-dz*sine,target['y']-origin['y'],dx*sine+dz*cosine)
    low,high=0.,1.
    for value,delta,half in zip(origins,deltas,(part['sx']/2,part['sy']/2,part['sz']/2)):
        if abs(delta)<1e-12:
            if abs(value)>half:
                return None
        else:
            a,b=sorted(((-half-value)/delta,(half-value)/delta))
            low,high=max(low,a),min(high,b)
            if low>high:
                return None
    return low,high


def first_hit(parts,origin,target):
    candidates=[]
    for part in parts:
        if part['transparency']>=.999:
            continue
        interval=ray_interval(part,origin,target)
        if interval is not None:
            candidates.append((interval[0],part['id'],part))
    return min(candidates,key=lambda item:(item[0],item[1])) if candidates else None


def surface_top(parts,point):
    tops=[]
    for part in parts:
        if not (part['walk'] and part['collide'] and part['shape']=='Block'):
            continue
        angle=math.radians(part['ry'])
        dx,dz=point['x']-part['x'],point['z']-part['z']
        x,z=dx*math.cos(angle)-dz*math.sin(angle),dx*math.sin(angle)+dz*math.cos(angle)
        if abs(x)<=part['sx']/2-1 and abs(z)<=part['sz']/2-1:
            tops.append(part['y']+part['sy']/2)
    if not tops: raise ValueError('Candidate spawn footprint unsupported')
    return max(tops)


def audit(data,eye_offset=4.5,spawn_point=None):
    parts=data['parts']
    spawn=next(p for p in parts if p['name']=='CoreSidewalkSpawn')
    eye=dict(x=spawn['x'],y=spawn['y']+spawn['sy']/2+eye_offset,z=spawn['z'])
    if spawn_point is not None:
        eye=dict(x=spawn_point['x'],y=surface_top(parts,spawn_point)+eye_offset,z=spawn_point['z'])
    landmarks={p['name'] for p in data['landmarks']}
    targets=[p for p in parts if p['name'] in ('Crown','Lantern') and p['id'].rsplit('.',1)[0].split('.BuildingMassing.',1)[-1] in landmarks]
    if not targets:
        raise ValueError('No actual constructed landmark anchors; cannot verify sightlines')
    results=[]
    for target in targets:
        parent=target['id'].rsplit('.',1)[0]
        aim=dict(x=target['x'],y=target['y']+target['sy']*.4,z=target['z'])
        hit=first_hit(parts,eye,aim)
        visible=hit is not None and hit[2]['id'].rsplit('.',1)[0]==parent
        item=dict(landmark=parent.split('.BuildingMassing.',1)[-1],anchor=target['id'],target=aim,
            visibleAnchor=visible,blocker=None,hitPoint=None)
        if hit is not None:
            item['blocker']=None if visible else hit[2]['id']
            item['hitPoint']={k:eye[k]+(aim[k]-eye[k])*hit[0] for k in ('x','y','z')}
        results.append(item)
    return dict(engineTested=False,eyeOffsetAssumed=eye_offset,eye=eye,
        landmarkCount=len(landmarks),anchorCount=len(results),visibleAnchorCount=sum(p['visibleAnchor'] for p in results),
        status='ANCHOR_SIGHTLINE_EXISTS' if any(p['visibleAnchor'] for p in results) else 'NO_TESTED_ANCHOR_CLEAR',
        limitations=['No engine camera or rig test','Blocked anchors do not prove all pixels invisible','Cylinders boxed; partial transparency conservatively opaque'],
        anchors=results)


if __name__=='__main__':
    root=Path(__file__).resolve().parents[2]
    data=json.loads((root/'docs/reports/walkability-world.json').read_text())
    result=audit(data)
    (root/'docs/reports/walkability-spawn-sightlines.json').write_text(json.dumps(result,indent=2)+'\n')
    with (root/'docs/reports/walkability-spawn-sightlines.csv').open('w',newline='') as output:
        writer=csv.DictWriter(output,fieldnames=['landmark','anchor','visibleAnchor','targetX','targetY','targetZ','blocker','hitX','hitY','hitZ'])
        writer.writeheader()
        for item in result['anchors']:
            row={k:item[k] for k in ('landmark','anchor','visibleAnchor','blocker')}
            row.update({f'target{k.upper()}':item['target'][k] for k in ('x','y','z')})
            row.update({f'hit{k.upper()}':(item['hitPoint'] or {}).get(k,'') for k in ('x','y','z')})
            writer.writerow(row)
    candidate=audit(data,eye_offset=data['recommendedSpawn']['eyeOffsetAssumed'],spawn_point=data['recommendedSpawn']['city'])
    lune=json.loads((root/'docs/reports/walkability-lune-results.json').read_text())
    candidate['runtimeApplied']=False
    candidate['recommendedPlan']=data['recommendedSpawn']
    candidate['routeProof']=lune['recommendedSpawn']['route']
    (root/'docs/reports/walkability-spawn-candidate.json').write_text(json.dumps(candidate,indent=2)+'\n')
    if not candidate['visibleAnchorCount'] or candidate['routeProof']['defects']:
        raise ValueError('Candidate spawn is not geometry-verified')
    print(f"CANDIDATE SPAWN: point={data['recommendedSpawn']['city']} clearAnchors={candidate['visibleAnchorCount']} route={candidate['routeProof']['length']:.6f} (runtime not applied)")
    print(f"SPAWN SIGHTLINES: eye={result['eye']} landmarks={result['landmarkCount']} testedAnchors={result['anchorCount']} clear={result['visibleAnchorCount']} ({result['status']}; camera/rig unverified)")
    raise SystemExit(0 if result['visibleAnchorCount'] else 1)
