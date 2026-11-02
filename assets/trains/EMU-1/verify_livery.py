"""Inspect blue body livery in the exported GLB via Blender reimport."""
import bpy,os
from collections import Counter
from mathutils import Vector
D=os.path.dirname(os.path.abspath(__file__))
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=os.path.join(D,'EMU-1.glb'))
counts=Counter(); heights={};uv_count=0
for o in bpy.context.scene.objects:
 if o.type!='MESH':continue
 for poly in o.data.polygons:
  mat=o.material_slots[poly.material_index].material
  if not mat or mat.name!='livery_blue':continue
  car='INTERMEDIATE' if o.name.startswith('INTERMEDIATE_') else 'CAB' if o.name.startswith('CAB_') else None
  assert car,('unexpected blue mesh',o.name)
  assert o.data.uv_layers.active,('missing UV',o.name)
  image_nodes=[n for n in mat.node_tree.nodes if n.type=='TEX_IMAGE' and n.image]
  assert image_nodes,('missing image texture',mat.name)
  centre=sum((o.matrix_world @ o.data.vertices[i].co for i in poly.vertices),Vector())/len(poly.vertices)
  side='R' if centre.y>0 else 'L'
  counts[(car,side)]+=1;heights.setdefault((car,side),[]).append(centre.z*.28)
  for li in poly.loop_indices:
   u,v=o.data.uv_layers.active.data[li].uv
   assert .75 < u < 1 and 0 < v < .25,('blue swatch UV outside bounds',o.name,u,v)
   uv_count+=1
assert len(counts)==4 and all(n==108 for n in counts.values()),counts
# Blue material spans the low belt and the tops of the doorway surrounds on both sides.
for key,z in heights.items():assert min(z)<1.4 and max(z)>2.75,(key,min(z),max(z))
print('LIVERY_GLB_PASS',sum(counts.values()),'blue triangles, four car-sides,',uv_count,'UV loop samples inside blue atlas swatch')
print('LIMIT: GLB reimport only; not visual approval, FBX or Roblox importer/material verification')
