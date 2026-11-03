"""Compare GLB surfaces, per category, including oriented normals in Blender."""
import bpy, os
from collections import Counter
from mathutils import Vector
from mathutils.bvhtree import BVHTree
D=os.path.dirname(os.path.abspath(__file__))
KINDS=tuple(f'{kind}_{layer}' for kind in ('edge','coping','tactile','canopy','bench','bin','lamp','gantry','surface') for layer in ('VISUAL','COLLISION'))

def import_glb(name, mirror=False):
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.gltf(filepath=os.path.join(D,name)); groups={}; bad=[]; counts=Counter()
 for o in bpy.context.scene.objects:
  if o.type not in {'MESH','EMPTY'}: continue
  if o.matrix_world.to_3x3().determinant() <= 1e-8: bad.append(o.name)
  if o.type!='MESH': continue
  kinds=[k for k in KINDS if k in o.name]
  assert len(kinds)==1,('unclassified/ambiguous mesh',o.name,kinds)
  kind=kinds[0];counts[kind]+=1;o.data.calc_loop_triangles()
  verts,faces=groups.setdefault(kind,([],[])); start=len(verts)
  for v in o.data.vertices:
   v=o.matrix_world@v.co
   verts.append(Vector((v.x,-v.y,v.z)) if mirror else v)
  for face in o.data.loop_triangles:
   f=[start+i for i in face.vertices]
   faces.append(tuple(reversed(f)) if mirror else tuple(f))
 return groups,bad,counts

def compare(a,b,kind):
 verts,faces=a;other,otherfaces=b;tree=BVHTree.FromPolygons(other,otherfaces,all_triangles=True)
 tested=0
 for f in faces:
  v0,v1,v2=(verts[i] for i in f);cross=(v1-v0).cross(v2-v0)
  if cross.length<1e-9: continue
  centre=(v0+v1+v2)/3
  matches=tree.find_nearest_range(centre,0.002)
  assert matches,('surface mismatch',kind,tuple(centre))
  assert any(normal.dot(cross.normalized())>.99 for _,normal,_,_ in matches),('winding mismatch',kind,tuple(centre),[normal.dot(cross.normalized()) for _,normal,_,_ in matches])
  tested+=1
 return tested
base,base_bad,base_counts=import_glb('platform-module.glb',True)
reflected,bad,reflected_counts=import_glb('platform-module-reflected.glb')
assert not base_bad and not bad,('non-positive transform',base_bad,bad)
assert base_counts==reflected_counts,('object counts',base_counts,reflected_counts)
assert base.keys()==reflected.keys(),(base.keys(),reflected.keys())
n=0
for kind in sorted(base):
 n+=compare(base[kind],reflected[kind],kind)
 n+=compare(reflected[kind],base[kind],kind)
print('REFLECTED_MODULE_PASS',sum(base_counts.values()),'meshes;',n,'triangle-centre surface and winding comparisons in both directions; positive transforms')
print('LIMIT: Blender GLB reimport, sampled triangle centres only; verify shading, materials and collision in Roblox Studio')
