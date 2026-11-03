"""Sample conditional apron joined to exported station in Blender, not to city."""
import bpy,os,runpy,sys
from mathutils import Vector
D=os.path.dirname(os.path.abspath(__file__))
if '--gltf' not in sys.argv:raise RuntimeError('Use -- --gltf after building the candidate')
v=runpy.run_path(os.path.join(D,'verify_station.py'))
bpy.ops.import_scene.gltf(filepath='/tmp/civitas-apron-candidate/conditional-apron.glb')
bpy.context.view_layer.update();v['dg'].update()
coll=v['build_tree'](True);visual=v['build_tree'](False)
lo=.63*.28;hi=.76;run=(hi-lo)*12;n=0
for dx in (-.6,-.3,0,.3,.6):
 for i in range(181):
  y=27.905+(28+run+1.795-27.905)*i/180
  z=hi if y<=28 else lo if y>=28+run else hi-(y-28)/12
  hit=coll.ray_cast(Vector((dx,y,z+.1)),Vector((0,0,-1)),.22)[0]
  assert hit is not None and abs(hit.z-z)<.015,('floor',dx,y,z,hit)
  for tree in (coll,visual):
   obstruction=tree.ray_cast(Vector((dx,y,z+.05)),Vector((0,0,1)),2)[0]
   assert obstruction is None,('headroom',dx,y,z,obstruction)
  n+=1
print('CONDITIONAL_APRON_PASS',n,'floor/headroom samples, 1.2m corridor; station threshold to hypothetical lower landing')
print('LIMIT: no city geometry present, no sidewalk join, continuous sweep, guardrails, approval, accessibility or Studio verification')
