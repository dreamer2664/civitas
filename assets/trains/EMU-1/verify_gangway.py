"""Sample straight-pose gangway floor and inspect visual opening; no runtime physics."""
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree
D=bpy.context.evaluated_depsgraph_get()
def gather(coll):
 verts=[];faces=[]
 for ob in bpy.context.scene.objects:
  if ob.type!='MESH' or ('COLLISION' in ob.name)!=coll: continue
  ev=ob.evaluated_get(D);me=ev.to_mesh();base=len(verts);verts.extend(ev.matrix_world@v.co for v in me.vertices);faces.extend([base+i for i in p.vertices] for p in me.polygons);ev.to_mesh_clear()
 return BVHTree.FromPolygons(verts,faces,epsilon=.000001)
visual=gather(False);coll=gather(True)
for i in range(15):
 x=-20.84-(21.66-20.84)*i/14
 h,*_=coll.ray_cast(Vector((x,0,.83)),Vector((0,0,-1)),.16)
 if not h or abs(h.z-.76)>.005: raise AssertionError(('missing gangway floor proxy',x,h))
for z in (1.0,1.7,2.5):
 h,*_=visual.ray_cast(Vector((-20.7,0,z)),Vector((-1,0,0)),1.1)
 if h: raise AssertionError(('gangway visual blocked',z,h))
print('GANGWAY_PASS: 15 floor samples and 3 forward rays in straight pose')
print('NOTE: not a curved-track, door, dynamic collision or Studio walk test')
