"""Analytic audit of the actual CityBuilder export. No engine/physics claims.

Only horizontal block surfaces are accepted. Rotated block footprint clipping is
analytic. A collidable cylinder obstacle is conservatively boxed, never used to
prove support. Unsupported shapes/tilt prevent acceptance.
"""
import json
import csv
import math
import importlib.util
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
EPS = 1e-5
_stream_spec=importlib.util.spec_from_file_location('walk_streaming',Path(__file__).with_name('streaming.py'))
_stream_module=importlib.util.module_from_spec(_stream_spec)
_stream_spec.loader.exec_module(_stream_module)


def local(p, x, z):
    a = math.radians(p['ry'])
    dx, dz = x-p['x'], z-p['z']
    return dx*math.cos(a)-dz*math.sin(a), dx*math.sin(a)+dz*math.cos(a)


def clip(p, a, b, margin):
    """Closed parametric interval inside a yawed box, margin in local axes."""
    ax, az = local(p, a['x'], a['z'])
    bx, bz = local(p, b['x'], b['z'])
    low, high = 0.0, 1.0
    for origin, delta, half in ((ax, bx-ax, p['sx']/2+margin), (az, bz-az, p['sz']/2+margin)):
        if half < 0:
            return None
        if abs(delta) < 1e-12:
            if abs(origin) > half:
                return None
        else:
            t0, t1 = sorted(((-half-origin)/delta, (half-origin)/delta))
            low, high = max(low, t0), min(high, t1)
            if low > high:
                return None
    return max(0., low), min(1., high)


