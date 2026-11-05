#!/usr/bin/env python3
"""Approximate passenger HUD concept; this is not an in-engine screenshot."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[2]
image = Image.new('RGB', (844, 390), '#6c7a70')
d = ImageDraw.Draw(image)
# Neutral conceptual background, not an assertion about what Roblox actually renders.
d.rectangle((0, 0, 844, 75), fill='#323f46')
d.rectangle((0, 75, 844, 250), fill='#9ba99f')
d.rectangle((0, 250, 844, 390), fill='#777d75')
d.rectangle((0, 235, 844, 250), fill='#c4bca8')
font_path = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
bold_path = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
font = ImageFont.truetype(font_path, 14)
bold = ImageFont.truetype(bold_path, 14)
small = ImageFont.truetype(font_path, 12)
d.text((18, 20), 'PASSENGER HUD CONCEPT  /  NOT A STUDIO SCREENSHOT', font=small, fill='#e3e9e9')
# UI is drawn at the same 260 x 110 pixel size and 16 pixel safe inset as the client.
x,y = 568,264
d.rectangle((x,y,x+260,y+110),fill='#161c22')
d.text((x+12,y+7),'EXPERIMENTAL SHUTTLE',font=bold,fill='#eef1f3')
d.text((x+12,y+25),'Doors open - alighting available',font=font,fill='#eef1f3')
d.rectangle((x+12,y+53,x+248,y+99),fill='#1f262e')
text='ALIGHT AT PLATFORM'
bounds=d.textbbox((0,0),text,font=font)
d.text((x+130-(bounds[2]-bounds[0])/2,y+68),text,font=font,fill='#eef1f3')
out = root / 'tools/world/renders/passenger-interface-concept.png'
image.save(out)
print('Rendered passenger interface concept (not a Studio screenshot).')
