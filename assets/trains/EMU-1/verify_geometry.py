"""Check visual envelopes and one cab sightline, in source-space metres."""
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree
scene=bpy.context.scene; dg=bpy.context.evaluated_depsgraph_get()
for rootname,expected in [('CAB_ROOT',(21,2.85,4.1)),('INTERMEDIATE_ROOT',(20,2.85,4.1))]:
 root=bpy.data.objects[rootname]; points=[]
 for obj in scene.objects:
  parent=obj
  while parent and parent!=root: parent=parent.parent
  if parent!=root or obj.type!='MESH' or 'COLLISION' in obj.name: continue
  ev=obj.evaluated_get(dg); me=ev.to_mesh(); points.extend(ev.matrix_world @ v.co for v in me.vertices); ev.to_mesh_clear()
 dims=tuple(max(p[i] for p in points)-min(p[i] for p in points) for i in range(3))
 print(rootname,'evaluated visual studs',tuple(round(x/.28,3) for x in dims))
 assert all(abs(dims[i]-expected[i])<.001 for i in range(3)), (rootname,dims)
start=Vector((-4.3,-.32,2.25)); end=Vector((4,-.32,2.25)); direction=(end-start).normalized(); blocked=[]; glazing=False
for obj in scene.objects:
 if obj.type!='MESH' or not obj.name.startswith('CAB_') or 'COLLISION' in obj.name: continue
 ev=obj.evaluated_get(dg); me=ev.to_mesh(); tree=BVHTree.FromPolygons([ev.matrix_world@v.co for v in me.vertices],[list(p.vertices) for p in me.polygons]); hit,normal,index,distance=tree.ray_cast(start,direction,(end-start).length); ev.to_mesh_clear()
 if hit:
  if 'windscreen_glazing' in obj.name: glazing=True
  else: blocked.append(obj.name)
assert glazing and not blocked, (glazing,blocked)
print('Cab forward eye-height sightline: glazing hit, no opaque render mesh hit')