def audit(data, minimum=1500, measure_streaming=True, check_spawns=True):
    parts, route, bounds = data['parts'], data['route'], data['bounds']
    defects = []
    def defect(code, x, z, detail, **extra):
        defects.append(dict(code=code, x=x, z=z, detail=detail, **extra))
    for p in parts:
        if not all(math.isfinite(p[k]) for k in ('x','y','z','sx','sy','sz','rx','ry','rz')):
            raise ValueError('Nonfinite geometry: '+p['id'])
        if p['rx'] != 0 or p['rz'] != 0 or p['shape'] not in ('Block','Cylinder'):
            defect('UNSUPPORTED_GEOMETRY',p['x'],p['z'],p['id'])
        if p['walk'] and not p['collide']:
            defect('NONCOLLIDABLE_SURFACE',p['x'],p['z'],p['id'])
        if min(p['sx'],p['sy'],p['sz']) <= 0:
            defect('DEGENERATE_GEOMETRY',p['x'],p['z'],p['id'])
        if not p['anchored']:
            defect('UNANCHORED',p['x'],p['z'],p['id'])
        p['top'], p['bottom'] = p['y']+p['sy']/2, p['y']-p['sy']/2
    # A single actual closed base solid containing every domain corner proves
    # continuous ground coverage for all real x/z coordinates, without sampling.
    corners = [dict(x=x,z=z) for x in (bounds['minX'],bounds['maxX']) for z in (bounds['minZ'],bounds['maxZ'])]
    seal_witness = next((p for p in parts if p['name']=='CollidableGround' and p['collide'] and p['anchored'] and p['shape']=='Block' and p['sx']>0 and p['sy']>0 and p['sz']>0 and p['rx']==p['rz']==0 and all(clip(p,c,c,0) is not None for c in corners)),None)
    if not seal_witness:
        defect('GROUND_SEAL_UNPROVEN',0,0,'No exact base-solid containment witness; not a sampled pass')
    supports = [p for p in parts if p['walk'] and p['collide'] and p['shape']=='Block' and p['rx']==p['rz']==0]
    spawn_results=[]
    for label,point in ((('District A sidewalk',route[0]),('station concourse',route[-1])) if check_spawns else ()):
        candidates=[p for p in supports if clip(p,point,point,-1.) is not None]
        top=max((p['top'] for p in candidates),default=None)
        blocked=[p['id'] for p in parts if top is not None and p['collide'] and clip(p,point,point,1.) is not None and p['bottom']<top+5-EPS and p['top']>top+1.2+EPS]
        valid=top is not None and not blocked
        spawn_results.append(dict(label=label,x=point['x'],z=point['z'],supportTop=top,geometrySafe=valid,blockers=blocked,runtimeVerified=False))
        if not valid: defect('SPAWN_UNSAFE',point['x'],point['z'],label)
    total, max_step, checks = 0., 0., 0
    previous = None
    for index,(a,b) in enumerate(zip(route,route[1:])):
        dx,dz=b['x']-a['x'],b['z']-a['z']
        length=math.hypot(dx,dz); total+=length
        intervals=[]; blockers=[]; ts={0.,1.}
        for p in supports:
            interval=clip(p,a,b,-1.)  # entire radius-1 footprint fits this true box
            if interval:
                intervals.append((p,*interval));ts.update(interval)
        for p in parts:
            if p['collide']:
                interval=clip(p,a,b,1.) # conservative horizontal body envelope
                if interval:
                    blockers.append((p,*interval));ts.update(interval)
        ts=sorted(ts)
        for lo,hi in zip(ts,ts[1:]):
            if hi-lo<1e-10: continue
            t=(lo+hi)/2; x,z=a['x']+t*dx,a['z']+t*dz;checks+=1
            support=[p for p,u,v in intervals if u-1e-12<=t<=v+1e-12]
            if not support:
                defect('ROUTE_GAP',x,z,f'unsupported footprint interval {(hi-lo)*length:.6f} studs',segment=index+1)
                previous=None;continue
            top=max(p['top'] for p in support)
            if previous is not None:
                step=abs(top-previous);max_step=max(max_step,step)
                if step>1.2+EPS:
                    defect('STEP',a['x']+lo*dx,a['z']+lo*dz,f'{step:.6f}-stud change',segment=index+1)
            previous=top
            for p,u,v in blockers:
                if u+1e-10<t<v-1e-10 and p['bottom']<top+5-EPS and p['top']>top+1.2+EPS:
                    defect('BODY_BLOCKED',x,z,p['id'],segment=index+1,top=p['top'],bottom=p['bottom'],startX=a['x']+lo*dx,startZ=a['z']+lo*dz,endX=a['x']+hi*dx,endZ=a['z']+hi*dz)
    if total<minimum: defect('ROUTE_TOO_SHORT',route[0]['x'],route[0]['z'],str(total))
    decorative = [p for p in parts if p['collide'] and any(s in p['name'] for s in ('DisplayWindow','EntryLintel','RecessedShopDoor','RecessedDoor'))]
    counts = {p['name']:sum(q['name']==p['name'] for q in decorative) for p in decorative}
    # Geometry residency envelope, NOT engine draw calls / actual client residency.
    streaming={}
    for radius in ((64,256,384,512,1024) if measure_streaming else ()):
        counts_at=[]
        for a,b in zip(route,route[1:]):
            steps=max(1,math.ceil(math.hypot(b['x']-a['x'],b['z']-a['z'])/16))
            for s in range(steps+1):
                x=a['x']+(b['x']-a['x'])*s/steps;z=a['z']+(b['z']-a['z'])*s/steps
                n=0
                for p in parts:
                    px,pz=local(p,x,z)
                    if max(0,abs(px)-p['sx']/2)**2+max(0,abs(pz)-p['sz']/2)**2<=radius**2:
                        n+=1
                counts_at.append(n)
        streaming[str(radius)]={'minIntersectingParts':min(counts_at),'maxIntersectingParts':max(counts_at),'samplePositions':len(counts_at),'spacingMaxStuds':16}
    continuous=_stream_module.envelopes(parts,route) if measure_streaming else {}
    return dict(status='GEOMETRY_CHECKS_PASS' if not defects else 'FAIL',engineTested=False,
        sourceRevision=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
        worldRevision=subprocess.check_output(['git','rev-parse','origin/world/historic-core-blockout'],cwd=ROOT,text=True).strip(),
        partCount=len(parts),spawnChecks=spawn_results,routeLength=total,routeIntervals=checks,maxStepStuds=max_step,
        groundSeal={'proven':seal_witness is not None,'method':'exact closed base-solid contains all domain corners','witness':seal_witness['id'] if seal_witness else None,'bounds':bounds,'areaStudsSquared':(bounds['maxX']-bounds['minX'])*(bounds['maxZ']-bounds['minZ'])},
        defects=defects,decorativeCollisionCount=len(decorative),decorativeCollisionClasses=counts,
        collisionPolicyFindings=[dict(code='DECORATIVE_COLLISION',x=p['x'],y=p['y'],z=p['z'],sx=p['sx'],sy=p['sy'],sz=p['sz'],id=p['id']) for p in decorative],
        streamingEnvelope=continuous,sampledStreamingEnvelope=streaming,unbatchedMainPassEstimate=continuous.get('1024',{}).get('maxIntersectingParts'),
        measuredDrawCalls=None,limitations=['Lune data model only, no engine','Box/cylinder obstacle bounds conservative','Continuous analytic bounding-footprint envelopes, not streaming simulation','Platform absent: station placeholder cannot prove platform exit','Landmark sight line and first-frame character grounding unverified'])


