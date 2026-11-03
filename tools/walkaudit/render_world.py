"""Render actual constructed geometry footprints and audited route, no invented city."""
import html
import json
import math
from pathlib import Path

root=Path(__file__).resolve().parents[2]
data=json.loads((root/'docs/reports/walkability-world.json').read_text())
result=json.loads((root/'docs/reports/walkability-live-results.json').read_text())
b=data['bounds'];scale=min(990/(b['maxX']-b['minX']),1120/(b['maxZ']-b['minZ']))
def xy(x,z): return 70+(x-b['minX'])*scale,130+(z-b['minZ'])*scale
svg=['<svg xmlns="http://www.w3.org/2000/svg" width="1140" height="1400" viewBox="0 0 1140 1400">','<rect width="1140" height="1400" fill="#142230"/>','<g font-family="monospace" fill="#ecf0f4">','<text x="40" y="42" font-size="25">CIVITAS / WALK · pave / REAL BUILDER GEOMETRY</text>',f'<text x="40" y="78" font-size="16">{result["partCount"]} parts · route {result["routeLength"]:.2f} studs · max step {result["maxStepStuds"]:.3f}</text>','<text x="40" y="105" font-size="15">Gold: route / Blue: walkable / Grey: massing / Red: blocked sidewalk</text>']
for p in sorted(data['parts'],key=lambda p:p['y']):
    c,s=math.cos(math.radians(p['ry'])),math.sin(math.radians(p['ry']))
    points=[]
    for dx,dz in ((-1,-1),(1,-1),(1,1),(-1,1)):
        lx,lz=dx*p['sx']/2,dz*p['sz']/2
        x,z=xy(p['x']+c*lx+s*lz,p['z']-s*lx+c*lz);points.append(f'{x:.2f},{z:.2f}')
    color='#45614e' if p['name']=='CollidableGround' else '#719caf' if p['walk'] else '#b8ada0'
    svg.append(f'<polygon points="{" ".join(points)}" fill="{color}" stroke="#334553" stroke-width="0.3"><title>{html.escape(p["id"])}</title></polygon>')
points=' '.join(f'{xy(p["x"],p["z"])[0]:.2f},{xy(p["x"],p["z"])[1]:.2f}' for p in data['route'])
svg.append(f'<polyline points="{points}" fill="none" stroke="#ffd465" stroke-width="4" stroke-linejoin="round"/>')
for check in result.get('sidewalkChecks',[]):
    for d in check['defects']:
        x,z=xy(d['x'],d['z']);svg.append(f'<circle cx="{x}" cy="{z}" r="7" fill="#ff5e60"><title>{html.escape(d["code"]+": "+d["detail"])}</title></circle>')
candidate=data.get('recommendedSpawn',{}).get('city')
if candidate:
    x,z=xy(candidate['x'],candidate['z'])
    svg.append(f'<circle cx="{x}" cy="{z}" r="7" fill="#6fe2e7" stroke="#142230"><title>Unapplied spawn candidate ({candidate["x"]}, {candidate["z"]}); 1505-stud route; geometry-visible landmark anchors</title></circle>')
for i,p in enumerate(data['route']):
    x,z=xy(p['x'],p['z']);svg.append(f'<circle cx="{x}" cy="{z}" r="5" fill="#ffd465" stroke="#142230"/><text x="{x+9}" y="{z-8}" font-size="13" fill="#fff1c6">{i+1}</text>')
for i,p in enumerate(data['route']):
    svg.append(f'<text x="40" y="{1280+i*11}" font-size="10">{i+1}. {html.escape(p["label"])} ({p["x"]}, {p["z"]})</text>')
svg+=[f'<text x="480" y="1275" font-size="13">{len(result["crossingChecks"])} crossings; max step {result["maximumCrossingStep"]:.3f} studs</text>','<text x="480" y="1300" font-size="13">Exact ground containment: 2,895,200 studs²</text>',f'<text x="480" y="1325" font-size="13">384-radius bound peak: {result["streamingEnvelope"]["384"]["maxIntersectingParts"]} parts; not engine profiling.</text>','<text x="480" y="1350" font-size="13">Platform absent; mobile draw calls unmeasured.</text>','</g></svg>']
(root/'docs/reports/renders/walkability-route.svg').write_text('\n'.join(svg)+'\n')
print('Rendered docs/reports/renders/walkability-route.svg from actual CityBuilder parts')
