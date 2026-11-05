#!/usr/bin/env python3
"""Concept rendering of the in-city experimental platform and shuttle, from exported plan data.

This is an explanatory diagram, not a Roblox screenshot or physics verification.
"""
from pathlib import Path
import json
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

root = Path(__file__).resolve().parents[2]
station = json.loads((root/'tools/world/generated-plan.json').read_text())['station']
fig = plt.figure(figsize=(14, 8), facecolor='#0e1216')
ax = fig.add_axes([.02,.08,.96,.72], projection='3d', computed_zorder=False, facecolor='#161c22')
fig.text(.06,.93,'CIVITAS  /  CENTRAL TEST PLATFORM',color='#eef1f3',fontsize=21,weight='bold')
fig.text(.06,.875,'Procedural station and shuttle concept  •  not a Roblox Studio screenshot',color='#aeb8c1',fontsize=11)
order = 0

def poly(faces, color, edge='#46504d'):
    global order
    order += 1
    ax.add_collection3d(Poly3DCollection(faces, facecolors=color, edgecolors=edge, linewidths=.35, zorder=order))

def box(cx, cz, base, w, d, h, color):
    x,z = cx-w/2, cz-d/2
    p=[(x,z,base),(x+w,z,base),(x+w,z+d,base),(x,z+d,base),
       (x,z,base+h),(x+w,z,base+h),(x+w,z+d,base+h),(x,z+d,base+h)]
    faces=[[p[i] for i in ids] for ids in [(0,1,2,3),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),(4,5,6,7)]]
    poly(faces,color)

x=station['centerX']; z=station['railCenterZ']; top=station['platformTopY']; rt=station['railTopY']
box(x,950,-2,310,220,2,'#657859')
box(x,station['concourseZ'],.13,station['width']-20,station['depth']*.55,.5,'#b9b1a2')
for side in (-1,1):
    box(x+side*(station['width']/2-7),station['concourseZ'],0,8,station['depth']*.55,19,'#c2b69b')
    width=(station['width']-20-24)/2
    box(x+side*(12+width/2),station['concourseZ']+station['depth']*.275,0,width,8,19,'#c2b69b')
box(x,station['concourseZ']+station['depth']*.275,14,24,8,5,'#c2b69b')
box(x,z,0,310,12,.18,'#5c574e')
for s in (-1,1): box(x,z+s*2.56285,rt-.25,310,.25,.25,'#929b9a')
for tx in range(int(x-145),int(x+146),8): box(tx,z,.1,.8,9,.22,'#584639')
box(x,station['platformCenterZ'],top-.8,station['platformWidth'],station['platformDepth'],.8,'#b8b3a5')
box(x,station['platformCenterZ']+station['platformDepth']/2-1.1,top,station['platformWidth'],2.14,.08,'#d3bd82')
z0,z1=station['rampStartZ'],station['rampEndZ']
poly([[(x-10,z0,.63),(x+10,z0,.63),(x+10,z1,top),(x-10,z1,top)]], '#b8b3a5')
for offset in (-80,-40,40,80): box(x+offset,station['platformCenterZ']-5,top,1.2,1.2,12,'#445356')
for offset in (-50,50):
    box(x+offset,station['platformCenterZ']-2,top+1.55,9,2,.5,'#826141')
    for side in (-1,1): box(x+offset+side*3.5,station['platformCenterZ']-2,top,.5,1.8,1.6,'#445356')
box(x,station['platformCenterZ'],top+12,station['platformWidth']-4,station['platformDepth']-5,.8,'#4c5c60')
lengths=[75,71.4286]; total=sum(lengths)+1.7857
centers=[x-total/2+37.5, x-total/2+75+1.7857+71.4286/2]
bodybottom=rt+3; bodyheight=11.1429
for cx, length in zip(centers,lengths):
    box(cx,z,bodybottom,length,10.1786,bodyheight,'#d3d8d2')
    box(cx,z,bodybottom+bodyheight,length,10.3786,.65,'#5f6a6b')
    for side in (-1,1):
        face=z+side*(10.1786/2+.1)
        box(cx,face,bodybottom+5.5,length*.84,.22,3.6,'#1d434b')
        for off in (-length*.25,length*.25): box(cx+off,face+side*.12,bodybottom,4.6429,.3,6.9643,'#9b3930')
ax.set_xlim(x-160,x+160); ax.set_ylim(850,1070); ax.set_zlim(0,60)
ax.set_box_aspect((320,220,60),zoom=1.2); ax.view_init(elev=29,azim=-58); ax.set_axis_off()
fig.text(.06,.06,'Ramp to platform  /  single test track  /  two-car placeholder train',color='#aeb8c1',fontsize=10)
fig.savefig(root/'tools/world/renders/station-shuttle-concept.png',dpi=150,facecolor=fig.get_facecolor())
print('Rendered station/shuttle concept (not a Studio screenshot).')
