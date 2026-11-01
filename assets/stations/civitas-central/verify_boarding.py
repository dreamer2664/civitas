"""Sample a hypothetical EMU/platform seam in Blender metres, not Studio physics.

The intermediate car is positioned to put one left door at x=-10 m, facing
platform 2 on the proposed z=3403.214 stud track. This is a placement test,
not an operating train or a proof of boarding.
"""
import bpy,os,sys
from mathutils import Vector
from mathutils.bvhtree import BVHTree
D=os.path.dirname(os.path.abspath(__file__)); TRAIN=os.path.abspath(os.path.join(D,'..','..','trains','EMU-1','EMU-1.blend'))
s=bpy.context.scene
scale=.28 if '--gltf' in sys.argv else 1.0
if scale!=1:
 bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.gltf(filepath=os.path.join(D,'civitas-central.glb'))
 before={o.as_pointer() for o in s.objects}
 bpy.ops.import_scene.gltf(filepath=os.path.join(os.path.dirname(TRAIN),'EMU-1.glb'))
 loaded=[o for o in s.objects if o.as_pointer() not in before and o.type in {'MESH','EMPTY'}]
else:
 with bpy.data.libraries.load(TRAIN,link=False) as (source,dest): dest.objects=list(source.objects)
 loaded=[o for o in dest.objects if o and o.type in {'MESH','EMPTY'}]
 for o in loaded:
  if not o.users_collection: s.collection.objects.link(o)
root=next(o for o in loaded if o.name=='INTERMEDIATE_ROOT')
root.location=(-4.6/scale,-.9/scale,0)
print('BOARDING_CHECK_MODE', 'GLB reimport (Blender)' if scale!=1 else 'source blend')
def in_car(o):
 while o:
  if o==root:return True
  o=o.parent
 return False
# Keep only station plus the intermediate car; leave high-detail object links intact.
for o in loaded:
 if not in_car(o): bpy.data.objects.remove(o,do_unlink=True)
def tree(collision):
 dg=bpy.context.evaluated_depsgraph_get();vs=[];polys=[]
 for ob in s.objects:
  if ob.type!='MESH' or ('COLLISION' in ob.name)!=collision:continue
  ev=ob.evaluated_get(dg);me=ev.to_mesh();base=len(vs);vs.extend((ev.matrix_world@v.co)*scale for v in me.vertices);me.calc_loop_triangles();polys.extend([[base+i for i in t.vertices] for t in me.loop_triangles]);ev.to_mesh_clear()
 return BVHTree.FromPolygons(vs,polys,all_triangles=True,epsilon=0)
def cross_hit(frame):
 s.frame_set(frame);t=tree(False)
 return t.ray_cast(Vector((-10.25,-2.0,1.65)),Vector((0,-1,0)),1.25)[0]
closed=cross_hit(1);opened=cross_hit(24)
print('DOOR_TEST closed_has_visual_hit=',bool(closed),'open_has_visual_hit=',bool(opened))
assert closed is not None and opened is None, (closed,opened)
# Sample the supporting proxy mesh at 1cm intervals between train and platform.
s.frame_set(24);c=tree(True);missing=[]
for i in range(61):
 y=-2.10-i*.01
 hit=c.ray_cast(Vector((-10,y,.86)),Vector((0,0,-1)),.2)[0]
 if hit is None or abs(hit.z-.76)>.015:missing.append(y)
assert missing, 'Expected gap changed; inspect and update the reported seam'
gap=(max(missing)-min(missing))+.01
print('BOARDING_PROXY_GAP approximately_m=',round(gap,3),'studs=',round(gap/.28,3),'step_m=',.01)
print('LIMIT: static representative pose, no Roblox character controller; gap traversability is not established')
