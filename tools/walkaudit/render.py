"""Top-down audit evidence; never invents geometry when world data is absent."""
import html
import json
from pathlib import Path

root = Path(__file__).resolve().parents[2]
data = json.loads((root / 'docs/reports/walkability-results.json').read_text())
svg = ['<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="900" viewBox="0 0 1200 900">',
       '<rect width="1200" height="900" fill="#111c28"/>',
       '<g font-family="monospace" fill="#ecf1f6"><text x="40" y="52" font-size="26">CIVITAS / WALK · pave / HEADLESS AUDIT</text>']
if data['status'] == 'BLOCKED':
    svg += ['<text x="40" y="140" font-size="30" fill="#ffbe77">BLOCKED — NO WORLD GEOMETRY</text>',
            '<text x="40" y="195" font-size="18">No city route can be drawn or accepted from this revision.</text>',
            '<text x="40" y="230" font-size="18">Missing: src/server/World/Geometry.generateAuditData()</text>',
            '<text x="40" y="290" font-size="18">No substitute floor. No invented city. No engine test.</text>']
else:
    b = data['bounds']
    scale = min(1100/(b['x1']-b['x0']), 650/(b['z1']-b['z0']))
    def x(v): return 50+(v-b['x0'])*scale
    def z(v): return 150+(v-b['z0'])*scale
    svg += ['<text x="40" y="100" font-size="18">Blue: supported surface / Grey: obstacle / Gold: route / Red: defect</text>']
    for box in data['boxes']:
        color = '#345f71' if box['walk'] and box['collide'] else '#4a4855'
        svg += [f'<rect x="{x(box["x0"])}" y="{z(box["z0"])}" width="{(box["x1"]-box["x0"])*scale}" height="{(box["z1"]-box["z0"])*scale}" fill="{color}" stroke="#77919b" stroke-width="0.4"><title>{html.escape(box["id"])}</title></rect>']
    points = ' '.join(f'{x(p["x"])},{z(p["z"])}' for p in data['route'])
    svg += [f'<polyline points="{points}" fill="none" stroke="#ffdc7b" stroke-width="3"/>']
    for d in data['defects']:
        svg += [f'<circle cx="{x(d["x"])}" cy="{z(d["z"])}" r="5" fill="#ff5b60"><title>{html.escape(d["code"]+": "+d["detail"])}</title></circle>']
svg += ['<text x="40" y="855" font-size="16">Geometry evidence only — Roblox character physics and client streaming unverified.</text></g></svg>']
path = root / 'docs/reports/renders/walkability-route.svg'
path.write_text('\n'.join(svg)+'\n')
print(path.relative_to(root))
