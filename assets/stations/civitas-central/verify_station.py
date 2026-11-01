"""Geometric route sampling in Blender; not a Roblox navigation or physics test."""
import bpy, os, sys
from mathutils import Vector
from mathutils.bvhtree import BVHTree
scale=.28 if '--gltf' in sys.argv else 1.0
if scale!=1.0:
 bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
 path=os.path.join(os.path.dirname(os.path.abspath(__file__)),'civitas-central.glb')
 bpy.ops.import_scene.gltf(filepath=path)
 expected={'PLATFORM_1_MODULE_1':(-20,11.2,.76),'PLATFORM_1_MODULE_2':(20,11.2,.76),'PLATFORM_2_MODULE_1':(-20,-5.6,.76),'PLATFORM_2_MODULE_2':(20,-5.6,.76)}
 for name,position in expected.items():
  obj=bpy.data.objects.get(name)
  assert obj is not None, 'Missing '+name
  actual=obj.matrix_world.translation*scale
  assert all(abs(actual[i]-position[i])<.001 for i in range(3)), (name,actual,position)
 print('GLB_MODULE_TRANSFORMS_PASS',len(expected),'axis round-trip in Blender, stud-scaled')
print('ROUTE_CHECK_MODE','GLB reimport (Blender)' if scale!=1.0 else 'source blend')
s=bpy.context.scene; dg=bpy.context.evaluated_depsgraph_get()
def build_tree(collision):
 vertices=[]; polygons=[]; n=0
 for ob in s.objects:
  if ob.type!='MESH' or ('COLLISION' in ob.name)!=collision: continue
  ev=ob.evaluated_get(dg); me=ev.to_mesh(); start=len(vertices)
  vertices += [(ev.matrix_world@v.co)*scale for v in me.vertices]
  me.calc_loop_triangles()
  polygons += [[start+i for i in p.vertices] for p in me.loop_triangles]; n+=1; ev.to_mesh_clear()
 print('ROUTE_MESHES', 'collision' if collision else 'visual',n)
 return BVHTree.FromPolygons(vertices,polygons,all_triangles=True,epsilon=0.0)
coll=build_tree(True); visual=build_tree(False)
def hit(tree,origin,direction,distance):
 return tree.ray_cast(Vector(origin),Vector(direction).normalized(),distance)[0]
def floor_at(x,y,z):
 p=hit(coll,(x,y,z+.10),(0,0,-1),.22)
 if not p or abs(p.z-z)>.015: raise AssertionError(('missing collision walking surface',x,y,z,p))
def clear(x,y,z):
 p=hit(coll,(x,y,z+.05),(0,0,1),2.0)
 if p: raise AssertionError(('insufficient proxy headroom',x,y,z,p))
 p=hit(visual,(x,y,z+.05),(0,0,1),2.0)
 if p: raise AssertionError(('insufficient visual headroom',x,y,z,p))
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
  x=-run/2-.9+run*i/24; z=lo+(hi-lo)*i/24
  floor_at(x,y,z); clear(x,y,z)
 print('RAMP_PASS',y,'m, 25 samples, 1:12; 2m proxy and visual headroom')
for i in range(25):
 y=-5.6+16.8*i/24; floor_at(run/2,y,hi); clear(run/2,y,hi)
print('BRIDGE_PASS 25 samples; underside 6.88m > 4.60m rail envelope; wire clearance not simulated')
# Straight line probes through each nominal train-envelope cross section.
# This detects obstructions along sampled lines, not a continuous volume sweep.
for centre in (6.5,-.9):
 for offset in (-1.6,0,1.6):
  for z in (.1,1.0,2.8,4.6):
   for tree,label in ((coll,'proxy'),(visual,'visual')):
    p=hit(tree,(-83.5,centre+offset,z),(1,0,0),167)
    if p: raise AssertionError(('through track obstruction',centre,offset,z,label,p))
 print('THROUGH_TRACK_PASS',centre,'m, 24 sampled lines each 167m long')
 for tree,label in ((coll,'proxy'),(visual,'visual')):
  p=hit(tree,(-83.5,centre,5.65),(1,0,0),167)
  if p: raise AssertionError(('overhead centreline obstruction',centre,label,p))
 print('PANTOGRAPH_CENTERLINE_PASS',centre,'m at 5.65m above rail')
print('NOTE: sampled geometric checks only, not a continuous sweep or Studio path test')
