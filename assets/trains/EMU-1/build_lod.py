"""Create static far-LOD candidates from evaluated high-detail car meshes.

Run on EMU-1.blend. Doors/pantograph are baked in frame-1 pose; no collision.
"""
import bpy, os
from mathutils import Vector
D=os.path.dirname(os.path.abspath(__file__)); s=bpy.context.scene; s.frame_set(1); dg=bpy.context.evaluated_depsgraph_get()
original=list(s.objects); lodroots=[]
for car in ('CAB','INTERMEDIATE'):
 root=bpy.data.objects[car+'_ROOT']; parent=bpy.data.objects.new(car+'_LOD1_ROOT',None); s.collection.objects.link(parent); parent.location=root.matrix_world.translation.copy(); lodroots.append(parent)
 components=[]
 for ob in original:
  if ob.type!='MESH' or 'COLLISION' in ob.name: continue
  p=ob
  while p and p!=root: p=p.parent
  if p!=root: continue
  ev=ob.evaluated_get(dg); mesh=bpy.data.meshes.new_from_object(ev,depsgraph=dg); mesh.transform(root.matrix_world.inverted() @ ev.matrix_world)
  part=bpy.data.objects.new(car+'_LOD_component',mesh); s.collection.objects.link(part); part.parent=parent; components.append(part)
 bpy.ops.object.select_all(action='DESELECT')
 for ob in components: ob.select_set(True)
 bpy.context.view_layer.objects.active=components[0]; bpy.ops.object.join(); joined=bpy.context.object; joined.name=car+'_LOD1_VISUAL'
 modifier=joined.modifiers.new('Far LOD collapse','DECIMATE'); modifier.decimate_type='COLLAPSE'; modifier.ratio=.20
 bpy.ops.object.modifier_apply(modifier=modifier.name)
for ob in original: bpy.data.objects.remove(ob,do_unlink=True)
s.render.engine='BLENDER_WORKBENCH'; s.display.shading.light='STUDIO'; s.display.shading.color_type='MATERIAL'; s.display.shading.show_shadows=True; s.display.shading.show_cavity=True
s.render.resolution_x=1400; s.render.resolution_y=700; s.render.resolution_percentage=100
camera=bpy.data.cameras.new('LOD_camera'); cam=bpy.data.objects.new('LOD_camera',camera); s.collection.objects.link(cam);cam.location=(16,-55,24);cam.rotation_euler=(Vector((-20,0,1.4))-cam.location).to_track_quat('-Z','Y').to_euler();camera.type='ORTHO';camera.ortho_scale=49;s.camera=cam
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(D,'EMU-1-LOD1.blend'))
s.render.filepath=os.path.join(D,'renders','lod1.png'); bpy.ops.render.render(write_still=True)
print('LOD1 generated at 20% collapse from evaluated frame-1 visual geometry')
