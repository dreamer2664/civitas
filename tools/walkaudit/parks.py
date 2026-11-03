"""Full parcel/cell-union inventory and physical meanGrade, not a quality score.

MeanGrade is percent surface slope (rise/run*100). A uniform-horizontal-face
proof gives zero regardless of overlap/area weighting; unsupported tilted faces
produce null, not an invented score. Steps and connectivity are separate gates.
"""
import json
import math
import hashlib
from pathlib import Path


def footprint(p):
    angle=math.radians(p['ry']);c,s=math.cos(angle),math.sin(angle)
    return [(p['x']+c*x+s*z,p['z']-s*x+c*z) for x,z in
            ((-p['sx']/2,-p['sz']/2),(p['sx']/2,-p['sz']/2),(p['sx']/2,p['sz']/2),(-p['sx']/2,p['sz']/2))]


def intersection_area(p,r):
    polygon=footprint(p)
    for axis,bound,sign in ((0,r['minX'],1),(0,r['maxX'],-1),(1,r['minZ'],1),(1,r['maxZ'],-1)):
        output=[]
        for a,b in zip(polygon,polygon[1:]+polygon[:1]):
            ia,ib=sign*(a[axis]-bound)>=0,sign*(b[axis]-bound)>=0
            if ia:output.append(a)
            if ia!=ib:
                t=(bound-a[axis])/(b[axis]-a[axis])
                output.append((a[0]+t*(b[0]-a[0]),a[1]+t*(b[1]-a[1])))
        polygon=output
        if not polygon:return 0.
    return abs(sum(a[0]*b[1]-b[0]*a[1] for a,b in zip(polygon,polygon[1:]+polygon[:1])))/2


def cell_domain(block,grid_x,grid_z):
    cells=[];seen=set()
    for cell in block['cells']:
        xi,zi=cell['xi']-1,cell['zi']-1
        if (xi,zi) in seen or not (0<=xi<len(grid_x)-1 and 0<=zi<len(grid_z)-1):
            raise ValueError('Duplicate or invalid source grid cell')
        seen.add((xi,zi))
        cells.append(dict(minX=grid_x[xi],maxX=grid_x[xi+1],minZ=grid_z[zi],maxZ=grid_z[zi+1]))
    if not cells:raise ValueError('Empty parcel')
    return cells


def contains(base,r):
    if not (base['collide'] and base['anchored'] and base['shape']=='Block' and base['rx']==base['rz']==0 and base['sy']>0):return False
    a=math.radians(base['ry']);c,s=math.cos(a),math.sin(a)
    for x in (r['minX'],r['maxX']):
        for z in (r['minZ'],r['maxZ']):
            dx,dz=x-base['x'],z-base['z']
            if abs(dx*c-dz*s)>base['sx']/2 or abs(dx*s+dz*c)>base['sz']/2:return False
    return True


def region(name,kind,domain,parts):
    if any(r['maxX']<=r['minX'] or r['maxZ']<=r['minZ'] for r in domain):raise ValueError('Degenerate domain')
    base=next((p for p in parts if p['name']=='CollidableGround' and all(contains(p,r) for r in domain)),None)
    relevant=[p for p in parts if any(intersection_area(p,r)>1e-7 for r in domain)]
    supports=[p for p in relevant if p['walk'] and p['collide']]
    horizontal=bool(supports) and all(p['anchored'] and min(p['sx'],p['sy'],p['sz'])>0 and p['shape']=='Block' and p['rx']==p['rz']==0 for p in supports)
    tops=[p['y']+p['sy']/2 for p in supports]
    step_bound=max(tops)-min(tops) if tops else None
    return dict(name=name,kind=kind,domain=domain,
        domainAreaStuds2=sum((r['maxX']-r['minX'])*(r['maxZ']-r['minZ']) for r in domain),
        meanGrade=0.0 if horizontal else None,meanGradeUnit='percent',
        meanGradeProof='Every intersecting intended support face is horizontal; area weighting therefore remains zero' if horizontal else 'Unsupported surface: no grade inferred',
        groundSealed=base is not None,groundWitness=base['id'] if base else None,
        supportStepUpperBoundStuds=step_bound,noncollidableSupportIDs=[p['id'] for p in relevant if p['walk'] and not p['collide']],
        partCount=len(relevant),supportPartIDs=[p['id'] for p in supports],
        obstaclePartIDs=[p['id'] for p in relevant if p['collide'] and not p['walk']],
        geometryEvidencePass=base is not None and horizontal and step_bound is not None and step_bound<=1.2 and not any(p['walk'] and not p['collide'] for p in relevant),
        evidenceScope='Ground seal, horizontal-support grade and conservative support-height bound only',freeSpaceConnectivity='NOT_PROVEN_BY_MEANGRADE; buildings/obstacles are not walkable space',engineTested=False)