if __name__=='__main__':
    data=json.loads((ROOT/'docs/reports/walkability-world.json').read_text())
    result=audit(data)
    sidewalk_checks=[]
    for part in data['parts']:
        if 'Sidewalk' not in part['name'] or part['name']=='CoreSidewalkSpawn': continue
        yaw=math.radians(part['ry'])
        if part['sx']>part['sz']:
            dx,dz=math.cos(yaw),-math.sin(yaw);half=part['sx']/2-1
        else:
            dx,dz=math.sin(yaw),math.cos(yaw);half=part['sz']/2-1
        route=[dict(x=part['x']-dx*half,z=part['z']-dz*half),dict(x=part['x']+dx*half,z=part['z']+dz*half)]
        sample=dict(data,route=route)
        check=audit(sample,minimum=0,measure_streaming=False,check_spawns=False)
        sidewalk_checks.append(dict(id=part['id'],length=check['routeLength'],maxStepStuds=check['maxStepStuds'],defects=check['defects']))
    crossing_checks=[]
    for intersection in data['intersections']:
        for axis in ('x','z'):
            half=intersection['widthX' if axis=='x' else 'widthZ']/2+data['sidewalkWidth']/2
            route=[dict(x=intersection['x']- (half if axis=='x' else 0),z=intersection['z']-(half if axis=='z' else 0)),
                   dict(x=intersection['x']+ (half if axis=='x' else 0),z=intersection['z']+(half if axis=='z' else 0))]
            check=audit(dict(data,route=route),minimum=0,measure_streaming=False,check_spawns=False)
            crossing_checks.append(dict(x=intersection['x'],z=intersection['z'],axis=axis,length=check['routeLength'],maxStepStuds=check['maxStepStuds'],defects=check['defects']))
    result['crossingChecks']=crossing_checks
    result['crossingDefectCount']=sum(len(c['defects']) for c in crossing_checks)
    result['maximumCrossingStep']=max(c['maxStepStuds'] for c in crossing_checks)
    if result['crossingDefectCount']: result['status']='FAIL_CROSSING_CONTINUITY'
    result['sidewalkChecks']=sidewalk_checks
    result['sidewalkDefectCount']=sum(len(p['defects']) for p in sidewalk_checks)
    if result['sidewalkDefectCount']: result['status']='FAIL_SIDEWALK_CONTINUITY'
    (ROOT/'docs/reports/walkability-live-results.json').write_text(json.dumps(result,indent=2)+'\n')
    (ROOT/'docs/reports/walkability-results.json').write_text(json.dumps(result,indent=2)+'\n')
    with (ROOT/'docs/reports/walkability-collision-defects.csv').open('w',newline='') as f:
        writer=csv.DictWriter(f,fieldnames=['code','id','x','y','z','sx','sy','sz'])
        writer.writeheader();writer.writerows(result['collisionPolicyFindings'])
    geometry_rows=[]
    scopes=[('acceptance-route',result['defects'])]
    scopes += [(c['id'],c['defects']) for c in result['sidewalkChecks']]
    scopes += [(f"crossing-{c['x']}-{c['z']}-{c['axis']}",c['defects']) for c in result['crossingChecks']]
    for scope,defects in scopes:
        for defect in defects:
            geometry_rows.append(dict(scope=scope,**{k:defect.get(k,'') for k in ('code','x','z','startX','startZ','endX','endZ','detail')}))
    with (ROOT/'docs/reports/walkability-geometry-defects.csv').open('w',newline='') as f:
        writer=csv.DictWriter(f,fieldnames=['scope','code','x','z','startX','startZ','endX','endZ','detail'])
        writer.writeheader();writer.writerows(geometry_rows)
    print(json.dumps({k:v for k,v in result.items() if k not in ('defects','limitations','decorativeCollisionClasses','collisionPolicyFindings','sidewalkChecks','crossingChecks')},indent=2))
    print(f"defects={len(result['defects'])}; decorativeCollisions={result['decorativeCollisionCount']}")
    raise SystemExit(1 if result['defects'] or result['sidewalkDefectCount'] or result['crossingDefectCount'] else 0)
