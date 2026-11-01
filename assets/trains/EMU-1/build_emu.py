"""Preliminary, reproducible exterior study. Not a completed production asset."""
import bpy, math, json, os
from mathutils import Vector
from mathutils.geometry import tessellate_polygon
D=os.path.dirname(os.path.abspath(__file__))
bpy.context.preferences.filepaths.save_version=0
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene
scene.unit_settings.system='METRIC'
def mat(name,col,metal=0):
 m=bpy.data.materials.new(name); m.diffuse_color=(*col,1); m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value=(*col,1); p.inputs['Metallic'].default_value=metal; p.inputs['Roughness'].default_value=.38
 return m
white=mat('body_porcelain',(0.76,.79,.78),.25); dark=mat('window_smoked',(.025,.07,.105),.15); red=mat('door_vermilion',(.56,.06,.04)); black=mat('undercarriage',(.035,.045,.052),.3); silver=mat('metal',(.37,.42,.44),.8); light=mat('headlamp',(.91,.86,.66)); interior=mat('interior',(.35,.38,.36))
# A real translucent material, exported in the GLB as alpha blending.
cab_glass=mat('cab_windscreen_glazing',(.16,.34,.40),.02)
cab_glass.diffuse_color=(.16,.34,.40,.24)
p=cab_glass.node_tree.nodes.get('Principled BSDF'); p.inputs['Alpha'].default_value=.24; p.inputs['Roughness'].default_value=.12
cab_glass.surface_render_method='DITHERED'
def empty(name,loc,parent=None):
 o=bpy.data.objects.new(name,None); scene.collection.objects.link(o); o.location=loc; o.parent=parent; return o
def cube(n,loc,dim,material,parent, bevel=0):
 bpy.ops.mesh.primitive_cube_add(size=1,location=(0,0,0)); o=bpy.context.object; o.name=n; o.dimensions=dim; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); o.location=loc; o.parent=parent; o.data.materials.append(material)
 if bevel:
  mod=o.modifiers.new('rounded fabricated edges','BEVEL'); mod.width=bevel; mod.segments=2
  mod=o.modifiers.new('weighted normals','WEIGHTED_NORMAL')
 return o
def wheel(name,loc,parent):
 bpy.ops.mesh.primitive_cylinder_add(vertices=24,radius=.42,depth=.13,location=(0,0,0),rotation=(math.pi/2,0,0)); o=bpy.context.object; o.name=name; o.parent=parent; o.location=loc; o.data.materials.append(black)
