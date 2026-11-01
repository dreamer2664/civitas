import bpy
from mathutils.bvhtree import BVHTree
s=bpy.context.scene
def tree(o):
 dg=bpy.context.evaluated_depsgraph_get(); ev=o.evaluated_get(dg); me=ev.to_mesh(); vs=[ev.matrix_world@v.co for v in me.vertices]; poly=[list(p.vertices) for p in me.polygons]; b=BVHTree.FromPolygons(vs,poly,all_triangles=False,epsilon=0.00001); ev.to_mesh_clear(); return b
issues=[]
for frame in range(1,25):
 s.frame_set(frame); errors=[]
 for o in s.objects:
  if o.type!='MESH' or not o.name.endswith('_leaf'):continue
  car=o.name.split('_')[0]; side=o.name.split('_')[1]
  leaf=tree(o)
  for t in s.objects:
   if t.type!='MESH' or not t.name.startswith(car+'_'+side+'_'):continue
   if not any(x in t.name for x in ['_side_','_pillar_','_door_header_']):continue
   if leaf.overlap(tree(t)): errors.append((o.name,t.name))
 if errors: issues.extend((frame,*e) for e in errors); print('FRAME',frame,'INTERSECTIONS',len(errors),errors[:2])
assert not issues, f'Door/body surface intersections: {len(issues)}'
print('Door/body surface overlap: 0 across frames 1-24, all 16 leaves')
