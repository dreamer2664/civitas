"""Render the experimental deployed FBX in the aligned station/train test pose.

This is a Blender rendering, not a Studio screenshot or runtime verification.
Run after building the bridge FBX and pass -- --gltf.
"""
import bpy,os,runpy,sys
from mathutils import Vector
D=os.path.dirname(os.path.abspath(__file__))
if '--gltf' not in sys.argv:raise RuntimeError('Use -- --gltf after building prototype FBXs')
runpy.run_path(os.path.join(D,'verify_boarding.py'))
s=bpy.context.scene
before={o.as_pointer() for o in s.objects}
bpy.ops.import_scene.fbx(filepath='/tmp/civitas-boarding-bridge/boarding-bridge-deployed.fbx')
objects=[o for o in s.objects if o.as_pointer() not in before]
root=next(o for o in objects if o.name=='BRIDGE_DEPLOYED_ROOT');root.location=(-10/.28,-.9/.28,0)
for o in s.objects:
 if o.type!='MESH': continue
 # Explicit explanatory cutaway: retain the test car, bridge and platform edge;
 # hide the station canopy and unrelated architecture that obscure the view.
 is_car=o.name.startswith('INTERMEDIATE_')
 is_edge=o.name.startswith('PLATFORM_2_MODULE_') and any(k in o.name for k in ('surface_VISUAL','edge_VISUAL','coping_VISUAL','tactile_VISUAL'))
 is_bridge=o in objects and 'VISUAL' in o.name
 o.hide_render=('COLLISION' in o.name or not (is_car or is_edge or is_bridge))
for o in objects:
 if o.type=='MESH' and 'VISUAL' in o.name:
  m=bpy.data.materials.new('RENDER_ONLY_HIGHLIGHT');m.diffuse_color=(1,.44,.06,1);o.data.materials.clear();o.data.materials.append(m)
s.frame_set(24)
bpy.ops.object.camera_add(location=Vector((-8.3,-4.9,2.9))/.28);camera=bpy.context.object
camera.name='RENDER_ONLY_BOARDING_CAMERA';target=Vector((-10,-2.55,1.05))/.28
camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=4.3/.28;s.camera=camera
s.render.engine='BLENDER_WORKBENCH';s.display.shading.light='STUDIO';s.display.shading.color_type='MATERIAL';s.display.shading.show_shadows=True;s.display.shading.show_cavity=True
s.render.resolution_x=1400;s.render.resolution_y=900;s.render.resolution_percentage=100
s.render.image_settings.file_format='PNG';s.render.filepath=os.path.join(D,'renders','boarding-bridge-deployed.png');s.render.film_transparent=False
bpy.ops.render.render(write_still=True)
print('BOARDING_RENDER',s.render.filepath,'Blender Workbench CUTAWAY; orange highlight and hidden architecture are render-only')