def shell_car(name,length,origin,cab):
 root=empty(name+'_ROOT',(origin,0,0)); root['pivot']='leading coupling face, rail top, track centre'; root['length_m']=length
 # Hollow, sectional body: two clearly separated doorway apertures per side.
 start=-length+.18; end=-3.2 if cab else -.18
 cube(name+'_floor',((start+end)/2,0,.70),(end-start,2.75,.12),interior,root)
 cube(name+'_roof',((start+end)/2,0,3.91),(end-start,2.72,.38),white,root,.12)
 doors=[-length*.27,-length*.73]
 for side in [-1,1]:
  suffix='L' if side<0 else 'R'; wall_y=side*1.35
  # Walls are built from short solid pieces, leaving physical openings at doors.
  segments=[]; prev=start
  for d in sorted(doors):
   segments.append((prev,d-.65)); prev=d+.65
  segments.append((prev,end))
  for i,(a,b) in enumerate(segments):
   if b<=a: continue
   for z,h,ma in [(1.08,.64,white),(2.21,1.62,dark),(3.31,.58,white)]:
    cube(f'{name}_{suffix}_side_{i}_{z}',((a+b)/2,wall_y,z),(b-a,.12,h),ma,root,.025)
   # white pillars over window band
   n=max(1,int((b-a)/1.8))
   for j in range(n+1):
    x=a+.06+(b-a-.12)*j/n
    cube(f'{name}_{suffix}_pillar_{i}_{j}',(x,side*1.405,2.25),(.09,.025,1.54),white,root)
  for i,d in enumerate(doors):
   cube(f'{name}_{suffix}_door_header_{i}',(d,wall_y,3.52),(1.3,.12,.45),white,root,.02)
   # Separate leaves. Their closure blocks entry only while closed, no wall behind them.
   for leaf in [-1,1]:
    leafroot=empty(f'{name}_{suffix}_door_{i}_{leaf}_PIVOT',(d+leaf*.65,side*1.345,.76),root)
    leafroot['travel_m']=1.35
    cube(f'{name}_{suffix}_door_{i}_{leaf}_leaf',(-leaf*.325,0,.975),(.60,.09,1.95),red,leafroot,.025)
    cube(f'{name}_{suffix}_door_{i}_{leaf}_glass',(-leaf*.325,side*.055,1.26),(.46,.025,.90),dark,leafroot,.025)
 # Underbody equipment and bogies
 cube(name+'_underframe',(-length/2,0,.51),(length-.9,2.35,.28),black,root,.04)
 for k,x in enumerate((-3,-length+3)):
  bogie=empty(f'{name}_BOGIE_{k}_PIVOT',(x,0,0),root); bogie['pivot']='bogie centre at rail top'
  cube(f'{name}_bogie_{k}_frame',(0,0,.55),(2.35,1.95,.27),black,bogie,.05)
  for dx in (-.75,.75):
   for side in (-1,1): wheel(f'{name}_wheel_{k}_{dx}_{side}',(dx,side*.72,.42),bogie)
 # Walkable collision proxies, individually named; no continuous wall across doors.
 coll=cube(name+'_COLLISION_floor',((start+end)/2,0,.64),(end-start,2.60,.12),black,root); coll.hide_render=True
 for side in (-1,1):
  prev=start
  for i,(a,b) in enumerate([(start,sorted(doors)[0]-.65),(sorted(doors)[0]+.65,sorted(doors)[1]-.65),(sorted(doors)[1]+.65,end)]):
   if b>a:
    coll=cube(f'{name}_COLLISION_wall_{side}_{i}',((a+b)/2,side*1.35,2.18),(b-a,.10,2.95),black,root); coll.hide_render=True
 if cab:
  # A compact cab desk and seat, currently a blockout for dashboard integration.
  cube('CAB_desk',(-3.35,-.34,1.48),(.55,1.30,.22),black,root,.05)
  cube('CAB_console',(-3.32,-.34,1.63),(.38,1.18,.12),silver,root,.025)
  cube('CAB_seat_base',(-4.32,-.32,1.05),(.6,.6,.16),dark,root,.04)
  cube('CAB_seat_back',(-4.62,-.32,1.45),(.15,.6,.85),dark,root,.05)
  cube('CAB_seat_stand',(-4.32,-.32,.86),(.25,.25,.3),black,root,.03)
  # Sculptural cab nose as successive 8-point cross sections, closed end caps.
  sections=[(-3.2,1.425,.72,3.99),(-1.8,1.38,.70,3.82),(-.55,1.15,.63,2.98),(-.20,.82,.58,1.65)]
  verts=[]
  for x,w,lo,hi in sections:
   c=.20
   verts += [(x,-w+c,lo),(x,w-c,lo),(x,w,lo+c),(x,w,hi-c),(x,w-c,hi),(x,-w+c,hi),(x,-w,hi-c),(x,-w,lo+c)]
  faces=[tuple(range(24,32))]
  for j in range(3):
   for i in range(8):
    if i==4 and j<2: continue  # aperture, not a dark overlay on a solid nose
    faces.append((j*8+i,j*8+(i+1)%8,(j+1)*8+(i+1)%8,(j+1)*8+i))
  mesh=bpy.data.meshes.new('cab nose'); mesh.from_pydata(verts,[],faces); mesh.update(); obj=bpy.data.objects.new(name+'_sculpted_nose',mesh); scene.collection.objects.link(obj); obj.parent=root; obj.data.materials.append(white)
  mod=obj.modifiers.new('shell thickness','SOLIDIFY'); mod.thickness=.06
  # The missing shell faces are replaced by thin glazed panels that follow the rake.
  # Each is a closed, non-zero-thickness wedge with alpha-blended glazing.
  for j in range(2):
   outer=[verts[j*8+4],verts[j*8+5],verts[(j+1)*8+5],verts[(j+1)*8+4]]
   inner=[(x,y,z-.012) for x,y,z in outer]; vs=outer+inner
   fs=[(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)]
   me=bpy.data.meshes.new('windscreen'); me.from_pydata(vs,[],fs); me.update(); ob=bpy.data.objects.new(name+'_windscreen_'+str(j),me); scene.collection.objects.link(ob); ob.parent=root; ob.data.materials.append(cab_glass)
  for y in (-.75,.75): cube(name+'_headlamp',( -.19,y,1.24),(.08,.30,.14),light,root,.03)
 else:
  cube(name+'_leading_bulkhead',(-.06,0,2.15),(.12,2.85,2.98),white,root)
 # Rear plane is exactly the trailing coupling datum.
 cube(name+'_trailing_bulkhead',(-length+.06,0,2.15),(.12,2.85,2.98),white,root)
 cube(name+'_coupler',(-.1,0,.58),(.2,.42,.22),black,root,.02)
 return root
