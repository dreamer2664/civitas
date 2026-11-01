"""Shared export and evaluated-mesh audit. Called by asset-local exporters."""
import bpy, bmesh, json, os
from mathutils import Vector
S=1/.28
def audit(objects, path):
 deps=bpy.context.evaluated_depsgraph_get(); stats={}; sums={'render_triangles':0,'collision_triangles':0}; largest=0
 for o in objects:
  if o.type!='MESH': continue
  ev=o.evaluated_get(deps); me=ev.to_mesh(); me.calc_loop_triangles(); triangles=len(me.loop_triangles)
  bm=bmesh.new(); bm.from_mesh(me); bad=sum(1 for e in bm.edges if not e.is_manifold); bm.free()
  collision='COLLISION' in o.name; key='collision_triangles' if collision else 'render_triangles'; sums[key]+=triangles; largest=max(largest,triangles)
  points=[o.matrix_world @ Vector(c) for c in o.bound_box]
  dims=[round((max(v[i] for v in points)-min(v[i] for v in points))*S,3) for i in range(3)]
  stats[o.name]={'triangles':triangles,'nonmanifold_edges':bad,'world_aabb_studs_blender_xyz':dims,'collision':collision}
  ev.to_mesh_clear()
 result={'status':'design study, not validated in Studio','units':'1 metre = 3.571428571 studs','summary':sums,'max_mesh_triangles':largest,'meshes':stats}
 with open(path,'w') as f: json.dump(result,f,indent=2,sort_keys=True)
 print('AUDIT',os.path.basename(path),sums,'max_mesh_triangles',largest,'nonmanifold_edges',sum(x['nonmanifold_edges'] for x in stats.values()))
 assert largest<=20000, 'Individual evaluated mesh exceeds Roblox 20,000 triangle limit'
def exports(objects,roots,base):
 # Scaling only top-level roots keeps their child and pivot relationships intact.
 for r in roots: r.location*=S; r.scale*=S
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects: o.select_set(True)
 bpy.context.view_layer.objects.active=roots[0]
 bpy.ops.export_scene.fbx(filepath=base+'.fbx',use_selection=True,object_types={'EMPTY','MESH'},axis_forward='-Z',axis_up='Y',apply_unit_scale=False,global_scale=1.0,add_leaf_bones=False,mesh_smooth_type='FACE',use_mesh_modifiers=True)
 bpy.ops.export_scene.gltf(filepath=base+'.glb',export_format='GLB',use_selection=True,export_yup=True,export_apply=True)
 print('EXPORTED',base+'.fbx',base+'.glb')
