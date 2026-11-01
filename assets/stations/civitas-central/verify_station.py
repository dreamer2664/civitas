"""Geometric route sampling in Blender; not a Roblox navigation or physics test."""
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree
s=bpy.context.scene; dg=bpy.context.evaluated_depsgraph_get()
def build_tree(collision):
 vertices=[]; polygons=[]; n=0
 for ob in s.objects:
  if ob.type!='MESH' or ('COLLISION' in ob.name)!=collision: continue
  ev=ob.evaluated_get(dg); me=ev.to_mesh(); start=len(vertices)
  vertices += [ev.matrix_world@v.co for v in me.vertices]
  polygons += [[start+i for i in p.vertices] for p in me.polygons]; n+=1; ev.to_mesh_clear()
 print('ROUTE_MESHES', 'collision' if collision else 'visual',n)
 return BVHTree.FromPolygons(vertices,polygons,epsilon=.000001)
coll=build_tree(True); visual=build_tree(False)
def hit(tree,origin,direction,distance):
 return tree.ray_cast(Vector(origin),Vector(direction).normalized(),distance)[0]
def floor_at(x,y,z):
 p=hit(coll,(x,y,z+.10),(0,0,-1),.22)
 if not p or abs(p.z-z)>.015: raise AssertionError(('missing collision walking surface',x,y,z,p))
def clear(x,y,z):
 p=hit(coll,(x,y,z+.05),(0,0,1),2.0)
 if p: raise AssertionError(('insufficient proxy headroom',x,y,z,p))
for x in (-19.6,0,19.6):
 # Square threshold to platform 1, north wall: y=27.75 and seam y=14.
 for i in range(31): floor_at(x,27.9-(27.9-13.4)*i/30,.76)
 for z in (1.3,2.4):
  for tree,label in [(coll,'collision'),(visual,'visual')]:
   p=hit(tree,(x,28.1,z),(0,-1,0),14.7)
   if p: raise AssertionError(('blocked entrance',label,x,z,p))
 print('ENTRANCE_CLEAR',x,'m; floor y=27.9..13.4 at z=.76m')
lo=.76; hi=7.0; run=(hi-lo)*12
for y in (11.2,-5.6):
 for i in range(25):
  x=-run/2+run*i/24; z=lo+(hi-lo)*i/24
  floor_at(x,y,z); clear(x,y,z)
 print('RAMP_PASS',y,'m, 25 samples, 1:12; 2m proxy headroom')
for i in range(25):
 y=-5.6+16.8*i/24; floor_at(run/2,y,hi); clear(run/2,y,hi)
print('BRIDGE_PASS 25 samples; underside 6.88m > 4.60m rail envelope; wire clearance not simulated')
print('NOTE: sampled geometric checks only, not a continuous sweep or Studio path test')