def build(data):
    references=[(cell['xi'],cell['zi']) for block in data['blocks'] for cell in block['cells']]
    expected={(x,z) for x in range(1,len(data['gridX'])) for z in range(1,len(data['gridZ']))}
    if len(references)!=len(set(references)) or set(references)!=expected:
        raise ValueError('Full block inventory must cover every source grid cell exactly once')
    declared=data['declaredSuperblocks']
    expected_names=[group['name'] for group in declared]
    actual_groups=[block for block in data['blocks'] if block['superblock']]
    actual_names=[block['name'] for block in actual_groups]
    if len(set(expected_names))!=len(expected_names) or len(set(actual_names))!=len(actual_names) or set(expected_names)!=set(actual_names):
        raise ValueError('Every declared superblock must be audited exactly once')
    by_name={block['name']:block for block in actual_groups}
    for group in declared:
        expected_cells={tuple(cell) for cell in group['cells']}
        actual_cells={(cell['xi'],cell['zi']) for cell in by_name[group['name']]['cells']}
        if expected_cells!=actual_cells:
            raise ValueError('Superblock membership differs from source declaration: '+group['name'])
    rows=[]
    for block in data['blocks']:
        rows.append(region(block['name'],'superblock' if block['superblock'] else 'block',cell_domain(block,data['gridX'],data['gridZ']),data['parts']))
    for square in [dict(data['plaza'],name='Old Town Square')]+data['pocketSquares']:
        r=dict(minX=square['centerX']-square['width']/2,maxX=square['centerX']+square['width']/2,minZ=square['centerZ']-square['depth']/2,maxZ=square['centerZ']+square['depth']/2)
        rows.append(region(square['name'],'public_square',[r],data['parts']))
    return dict(schema='civitas.walk.PARKS.v1',engineTested=False,
        meanGradeDefinition='Physical surface slope percent, not a quality/grading score. Horizontal support has zero slope; steps are excluded and bounded separately.',
        domainDefinition='Full union of source grid-centreline cells including former internal road corridors; L-shape missing cells are NOT filled by a bounding box. Public squares use exact declared rectangles.',
        superblockCoverageCertificate=dict(expectedCount=len(expected_names),auditedCount=len(actual_names),expectedNames=sorted(expected_names),auditedNames=sorted(actual_names),missing=[],unexpected=[],membershipMatches=True),
        semanticParksDeclared=0,note='No semantic park inventory exists. PARKS.json names the requested artifact; records are actual parcels and public squares, not invented parks.',
        fullBlockCount=sum(r['kind'] in ('block','superblock') for r in rows),superblockCount=sum(r['kind']=='superblock' for r in rows),publicSquareCount=sum(r['kind']=='public_square' for r in rows),
        sourceGridCellCount=len(expected),auditedGridCellCount=len(references),gridCoverageComplete=True,
        actualScenePartCount=len(data['parts']),allRegionEvidencePass=all(r['geometryEvidencePass'] for r in rows),regions=rows,
        limitations=['Grade zero does not imply obstacle-free or accessible space','Shared boundary roads and overlapping region inventories must not be summed as unique scene parts','Base seal does not prove elevated floors','No engine or phone profiling'])


if __name__=='__main__':
    root=Path(__file__).resolve().parents[2]
    source=root/'docs/reports/walkability-world.json'
    result=build(json.loads(source.read_text()))
    result['geometryExportSHA256']=hashlib.sha256(source.read_bytes()).hexdigest()
    (root/'audit').mkdir(exist_ok=True)
    (root/'audit/PARKS.json').write_text(json.dumps(result,indent=2)+'\n')
    summary=['# Full-superblock meanGrade summary','',
        'meanGrade = physical slope %, not a quality score. All 50 parcels are inventoried in PARKS.json; the table summarizes every superblock plus all three public squares.',
        f"Coverage certificate: {result['superblockCoverageCertificate']['auditedCount']}/{result['superblockCoverageCertificate']['expectedCount']} declared superblocks, exact cell membership; missing 0, unexpected 0. All {result['auditedGridCellCount']} grid cells audited exactly once.",
        '','| Region | Kind | Domain area (studs²) | meanGrade (%) | Support step bound (studs) | Base sealed |',
        '|---|---|---:|---:|---:|---|']
    for row in result['regions']:
        if row['kind']=='block':continue
        grade='unknown' if row['meanGrade'] is None else f"{row['meanGrade']:.3f}"
        step='unknown' if row['supportStepUpperBoundStuds'] is None else f"{row['supportStepUpperBoundStuds']:.3f}"
        summary.append(f"| {row['name']} | {row['kind']} | {row['domainAreaStuds2']:.1f} | {grade} | {step} | {'yes' if row['groundSealed'] else 'NO'} |")
    summary+=['','Uniform horizontal support proves meanGrade=0 without double-counting overlap. Step bounds are conservative max-minus-min of actual support tops, not a measured boundary transition. Buildings and obstacles remain excluded from any claim of free-space connectivity. No semantic parks or engine tests are invented.']
    (root/'audit/meanGrade-summary.md').write_text('\n'.join(summary)+'\n')
    print(f"PARKS: parcels={result['fullBlockCount']} superblocks={result['superblockCount']} publicSquares={result['publicSquareCount']} regionEvidencePass={result['allRegionEvidencePass']}")
    if not result['allRegionEvidencePass']:raise SystemExit(1)
