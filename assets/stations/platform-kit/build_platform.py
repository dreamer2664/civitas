"""Build a modular platform-kit design study in metres; Z is up, +X along platform."""
import bpy, os, math, sys
from mathutils import Vector
D=os.path.dirname(os.path.abspath(__file__))
bpy.context.preferences.filepaths.save_version=0
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
s=bpy.context.scene; s.unit_settings.system='METRIC'
def mat(n,c):
 m=bpy.data.materials.new(n); m.diffuse_color=(*c,1); return m
stone=mat('cast_concrete',(.53,.56,.54)); pale=mat('coping_stone',(.76,.76,.71)); yellow=mat('tactile_buff',(.73,.61,.32)); steel=mat('painted_steel',(.13,.19,.22)); wood=mat('bench_timber',(.43,.25,.12)); glass=mat('sign_offwhite',(.78,.80,.76)); black=mat('dark_detail',(.055,.075,.08))
def root(n,x,y):
 ob=bpy.data.objects.new(n,None); s.collection.objects.link(ob); ob.location=(x,y,0); ob['origin']='base centre on platform surface; +X along platform'; return ob
def box(n,loc,dim,ma,p):
 bpy.ops.mesh.primitive_cube_add(size=1); o=bpy.context.object; o.name=n; o.dimensions=dim; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); o.parent=p; o.location=loc; o.data.materials.append(ma); return o
def cyl(n,loc,r,depth,ma,p):
 bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=r,depth=depth); o=bpy.context.object; o.name=n; o.parent=p; o.location=loc; o.data.materials.append(ma); return o
# Assembly scene spaces modules apart for review; each root exports at scene origin.
e=root('edge',0,0); box('edge_visual',(0,0,-.38),(4,.45,.76),stone,e); box('edge_COLLISION',(0,0,-.38),(4,.45,.76),stone,e).hide_render=True
c=root('coping',5.2,0); box('coping_visual',(0,0,.035),(4,.35,.07),pale,c); box('coping_COLLISION',(0,0,.035),(4,.35,.07),pale,c).hide_render=True
t=root('tactile',10.4,0); box('tactile_base',(0,0,.016),(4,.6,.032),yellow,t)
# Raised domes visually communicate the tactile strip without a texture dependency.
for x in range(20):
 for y in range(3): cyl('tactile_stud',(-1.9+x*.2,-.2+y*.2,.045),.035,.026,yellow,t)
box('tactile_COLLISION',(0,0,.02),(4,.6,.04),yellow,t).hide_render=True
c=root('canopy',0,4); box('canopy_roof',(0,0,3.28),(4,2.65,.16),steel,c); box('canopy_fascia',(0,-1.27,3.31),(4,.11,.22),steel,c)
for x in (-1.78,1.78):
 box('canopy_post',(x,.65,1.6),(.14,.14,3.2),steel,c); box('canopy_brace',(x,0,3.26),(.13,2.5,.12),steel,c)
 box('canopy_COLLISION_post',(x,.65,1.6),(.16,.16,3.2),steel,c).hide_render=True
box('canopy_COLLISION_roof',(0,0,3.28),(4,2.65,.16),steel,c).hide_render=True
b=root('bench',5.2,4)
for y in (-.18,0,.18): box('bench_seat_slat',(0,y,.48),(1.8,.14,.07),wood,b)
for z in (.75,.95): box('bench_back_slat',(0,.26,z),(1.8,.08,.14),wood,b)
for x in (-.7,.7):
 box('bench_leg',(x,0,.25),(.08,.5,.5),steel,b); box('bench_back_support',(x,.27,.75),(.07,.07,.65),steel,b)
box('bench_COLLISION',(0,0,.48),(1.8,.52,.1),steel,b).hide_render=True
b=root('bin',8,4); cyl('bin_body',(0,0,.42),.22,.84,steel,b); cyl('bin_top',(0,0,.84),.24,.06,black,b); cyl('bin_COLLISION',(0,0,.42),.22,.84,steel,b).hide_render=True
l=root('lamp',10.4,4); cyl('lamp_post',(0,0,1.6),.065,3.2,steel,l); box('lamp_arm',(.32,0,3.15),(.64,.08,.08),steel,l); box('lamp_head',(.6,0,3.1),(.46,.28,.12),glass,l); cyl('lamp_COLLISION',(0,0,1.6),.07,3.2,steel,l).hide_render=True
g=root('gantry',15.6,4)
for x in (-1.8,1.8): box('gantry_post',(x,0,1.65),(.12,.12,3.3),steel,g); box('gantry_COLLISION_post',(x,0,1.65),(.14,.14,3.3),steel,g).hide_render=True
box('gantry_sign',(0,0,2.98),(3.55,.12,.55),steel,g); box('gantry_sign_face',(0,-.071,2.98),(3.35,.025,.42),glass,g)
# Join visual components for each kit type into one reusable mesh; keep proxies separate.
for rt in [o for o in s.objects if o.type=='EMPTY']:
 visual=[o for o in rt.children if o.type=='MESH' and 'COLLISION' not in o.name]
 bpy.ops.object.select_all(action='DESELECT')
 for o in visual: o.select_set(True)
 bpy.context.view_layer.objects.active=visual[0]; bpy.ops.object.join(); visual[0].name=rt.name+'_VISUAL'
sys.path.insert(0,os.path.abspath(os.path.join(D,'..','..','trains','tools')))
from palette import setup as setup_palette
setup_palette()
s.render.engine='BLENDER_WORKBENCH'; s.display.shading.light='STUDIO'; s.display.shading.color_type='MATERIAL'; s.display.shading.show_shadows=True; s.display.shading.show_cavity=True
s.render.resolution_x=1400; s.render.resolution_y=800; s.render.resolution_percentage=100
def camera(n,loc,target,scale):
 d=bpy.data.cameras.new(n); ob=bpy.data.objects.new(n,d); s.collection.objects.link(ob); ob.location=loc; ob.rotation_euler=(Vector(target)-ob.location).to_track_quat('-Z','Y').to_euler(); d.type='ORTHO'; d.ortho_scale=scale; return ob
s.camera=camera('overview',(20,-22,19),(7.2,2,1),25); bpy.ops.wm.save_as_mainfile(filepath=os.path.join(D,'platform-kit.blend'))
for name,loc,target,scale in [('overview',(20,-22,19),(7.2,2,1),25),('canopy', (9,-8,8),(1,3.5,1.4),13),('furniture',(13,-5,7),(9,4,1),11)]:
 s.camera=camera(name+'_camera',loc,target,scale); s.render.filepath=os.path.join(D,'renders',name+'.png'); bpy.ops.render.render(write_still=True)
print('KIT: eight reusable visual meshes and separate collision proxies')
