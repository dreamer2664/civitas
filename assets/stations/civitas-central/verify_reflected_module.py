"""Compare both exported GLB variants in Blender and check transform signs."""
import bpy,os
from mathutils import Vector
D=os.path.dirname(os.path.abspath(__file__))

def import_glb(name):
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.gltf(filepath=os.path.join(D,name)); groups={}; negative=[]
 for o in bpy.context.scene.objects:
  if o.type not in {'MESH','EMPTY'}: continue
  if o.matrix_world.to_3x3().determinant() < -1e-5: negative.append(o.name)
  if o.type!='MESH': continue
  for kind in ('edge_VISUAL','coping_VISUAL','tactile_VISUAL','canopy_VISUAL','bench_VISUAL','bin_VISUAL','lamp_VISUAL','gantry_VISUAL','surface_VISUAL','surface_COLLISION'):
   if kind in o.name:
    groups.setdefault(kind,[]).extend(o.matrix_world@Vector(v.co) for v in o.data.vertices);break
 bounds={k:tuple((min(v[i] for v in points),max(v[i] for v in points)) for i in range(3)) for k,points in groups.items()}
 return bounds,negative
base,base_neg=import_glb('platform-module.glb'); reflected,neg=import_glb('platform-module-reflected.glb')
assert not base_neg and not neg,('negative transform',base_neg,neg)
assert base.keys()==reflected.keys(),(base.keys(),reflected.keys())
for kind in sorted(base):
 a=base[kind];b=reflected[kind];expected=(a[0],(-a[1][1],-a[1][0]),a[2])
 assert all(abs(expected[i][j]-b[i][j])<.002 for i in range(3) for j in range(2)),(kind,expected,b)
print('REFLECTED_MODULE_PASS',len(base),'category bounds match mirrored unreflected GLB; no negative object transforms')
print('LIMIT: Blender reimport and bounds only; verify rendering, normals and collision in Roblox Studio')
