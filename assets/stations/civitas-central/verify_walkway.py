"""Dense deterministic walking-surface and headroom samples, not a humanoid sweep.

Run against the source blend or pass --gltf to test the exported GLB round-trip.
"""
import os,runpy,math
D=os.path.dirname(os.path.abspath(__file__))
v=runpy.run_path(os.path.join(D,'verify_station.py'))
floor_at,clear=v['floor_at'],v['clear']
count=0
def probe(x,y,z):
 global count
 floor_at(x,y,z);clear(x,y,z);count+=1
# A 1.2m-wide corridor at each door from inside threshold to platform 1.
for entrance in (-19.6,0,19.6):
 for dx in (-.6,-.3,0,.3,.6):
  for i in range(59):
   y=27.9-(27.9-13.4)*i/58;probe(entrance+dx,y,.76)
print('DENSE_ENTRANCE_PASS',count,'floor and 2m-headroom points, three 1.2m-wide corridors')
# Connect the west entrance through the concourse to the foot of platform 1's
# ramp, instead of assuming that independently clear segments join up.
for dy in (-.6,-.3,0,.3,.6):
 for i in range(78): probe(-19.6+(-39.0+19.6)*i/77,14.8+dy,.76)
for dx in (-.6,-.3,0,.3,.6):
 for i in range(16): probe(-39.0+dx,14.8+(11.2-14.8)*i/15,.76)
for dy in (-.6,-.3,0,.3,.6):
 for i in range(5): probe(-39.0+(-38.34+39.0)*i/4,11.2+dy,.76)
print('DENSE_CONCOURSE_TO_RAMP_PASS',count,'cumulative points')
# Sample both ramps at five lateral offsets and 0.25m longitudinal steps.
lo=.76;hi=7;run=(hi-lo)*12;nr=math.ceil(run/.25)
for centre in (11.2,-5.6):
 for dy in (-.6,-.3,0,.3,.6):
  for i in range(nr+1):
   x=-run/2-.9+run*i/nr; z=lo+(hi-lo)*i/nr;probe(x,centre+dy,z)
print('DENSE_RAMPS_PASS',count,'cumulative points, 1.2m usable corridor')
# Link the two ramp heads across the bridge, within its 1.8m deck width.
for dx in (-.6,-.3,0,.3,.6):
 for i in range(69): probe(run/2+dx,-5.6+16.8*i/68,hi)
print('DENSE_BRIDGE_PASS',count,'total sampled positions')
print('LIMIT: sampled vertical rays, not continuous swept volume, avatar steps, Studio collision or outside sidewalk')
