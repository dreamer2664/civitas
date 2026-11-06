#!/usr/bin/env python3
"""Package current verified build, curated renders, native scene and standalone report."""
import base64
import hashlib
import html
import io
import shutil
import subprocess
import zipfile
from pathlib import Path
import mistune
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'deliverables/norman'
OUT.mkdir(parents=True, exist_ok=True)
EVIDENCE = ROOT / 'evidence/norman'
CURATED = ['01-central-arrival.png', '03-historic-core.png', '05-shuttle-detail.png', '06-station-front.png']
EXTRAS = ['07-service-telemetry.png', '08-service-interface-study.png']
shutil.copyfile(ROOT/'build/civitas.rbxlx', OUT/'civitas-norman.rbxlx')
shutil.copyfile(ROOT/'build/review/civitas-norman-review.blend', OUT/'civitas-norman-review.blend')
notes = (EVIDENCE/'RENDER-REVIEW.md').read_text()
with zipfile.ZipFile(OUT/'civitas-best-renders.zip', 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as z:
    hashes = []
    for name in CURATED + EXTRAS:
        path = EVIDENCE/'renders'/name
        member = ('renders/' if name in CURATED else 'evidence/') + name
        z.write(path, member)
        hashes.append(hashlib.sha256(path.read_bytes()).hexdigest() + '  ' + member)
    z.writestr('RENDER-REVIEW.md', notes)
    z.writestr('README.txt', 'CIVITAS / Norman / 6 November 2026\n\nFour curated Blender geometry reviews under renders/.\nSimulation evidence and a UI layout study are separate under evidence/.\nNone are Roblox Studio screenshots. Not final production art.\nSee RENDER-REVIEW.md for inspected decisions and rejected iterations.\n')
    z.writestr('SHA256SUMS.txt', '\n'.join(hashes) + '\n')

report = (ROOT/'docs/reports/norman-app-report.md').read_text()
renderer = mistune.create_markdown(plugins=['table'])
report_html = renderer(report)
# Inline all media for the network-isolated viewer. Smaller JPEG display copies avoid
# duplicating the full-resolution PNG archive inside the report.
gallery = []
for name in ['01-central-arrival.png', '03-historic-core.png', '06-station-front.png', '07-service-telemetry.png', '08-service-interface-study.png']:
    image = Image.open(EVIDENCE/'renders'/name).convert('RGB')
    image.thumbnail((1280, 1280))
    buffer = io.BytesIO()
    image.save(buffer, format='JPEG', quality=87)
    uri = 'data:image/jpeg;base64,' + base64.b64encode(buffer.getvalue()).decode()
    gallery.append(f'<figure><img alt="{html.escape(name)}" src="{uri}"><figcaption>{html.escape(name)}</figcaption></figure>')
branch = subprocess.check_output(['git','branch','--show-current'], cwd=ROOT, text=True).strip()
content = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Civitas — Norman's app report</title>
<style>
:root{color-scheme:dark}*{box-sizing:border-box}body{margin:0;background:#101c20;color:#e8e6d9;font:16px/1.7 system-ui,sans-serif}header{padding:64px max(24px,calc((100vw - 1050px)/2));background:#1c3035;border-bottom:3px solid #cdb77b}header .brand{letter-spacing:.35em;color:#d3bd82;font-size:14px}header h1{font-size:clamp(32px,6vw,58px);line-height:1.1;margin:18px 0}header p{max-width:760px;color:#c3d0cb}.tag{display:inline-block;border:1px solid #667c7d;padding:5px 12px;border-radius:3px;font-size:12px;letter-spacing:.08em}main{max-width:1100px;margin:auto;padding:36px 24px 80px}.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:12px;margin-bottom:32px}.stat{background:#1b2c31;padding:20px;border-left:3px solid #cdb77b}.stat strong{display:block;font-size:28px;color:#d3bd82}.stat span{font-size:13px;color:#b6c8c7}h1,h2,h3{color:#f1eedf;line-height:1.3}article>h1{font-size:27px}h2{margin-top:42px;font-size:23px;border-bottom:1px solid #3c555b;padding-bottom:10px}a{color:#d3bd82}code{font-size:.88em;background:#243940;padding:2px 5px;border-radius:3px;overflow-wrap:anywhere}li{margin:10px 0}table{border-collapse:collapse;width:100%;font-size:13px;margin:24px 0}td,th{text-align:left;padding:12px;vertical-align:top;border-bottom:1px solid #3c555b}th{background:#243940;color:#d3bd82}figure{margin:28px 0;background:#1b2c31}figure img{width:100%;display:block}figcaption{padding:12px 18px;color:#b6c8c7;font-size:12px}.notice{padding:18px 22px;background:#302d22;border-left:3px solid #cdb77b}footer{margin-top:40px;font-size:12px;color:#a5b9ba}@media(max-width:600px){table{font-size:11px}td,th{padding:7px}header{padding:36px 24px}}
</style><header><div class="brand">C I V I T A S / NORMAN</div><h1>A stronger prototype.<br>Not a finished game.</h1><p>Two-stop automatic service, a connected second halt, an incremental train/station art pass and inspected geometry evidence.</p><span class="tag">06 NOVEMBER 2026 · EXPERIMENTAL ROBLOX BUILD</span></header><main>
<div class="stats"><div class="stat"><strong>178</strong><span>unit + city tests passed</span></div><div class="stat"><strong>12 min</strong><span>pure service simulation</span></div><div class="stat"><strong>2,328</strong><span>west corridor sample points</span></div><div class="stat"><strong>8</strong><span>inspected final review images</span></div></div><div class="notice"><strong>Evidence boundary:</strong> No Roblox Studio, multiplayer or mobile playtest was performed. Images are Blender geometry reviews, a simulation plot and a labelled layout study—not in-game screenshots.</div>
'''
content += '<article>' + report_html + '</article><h2>Inspected gallery</h2>' + ''.join(gallery)
content += '<footer>Source branch: ' + html.escape(branch) + '. Full-resolution curated PNGs are in civitas-best-renders.zip. Reproduction scripts, source and test evidence are in the repository. No external assets load in this report.</footer></main></html>'
(OUT/'civitas-app-report.html').write_text(content)
files = ['civitas-norman.rbxlx','civitas-best-renders.zip','civitas-norman-review.blend','civitas-app-report.html']
(OUT/'SHA256SUMS.txt').write_text(''.join(hashlib.sha256((OUT/n).read_bytes()).hexdigest() + '  ' + n + '\n' for n in files))
for n in files:
    print(n, (OUT/n).stat().st_size, 'bytes')
