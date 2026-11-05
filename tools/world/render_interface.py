#!/usr/bin/env python3
"""Approximate interface review images, NOT Roblox screenshots.

Uses the committed city concept render and NETWORK.md data. Roblox fonts, GUI layout,
clipping and input behaviour must still be checked in Studio.
"""
from pathlib import Path
import sys
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
import gen_network

OUT = ROOT / "tools/world/renders"
md = (ROOT / "docs/rail/NETWORK.md").read_text()
stations = gen_network.parse_stations(md)
lines = gen_network.parse_waypoints(md)
fontfile = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
boldfile = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

def font(size, bold=False):
    return ImageFont.truetype(boldfile if bold else fontfile, size)

def render(w, h, name):
    im = Image.open(OUT / "street-view-station.png").convert("RGB")
    im = im.crop((0, 110, im.width, 880)).resize((w, h))
    d = ImageDraw.Draw(im)
    # ScreenGui controls and panel dimensions match CityInterface.client.luau.
    d.rounded_rectangle((16, 16, 176, 64), 2, fill="#1e3a46")
    d.text((29, 29), "HISTORIC CORE", font=font(16, True), fill="#f3efe4")
    x, y, pw, ph = w*.05, h*.08, w*.9, h*.84
    d.rectangle((x, y, x+pw, y+ph), fill="#0e1216")
    d.text((x+16, y+5), "PLANNED NETWORK", font=font(18, True), fill="#eef1f3")
    d.text((x+16, y+32), "Concept only - no train services yet. Zoom for station names.", font=font(12), fill="#aeb8c1")
    mx, my, mw, mh = x+12, y+64, pw-24, ph-128
    d.rectangle((mx, my, mx+mw, my+mh), fill="#161c22")
    points = [p for pts in lines.values() for p in pts] + [(s['x'], s['z']) for s in stations]
    minx, maxx = min(p[0] for p in points), max(p[0] for p in points)
    minz, maxz = min(p[1] for p in points), max(p[1] for p in points)
    scale = min(max(mw-48, 1)/(maxx-minx), max(mh-48, 1)/(maxz-minz))
    ox = mx+24+(max(mw-48, 1)-(maxx-minx)*scale)/2
    oy = my+24+(max(mh-48, 1)-(maxz-minz)*scale)/2
    def pt(p): return (ox+(p[0]-minx)*scale, oy+(p[1]-minz)*scale)
    colors = {1:'#2a9696', 2:'#5c8ac8', 3:'#c99a2e'}
    for n, pts in lines.items():
        d.line([pt(p) for p in pts], fill=colors[n], width=4)
    accepted = []
    for s in stations:
        sx, sy = pt((s['x'], s['z']))
        size = 18 if len(s['lines']) > 1 else 12
        accepted.append((sx-size/2-2, sy-size/2-2, sx+size/2+2, sy+size/2+2))
    for s in stations:
        sx, sy = pt((s['x'], s['z']))
        size = 18 if len(s['lines']) > 1 else 12
        d.ellipse((sx-size/2, sy-size/2, sx+size/2, sy+size/2), fill="#f3efe4", outline="#0e1216", width=2)
        rect = (sx+size/2+4, sy-8, sx+size/2+4+len(s['name'])*9, sy+10)
        clipped = rect[0] < mx or rect[1] < my or rect[2] > mx+mw or rect[3] > my+mh
        overlaps = any(rect[0] < r[2] and rect[2] > r[0] and rect[1] < r[3] and rect[3] > r[1] for r in accepted)
        if not clipped and not overlaps:
            accepted.append(rect)
            d.text((rect[0], rect[1]), s['name'], font=font(12), fill="#eef1f3")
    for text, bx in [('-', x+12), ('+', x+76)]:
        d.rounded_rectangle((bx,y+ph-56,bx+56,y+ph-8), 4, fill="#1f262e", outline="#3a4550")
        d.text((bx+23,y+ph-43), text, font=font(16, True), fill="#eef1f3")
    d.rounded_rectangle((w-136,16,w-16,64), 4, fill="#1f262e", outline="#3a4550")
    d.text((w-121,31), "CLOSE MAP", font=font(14, True), fill="#eef1f3")
    im.save(OUT / name)

render(1280, 720, 'ui-map-desktop-concept.png')
render(844, 390, 'ui-map-phone-concept.png')
print('Wrote interface concepts (not Roblox screenshots).')
