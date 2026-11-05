#!/usr/bin/env python3
"""Approximate rail-test controls layout for design review; not a Roblox screenshot."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
root = Path(__file__).resolve().parents[1]
out = root / 'tools/world/renders'
font = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
bold = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
im = Image.open(out / 'rail-test-concept.png').convert('RGB').resize((1280,720))
d = ImageDraw.Draw(im)
x, y, w = 215, 542, 850
d.rectangle((x,y,x+w,y+166),fill='#161c22')
d.text((x+8,y+6),'RAIL TEST  /  BRAKE  /  FORWARD',font=ImageFont.truetype(bold,16),fill='#eef1f3')
d.text((x+8,y+29),'000.0 km/h  |  160 studs  |  doors closed  |  ready',font=ImageFont.truetype(font,14),fill='#aeb8c1')
labels=['POWER [W]', 'COAST [C]', 'BRAKE [S]', 'FORWARD [F]', 'REVERSE [R]', 'OPEN DOORS', 'CLOSE DOORS', 'HOLD DOORS']
for i,label in enumerate(labels):
    bx=x+(i%4)*w/4+4; by=y+55+(i//4)*52
    d.rectangle((bx,by,bx+w/4-8,by+46),fill='#1f262e')
    f=ImageFont.truetype(font,14)
    bb=d.textbbox((0,0),label,font=f)
    d.text((bx+(w/4-8-(bb[2]-bb[0]))/2,by+14),label,font=f,fill='#eef1f3')
im.save(out/'rail-controls-concept.png')
print('Rendered rail controls concept (not a Studio screenshot).')
