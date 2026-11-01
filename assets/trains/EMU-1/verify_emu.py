"""Reimport GLB in Blender and validate stock root and bogie pivot positions in studs."""
import bpy, os
D=os.path.dirname(os.path.abspath(__file__))
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=os.path.join(D,'EMU-1.glb'))
expected={'CAB_ROOT':0.0,'INTERMEDIATE_ROOT':-21.5/.28,'CAB_BOGIE_0_PIVOT':-3/.28,'CAB_BOGIE_1_PIVOT':-18/.28,'INTERMEDIATE_BOGIE_0_PIVOT':-24.5/.28,'INTERMEDIATE_BOGIE_1_PIVOT':-38.5/.28}
for name,x in expected.items():
 obj=bpy.data.objects.get(name)
 if obj is None: raise RuntimeError('Missing '+name)
 v=obj.matrix_world.translation
 print('PIVOT',name,tuple(round(q,4) for q in v))
 assert abs(v.x-x)<0.001 and abs(v.y)<0.001 and abs(v.z)<0.001, name
print('GLB pivot checks passed:',len(expected))
door=bpy.data.objects.get('CAB_L_door_0_-1_PIVOT')
assert door is not None
positions=[]
for frame in (1,6,24):
 bpy.context.scene.frame_set(frame); v=door.matrix_world.translation.copy(); positions.append(v)
 print('DOOR',frame,tuple(round(q,4) for q in v))
assert abs((positions[1]-positions[0]).y + .24/.28)<.001
assert abs((positions[2]-positions[1]).x + 1.35/.28)<.001
print('GLB door animation displacement checks passed')
# Wheelsets retain centred axle pivots after consolidation.
for car,length,origin in [('CAB',21,0),('INTERMEDIATE',20,-21.5)]:
 for bogie,x in enumerate((-3,-length+3)):
  for j,dx in enumerate((-.75,.75)):
   name=f'{car}_BOGIE_{bogie}_AXLE_{j}_PIVOT'; obj=bpy.data.objects.get(name)
   assert obj is not None, name
   v=obj.matrix_world.translation
   assert abs(v.x-(origin+x+dx)/.28)<.001 and abs(v.y)<.001 and abs(v.z-.42/.28)<.001,(name,tuple(v))
print('GLB axle pivot checks passed: 8')
