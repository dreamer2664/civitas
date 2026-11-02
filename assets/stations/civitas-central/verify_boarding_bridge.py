"""Test regenerated prototype GLB or FBX at one static, hypothetical aligned door.

The train and station are always GLB. Pass --fbx to reimport bridge FBXs.
"""
import bpy,os,runpy,sys
from mathutils import Vector
D=os.path.dirname(os.path.abspath(__file__))
if '--gltf' not in sys.argv: raise RuntimeError('Pass -- --gltf; build prototype GLBs first')
path='/tmp/civitas-boarding-bridge'
ns=runpy.run_path(os.path.join(D,'verify_boarding.py'))
s=bpy.context.scene

def check(pose,expect_missing):
 before={o.as_pointer() for o in s.objects}
 bridge=os.path.join(path,'boarding-bridge-'+pose+('.fbx' if '--fbx' in sys.argv else '.glb'))
 if '--fbx' in sys.argv: bpy.ops.import_scene.fbx(filepath=bridge)
 else: bpy.ops.import_scene.gltf(filepath=bridge)
 objects=[o for o in s.objects if o.as_pointer() not in before]
 root=next(o for o in objects if o.name=='BRIDGE_'+pose.upper()+'_ROOT')
 # Prototype origin is the door-aligned track centre at rail-top height.
 root.location=(-10/.28,-.9/.28,0);bpy.context.view_layer.update()
 proxy=next(o for o in objects if o.type=='MESH' and 'COLLISION' in o.name)
 ys=[((proxy.matrix_world@v.co).y*.28+.9) for v in proxy.data.vertices]
 extent=max(abs(y) for y in ys)
 assert abs(extent-(1.6 if pose=='stowed' else 1.78))<.002,(pose,extent)
 c=ns['tree'](True); missing=[]
 for dx in (-.28,0,.28):
  for i in range(141):
   y=-1.8-i*.01
   hit=c.ray_cast(Vector((-10+dx,y,.86)),Vector((0,0,-1)),.2)[0]
   if hit is None or abs(hit.z-.76)>.015: missing.append((dx,y))
 if expect_missing: assert missing,('expected exposed gap',pose)
 else: assert not missing,('uncovered samples',pose,missing[:10])
 print('BRIDGE_POSE',pose,'extent_m',round(extent,3),'missing_support_samples',len(missing),'of',3*141)
 for o in objects:bpy.data.objects.remove(o,do_unlink=True)
check('stowed',True);check('deployed',False)
print('BRIDGE_SAMPLE_PASS', 'FBX' if '--fbx' in sys.argv else 'GLB', ': deployed prototype supports 423 sampled points over the representative 0.56m-wide boarding corridor')
print('SAFETY LIMIT: static aligned Blender reimports only; no articulation, interlocks, service placement, moving-train clearance, Studio physics or avatar test')
