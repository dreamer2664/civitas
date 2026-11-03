"""Audit stowed vehicle-mounted bridge geometry and one manually deployed seam.

Uses Blender GLB or FBX reimport for the vehicle graph, not Studio or a runtime safety controller.
The seam check always uses station and vehicle GLBs.
"""
import bpy,os,runpy,sys
from mathutils import Vector
D=os.path.dirname(os.path.abspath(__file__))
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
if '--fbx' in sys.argv: bpy.ops.import_scene.fbx(filepath=os.path.join(D,'EMU-1.fbx'))
else: bpy.ops.import_scene.gltf(filepath=os.path.join(D,'EMU-1.glb'))
for car,length in (('CAB',21),('INTERMEDIATE',20)):
 root=bpy.data.objects[car+'_ROOT']
 for side,label in ((-1,'L'),(1,'R')):
  for i,doorx in enumerate((-length*.27,-length*.73)):
   n=f'{car}_{label}_BRIDGE_{i}';p=bpy.data.objects[n+'_PIVOT'];assert p.parent==root,(n,'wrong parent')
   visual=bpy.data.objects[n+'_VISUAL'];proxy=bpy.data.objects[n+'_COLLISION']
   assert visual.parent==p and proxy.parent==p,(n,'wrong children')
   start=p.location.copy(); assert (start-Vector((doorx,side*1.47,.70))).length<.0001,(n,start)
   for state in ('stowed','deployed'):
    p.location=start+Vector((0,side*.18,.04)) if state=='deployed' else start
    bpy.context.view_layer.update()
    for o in (visual,proxy):
     points=[root.matrix_world.inverted()@o.matrix_world@v.co for v in o.data.vertices]
     dims=[max(v[a] for v in points)-min(v[a] for v in points) for a in range(3)]
     extent=max(abs(v.y) for v in points);top=max(v.z for v in points)
     assert all(abs(dims[a]-d)<.0002 for a,d in enumerate((1.10,.26,.04))),(n,dims)
     assert abs(extent-(1.60 if state=='stowed' else 1.78))<.0002,(n,state,extent)
     assert abs(top-(.72 if state=='stowed' else .76))<.0002,(n,state,top)
   p.location=start
print('VEHICLE_BRIDGE_GRAPH_PASS', 'FBX' if '--fbx' in sys.argv else 'GLB', '8 mounts, each with visual and proxy, both sides and cars; stowed half-width 1.60m; simulated deployed 1.78m')
# Reload station and train GLBs and test one representative door, using the
# already committed static-pose boarding checker to establish the baseline.
if '--gltf' not in sys.argv:raise RuntimeError('Run with -- --gltf')
station=os.path.abspath(os.path.join(D,'..','..','stations','civitas-central'))
v=runpy.run_path(os.path.join(station,'verify_boarding.py'))
p=bpy.data.objects['INTERMEDIATE_L_BRIDGE_0_PIVOT'];p.location.y-=.18;p.location.z+=.04
bpy.context.view_layer.update();coll=v['tree'](True);miss=[]
for dx in (-.28,0,.28):
 for i in range(141):
  y=-1.8-i*.01;hit=coll.ray_cast(Vector((-10+dx,y,.86)),Vector((0,0,-1)),.2)[0]
  if hit is None or abs(hit.z-.76)>.015:miss.append((dx,y))
assert not miss,('deployed pose unsupported',miss[:10])
print('MOUNTED_BRIDGE_SEAM_PASS: 0/423 missing support points at one manually deployed intermediate door')
print('LIMIT: no runtime deployment, interlock, collision gating, variable stop, avatar or Studio validation')
