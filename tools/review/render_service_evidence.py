#!/usr/bin/env python3
"""Evidence plot + illustrative UI layouts. Neither is an in-engine screenshot."""
import json
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'evidence/norman/renders'
OUT.mkdir(parents=True, exist_ok=True)
data = json.loads((ROOT / 'evidence/norman/service-telemetry.json').read_text())
s = data['samples']
plt.rcParams.update({'font.family':'DejaVu Sans', 'text.color':'#e8e4d5', 'axes.labelcolor':'#bdcaca', 'xtick.color':'#bdcaca', 'ytick.color':'#bdcaca'})
fig, axes = plt.subplots(2, 1, figsize=(14, 8), sharex=True, facecolor='#132125', gridspec_kw={'height_ratios':[1.3,1]})
fig.subplots_adjust(top=.77, bottom=.14, hspace=.25, left=.1, right=.94)
fig.text(.07,.92,'C I V I T A S   /   SERVICE RELIABILITY',fontsize=22,weight='bold')
fig.text(.07,.865,'12 simulated minutes · 30 Hz · two stops · automatic dwell and door interlocks',fontsize=12,color='#b9cbc7')
fig.text(.07,.815,f"{data['arrivalsIncludingStartup']} arrivals incl. startup    /    peak {data['peakSpeedKph']:.2f} km/h    /    {data['doorViolations']} simulated door violations",fontsize=12,color='#d3bd82')
for ax in axes:
    ax.set_facecolor('#1a2b30')
    ax.spines[['top','right']].set_visible(False)
    ax.spines[['left','bottom']].set_color('#52656a')
    ax.grid(alpha=.12)
axes[0].plot([r['seconds'] for r in s], [r['positionStuds'] for r in s], color='#d3bd82', lw=2)
axes[0].set_yticks([200,770],['West Gardens','Civitas Central'])
axes[0].set_ylim(140,840)
axes[1].plot([r['seconds'] for r in s], [r['speedKph'] for r in s], color='#79aeb0', lw=1.7)
axes[1].set_ylabel('Speed · km/h')
axes[1].set_xlabel('Simulated time · seconds')
for ax in axes:
    for event in data['arrivals']:
        ax.axvline(event['seconds'], alpha=.14, color='#d3bd82')
fig.text(.07,.055,f"Pure rules only — NOT Roblox runtime, seat transport, multiplayer or mobile performance evidence.\nPrototype docking snap: maximum {data['maxDockingCorrectionStuds']:.3f} studs; not a real stopping-accuracy claim.",fontsize=10,color='#b9cbc7')
fig.savefig(OUT/'07-service-telemetry.png',dpi=140,facecolor=fig.get_facecolor())
plt.close(fig)

# Illustrate the actual service-panel dimensions/colours and sample strings. The backdrop
# is a reviewed Blender geometry render, NOT an engine capture; no false screenshot claim.
font_path='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
bold_path='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
font=ImageFont.truetype(font_path,14)
small=ImageFont.truetype(font_path,12)
bold=ImageFont.truetype(bold_path,14)
image=Image.new('RGB',(1100,800),'#132125')
d=ImageDraw.Draw(image)
d.text((34,26),'C I V I T A S   /   LIVE SERVICE INTERFACE',font=ImageFont.truetype(bold_path,24),fill='#eee8d7')
d.text((34,66),'LAYOUT STUDY · NOT ROBLOX STUDIO · illustrative server state',font=font,fill='#b9cbc7')
# Main landscape reference frame, 844 x 390 like the earlier passenger concept.
x0,y0=34,112
back=Image.open(OUT/'01-central-arrival.png').crop((0,112,1600,926)).resize((844,390))
image.paste(back,(x0,y0))
d=ImageDraw.Draw(image)
d.rectangle((x0+16,y0+16,x0+176,y0+64),fill='#1c3337')
d.text((x0+32,y0+33),'HISTORIC CORE',font=bold,fill='#eee8d7')
x,y=x0+16,y0+78
d.rectangle((x,y,x+238,y+88),fill='#162327')
d.rectangle((x,y,x+3,y+88),fill='#d3bd82')
for i,line in enumerate(['S1  •  AUTOMATIC','Civitas Central','Departs in 18s · doors open']):
    d.text((x+14,y+12+i*21),line,font=font,fill='#eee8d7')
d.text((34,530),'SEATED PASSENGER PANEL · REPLACES THE SERVICE BOARD',font=bold,fill='#d3bd82')
x,y=34,565
d.rectangle((x,y,x+260,y+110),fill='#161c22')
d.text((x+12,y+7),'S1 · Civitas Central',font=font,fill='#eef1f3')
d.text((x+12,y+27),'Doors open - alighting available',font=font,fill='#eef1f3')
d.rectangle((x+12,y+53,x+248,y+99),fill='#1f262e')
d.text((x+45,y+68),'ALIGHT AT PLATFORM',font=font,fill='#eef1f3')
d.text((330,570),'SERVER AUTHORITY',font=bold,fill='#d3bd82')
d.text((330,599),'Stop, door, alignment and occupancy checks gate alighting.',font=font,fill='#eee8d7')
d.text((330,627),'Top-left placement leaves stock mobile movement controls clear.',font=font,fill='#eee8d7')
d.text((330,655),'Both panels hide when the planned-network map is open.',font=font,fill='#eee8d7')
d.text((34,725),'Backdrop: Blender geometry review. UI: source-dimension layout study, not a game screenshot.',font=small,fill='#b9cbc7')
d.text((34,752),'Gamepad, small-screen safe areas, seat carrying and replication still need Studio tests.',font=small,fill='#b9cbc7')
image.save(OUT/'08-service-interface-study.png')
print('Rendered service telemetry and explicitly labelled interface study')
