"""Additional platform-2-to-concourse geometric evidence, not a Roblox walk test.

Launch against a .blend or pass --gltf for Blender GLB re-import.
"""
import math,os,runpy
D=os.path.dirname(os.path.abspath(__file__))
v=runpy.run_path(os.path.join(D,'verify_walkway.py'))['v']
floor_at,hit=v['floor_at'],v['hit']; coll,visual=v['coll'],v['visual']; count=0

def probe(x,y):
 global count
 floor_at(x,y,.76)
 # Permit the visible 0.058m tactile studs (visual-only); test upper clearance.
 for tree,label in ((coll,'proxy'),(visual,'visual')):
  p=hit(tree,(x,y,.86),(0,0,1),1.96)
  if p: raise AssertionError(('platform access obstruction',label,x,y,p))
 count+=1
# Representative starting point on platform 2, not an asserted train door.
# 0.56 m transverse corridor, sampled in <=0.25 m steps.
for dx in (-.28,0,.28):
 for i in range(9): probe(-10+dx,-3.2+(-4+3.2)*i/8)
for dy in (-.28,0,.28):
 for i in range(117): probe(-10+(-39+10)*i/116,-4+dy)
for dx in (-.28,0,.28):
 for i in range(9): probe(-39+dx,-4+(-5.6+4)*i/8)
for dy in (-.28,0,.28):
 for i in range(5): probe(-39+(-38.34+39)*i/4,-5.6+dy)
print('PLATFORM2_TO_RAMP_PASS',count,'sample points, 0.56m corridor')
print('ROUTE_LIMIT: representative platform point only, not actual train doorway or continuous character sweep')
