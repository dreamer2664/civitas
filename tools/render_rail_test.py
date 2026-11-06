#!/usr/bin/env python3
"""Draw an approximate model of the isolated procedural rail-test scene, not a Studio screenshot."""
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

root = Path(__file__).resolve().parents[1]
fig = plt.figure(figsize=(14, 8), facecolor='#0e1216')
ax = fig.add_axes([0.04,0.06,0.92,0.75], projection='3d', facecolor='#161c22', computed_zorder=False)
fig.text(.06,.93,'CIVITAS  /  ISOLATED RAIL TEST',color='#eef1f3',fontsize=22,weight='bold')
fig.text(.06,.88,'Procedural geometry concept  •  not a Roblox Studio screenshot',color='#aeb8c1',fontsize=11)

counter = 0
def box(x,y,z,dx,dy,dz, color, edge='#253037'):
    global counter
    counter += 1
    v = [(x,y,z),(x+dx,y,z),(x+dx,y+dy,z),(x,y+dy,z),
         (x,y,z+dz),(x+dx,y,z+dz),(x+dx,y+dy,z+dz),(x,y+dy,z+dz)]
    faces = [[v[i] for i in ids] for ids in [(0,1,2,3),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]]
    ax.add_collection3d(Poly3DCollection(faces,facecolors=color,edgecolors=edge,linewidths=.35,alpha=1,zorder=counter))
# Here plot axes are world X, Z, Y. Cropped to the station end of the 1200-stud test line.
box(25,-45,-2,270,90,2,'#566b4f')
box(25,-8.5,0,270,17,.5,'#615e55')
for x in range(30, 300, 15): box(x,-5.5,.43,2,11,.3,'#584639')
for z in [-3.2,3.2]: box(25,z-.25,.5,270,.5,.5,'#92999a')
box(45,-21.5,0,230,15,2,'#aaa797')
box(45,-7.5,2.04,230,1,.08,'#d9c27e')
box(138,-4.5,1.5,44,9,7,'#cfd5d0')
box(139,-4.58,4.85,36,9.16,2.3,'#1e3d46')
box(138,-4.6,8.5,44,9.2,.5,'#636d6d')
box(173.5,-1.5,9,3,3,1,'#283034')
ax.set_xlim(25,295); ax.set_ylim(-48,40); ax.set_zlim(0,38)
ax.set_box_aspect((270,88,38), zoom=1.6); ax.view_init(elev=23,azim=-60)
ax.set_axis_off()
fig.text(.06,.07,'Single test train  /  1,200-stud straight track  /  platform spawn',color='#aeb8c1',fontsize=10)
fig.savefig(root/'tools/world/renders/rail-test-concept.png',dpi=140,facecolor=fig.get_facecolor())
print('Rendered isolated rail-test concept (not a Studio screenshot).')