shell_car('CAB',21,0,True); shell_car('INTERMEDIATE',20,-21.5,False)
# Plug-slide: move each leaf outward first, then along the body.  The named
# outboard-edge pivots are unchanged at rest. NLA tracks share a name for GLB.
for door in [o for o in scene.objects if o.type=='EMPTY' and '_door_' in o.name and o.name.endswith('_PIVOT')]:
 base=door.location.copy(); leaf=int(door.name.split('_')[-2]); side=-1 if '_L_' in door.name else 1
 for frame,outward,slide in [(1,0,0),(6,.24,0),(24,.24,1.35),(30,.24,1.35)]:
  door.location=(base.x+leaf*slide,base.y+side*outward,base.z); door.keyframe_insert(data_path='location',frame=frame)
 action=door.animation_data.action; action.name=door.name+'_motion'
 for fc in action.fcurves:
  for key in fc.keyframe_points: key.interpolation='LINEAR'
 track=door.animation_data.nla_tracks.new(); track.name='Door_open'; track.strips.new('Door_open',1,action); door.animation_data.action=None
scene.frame_set(1)
# Studio workbench preview. Render is a design study, not proof of final visual quality.
scene.render.engine='BLENDER_WORKBENCH'; scene.display.shading.light='STUDIO'; scene.display.shading.color_type='MATERIAL'; scene.display.shading.show_shadows=True; scene.display.shading.show_cavity=True
scene.render.resolution_x=1400; scene.render.resolution_y=700; scene.render.resolution_percentage=100
world=scene.world; world.color=(.06,.06,.06)
def camera(name,loc,target,scale):
 data=bpy.data.cameras.new(name); ob=bpy.data.objects.new(name,data); scene.collection.objects.link(ob); ob.location=loc; ob.rotation_euler=(Vector(target)-ob.location).to_track_quat('-Z','Y').to_euler(); data.type='ORTHO'; data.ortho_scale=scale; return ob
scene.camera=camera('three_quarter',(16,-55,24),(-20,0,1.4),49)
scene.render.image_settings.file_format='PNG'; scene.render.filepath=os.path.join(D,'renders','front-three-quarter.png'); bpy.ops.wm.save_as_mainfile(filepath=os.path.join(D,'EMU-1.blend')); bpy.ops.render.render(write_still=True)
scene.camera=camera('side',(-21,-48,2.4),(-21,0,2.0),46)
scene.render.filepath=os.path.join(D,'renders','side.png'); bpy.ops.render.render(write_still=True)
# Interior perspective: camera is inside cab looking forward to the desk and inner nose.
scene.camera=camera('cab_interior',(-5.8,.45,2.4),(-3.0,-.35,1.55),4)
scene.camera.data.type='PERSP'; scene.camera.data.lens=16
scene.render.filepath=os.path.join(D,'renders','cab-interior.png'); bpy.ops.render.render(write_still=True)

# Four-stage door movement evidence: closed, plugged out, mid-slide, open.
scene.camera=camera('door_sequence',(-5.67,-8,1.8),(-5.67,-1.3,1.75),5.8)
for frame in (1,6,15,24):
 scene.frame_set(frame); scene.render.filepath=os.path.join(D,'renders',f'door-{frame:02d}.png'); bpy.ops.render.render(write_still=True)
scene.frame_set(1)
dep=bpy.context.evaluated_depsgraph_get(); total=0; counts={}
for obj in scene.objects:
 if obj.type!='MESH': continue
 ev=obj.evaluated_get(dep); me=ev.to_mesh(); me.calc_loop_triangles(); counts[obj.name]=len(me.loop_triangles); total+=len(me.loop_triangles); ev.to_mesh_clear()
print('STUDY evaluated_triangles=',total,' meshes=',len(counts))
