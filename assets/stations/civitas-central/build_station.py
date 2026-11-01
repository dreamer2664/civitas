"""Build Civitas Central in metres. Export root is placed at (4000,0,3400) studs.

Source +X is world +X, +Y is world -Z, +Z is world +Y. No downloads.
"""
import bpy, math, os
from mathutils import Vector
D=os.path.dirname(os.path.abspath(__file__))
KIT=os.path.abspath(os.path.join(D,'..','platform-kit','platform-kit.blend'))
bpy.context.preferences.filepaths.save_version=0
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
s=bpy.context.scene; s.unit_settings.system='METRIC'
def mat(name,col):
 m=bpy.data.materials.new(name); m.diffuse_color=(*col,1); m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value=(*col,1); p.inputs['Roughness'].default_value=.72
 return m
stone=mat('station_limestone',(.61,.58,.51)); light=mat('station_trim',(.80,.77,.69)); floor=mat('concourse_terrazzo',(.48,.50,.47)); steel=mat('roof_steel',(.12,.20,.23)); roof=mat('roof_zinc',(.27,.34,.34)); glass=mat('station_glazing',(.11,.24,.29)); brick=mat('station_brick',(.40,.25,.19)); yellow=mat('rail_metal',(.32,.34,.33))
def empty(name,loc=(0,0,0),parent=None):
 ob=bpy.data.objects.new(name,None); s.collection.objects.link(ob); ob.parent=parent; ob.location=loc; return ob
root=empty('CENTRAL_ROOT'); root['world_placement_studs']='X=4000 Y=0 Z=3400; verify world rail elevation with strata'
def box(name,loc,dim,material,parent=root,collision=False):
 bpy.ops.mesh.primitive_cube_add(size=1); ob=bpy.context.object; ob.name=name; ob.dimensions=dim; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); ob.parent=parent; ob.location=loc; ob.data.materials.append(material); ob.hide_render=collision; return ob
def pair(name,loc,dim,material):
 box(name+'_VISUAL',loc,dim,material); box(name+'_COLLISION',loc,dim,material,collision=True)
def ramp(name,x0,x1,y,z0,z1,width):
 # watertight ramp with a parallel collision proxy; Z-up, solid underfloor thickness .12m
 v=[(x0,y-width/2,z0),(x0,y+width/2,z0),(x1,y+width/2,z1),(x1,y-width/2,z1)]
 v+= [(x,y,z-.12) for x,y,z in v]
 faces=[(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)]
 for suffix,col in [('VISUAL',False),('COLLISION',True)]:
  mesh=bpy.data.meshes.new(name+'_'+suffix); mesh.from_pydata(v,[],faces); mesh.update(); ob=bpy.data.objects.new(name+'_'+suffix,mesh); s.collection.objects.link(ob); ob.parent=root; ob.data.materials.append(floor); ob.hide_render=col
# Concourses: north square-facing floor reaches platform 1; 168m x 14m.
pair('concourse_floor',(0,21,.64),(168,14,.24),floor)
# Three through entrances in north façade at x=-19.6,0,19.6m; 5.6m clear openings.
openings=[(-22.4,-16.8),(-2.8,2.8),(16.8,22.4)]
prev=-84
for i,(a,b) in enumerate(openings+[(84,84)]):
 if a>prev: pair('north_wall_%d'%i,((prev+a)/2,27.75,3.35),(a-prev,.5,6.7),stone)
 prev=b
pair('north_upper_wall',(0,27.75,7.75),(168,.5,2.1),stone)
# Cornices and vertical piers articulate the long civic facade.
box('north_cornice',(0,28.03,9.05),(168,.7,.55),light)
prev=-84
for i,(a,b) in enumerate(openings+[(84,84)]):
 if a>prev: box('north_plinth_%d'%i,((prev+a)/2,28.03,1.05),(a-prev,.15,.55),light)
 prev=b
for x in range(-80,81,8):
 if any(a-1.1<x<b+1.1 for a,b in openings): continue
 box('north_pier',(x,28.15,4.35),(.8,.4,7.3),light)
 box('north_pier_capital',(x,28.23,7.95),(1.25,.55,.45),light)
# Grand central raised bay and crest. Decorative high glazing is above walking height.
for x in (-23,-15,-7,7,15,23):
 box('facade_upper_window',(x,28.07,5.1),(3.0,.08,2.65),glass)
box('entry_attic',(0,27.9,10.15),(31,.6,2.0),brick)
box('entry_attic_cornice',(0,28.15,11.25),(33,.7,.4),light)
for x in (-13,-6.5,0,6.5,13): box('attic_recess',(x,28.23,10.2),(4.6,.07,.85),light)
# Side walls above rail clearance, leaving the ends open for through running.
for x in (-83.75,83.75):
 pair('sidewall_concourse_'+str(x),(x,21,4.8),(.5,14,9.6),stone)
 box('high_side_lintel',(x,-7,9.0),(.5,42,1.0),stone)
# Long roof: standing-seam barrel vault, open beneath for platforms and bridge.
segments=16
for i in range(segments):
 y0=-28+i*56/segments; y1=-28+(i+1)*56/segments; yc=(y0+y1)/2
 # radial arch approximation; eaves 10.2m, crown 15.2m
 z=10.2+5*(1-(yc/28)**2)
 b=box('vault_roof_panel',(0,yc,z),(168,56/segments+.03,.18),roof)
 dzdy=-10*yc/(28*28); b.rotation_euler.x=math.atan(dzdy)
for x in range(-80,81,8):
 for side in (-1,1):
  if side==1 and any(a-.3<x<b+.3 for a,b in openings): continue
  box('roof_support',(x,side*27.4,5),(.35,.35,10),steel)
# Steel transverse arch ribs follow the same profile as the roof.
for x in range(-80,81,16):
 for i in range(16):
  y=-28+(i+.5)*3.5; z=10.2+5*(1-(y/28)**2)-.22
  b=box('vault_rib',(x,y,z),(.20,3.55,.28),steel); b.rotation_euler.x=math.atan(-10*y/(28*28))
# Four physically linked module instances: two bays per platform, each 40m x 6m.
with bpy.data.libraries.load(KIT,link=False) as (source,dest):
 dest.objects=[n for n in source.objects if n.endswith('_VISUAL') or '_COLLISION' in n]
kit={o.name:o for o in dest.objects if o}
# Derive one shared station-specific tactile LOD from the original kit mesh.
# The source kit .blend is untouched; every module references this datablock.
tactile_source=kit['tactile_VISUAL']
tmp=tactile_source.copy(); tmp.data=tactile_source.data.copy(); s.collection.objects.link(tmp); tmp.parent=None
bpy.ops.object.select_all(action='DESELECT'); tmp.select_set(True); bpy.context.view_layer.objects.active=tmp
mod=tmp.modifiers.new('Station tactile budget','DECIMATE'); mod.ratio=.20
bpy.ops.object.modifier_apply(modifier=mod.name)
tactile_source.data=tmp.data
bpy.data.objects.remove(tmp,do_unlink=True)
def piece(category,parent,offset,zscale=1):
 for src in kit.values():
  if not (src.name.startswith(category+'_VISUAL') or src.name.startswith(category+'_COLLISION')): continue
  if category in ('edge','coping','tactile') and '_COLLISION' in src.name: continue  # surface proxy already supports walking
  ob=src.copy(); ob.data=src.data; s.collection.objects.link(ob); ob.parent=parent
  ob.location=src.location+Vector(offset); ob.location.z=src.location.z*zscale+offset[2]; ob.rotation_euler=src.rotation_euler.copy(); ob.scale=src.scale.copy(); ob.scale.z*=zscale
  ob.name=parent.name+'_'+src.name
surface_cache={}
for platform,y in [(1,11.2),(2,-5.6)]:
 for module,x in [(1,-20),(2,20)]:
  mod=empty('PLATFORM_%d_MODULE_%d'%(platform,module),(x,y,.76),root); mod['kit_instances']=10; mod['surface_width_m']=6.0; mod.scale.y=1 if platform==1 else -1; edge=-1
  # A 40m continuous walking surface; separate box proxy.
  for suffix,is_collision in [('VISUAL',False),('COLLISION',True)]:
   surface=box(mod.name+'_surface_'+suffix,(0,0,-.18),(40,6,.36),floor,mod,is_collision)
   if suffix in surface_cache:
    old_mesh=surface.data; surface.data=surface_cache[suffix]
    if old_mesh.users==0: bpy.data.meshes.remove(old_mesh)
   else: surface_cache[suffix]=surface.data
  for i in range(10):
   along=-18+4*i
   piece('edge',mod,(along,edge*2.775,0)); piece('coping',mod,(along,edge*2.775,0)); piece('tactile',mod,(along,edge*2.30,0)); piece('canopy',mod,(along,.4,0),2.8)
  piece('bench',mod,(-7,-edge*1.8,0)); piece('bin',mod,(4,-edge*2.1,0)); piece('lamp',mod,(6,-edge*2.3,0)); piece('gantry',mod,(11,-edge*2.3,0))
# Rail-top datum at Z=0 (Blender); rail visuals continue through building ends.
for centre in (6.5,-.9):
 for side in (-1,1): box('through_rail',(0,centre+side*.7175,-.035),(168,.07,.07),yellow)
 for x in range(-84,85,3): box('rail_sleeper',(x,centre,-.11),(.19,2.6,.12),steel)
# Accessible bridge links platforms: 1:12 ramps above through rails.
# Bridge underside 6.88m leaves room for 5.8m overhead wire and vehicle clearance.
lo=.76; hi=7.0; run=(hi-lo)*12
ramp('north_bridge_ramp',-run/2-.9,run/2-.9,11.2,lo,hi,1.8)
ramp('south_bridge_ramp',-run/2-.9,run/2-.9,-5.6,lo,hi,1.8)
pair('bridge_deck',(run/2,2.8,hi-.06),(1.8,18.6,.12),floor)
for y in (12.3,-6.7): pair('bridge_support_'+str(y),(run/2,y,(hi+.76)/2),(.2,.2,hi-.76),steel)
# Walkable railings beside the bridge; not treated as walk surfaces.
for x in (run/2-.99,run/2+.99): box('bridge_railing',(x,2.8,hi+.55),(.09,14.8,1.1),steel)
# Guardrails stay outside the 1.8m clear ramp; the 1:12 slope is unchanged.
for y in (11.2,-5.6):
 for side in (-1,1):
  bar=box('ramp_guardrail',(-.9,y+side*.98,(lo+hi)/2+1.0),(math.hypot(run,hi-lo),.07,.07),steel)
  bar.rotation_euler.y=-math.atan2(hi-lo,run)
  for i in range(7):
   x=-run/2-.9+run*i/6; z=lo+(hi-lo)*i/6
   box('ramp_baluster',(x,y+side*.98,z+.52),(.07,.07,1.04),steel)
# Consolidate static architecture by material and 42m X zone; kit module
# instances remain independent and linked to the original kit mesh datablocks.
# Collision boxes stay separate so convex collision cannot seal entrances.
groups={}
for ob in list(root.children):
 if ob.type!='MESH' or 'COLLISION' in ob.name: continue
 zone=max(0,min(3,int((ob.location.x+84)/42)))
 key=(zone,ob.data.materials[0].name if ob.data.materials else 'none')
 groups.setdefault(key,[]).append(ob)
for (zone,material),objects in groups.items():
 bpy.ops.object.select_all(action='DESELECT')
 for ob in objects: ob.select_set(True)
 bpy.context.view_layer.objects.active=objects[0]; bpy.ops.object.join()
 bpy.context.object.name='CENTRAL_visual_zone%d_%s'%(zone,material)
# Workbench cameras, preliminary evidence only; no Studio functionality implied.
s.render.engine='BLENDER_WORKBENCH'; s.display.shading.light='STUDIO'; s.display.shading.color_type='MATERIAL'; s.display.shading.show_shadows=True; s.display.shading.show_cavity=True
s.render.resolution_x=1600; s.render.resolution_y=900; s.render.resolution_percentage=100

def camera(name,loc,target,scale):
 data=bpy.data.cameras.new(name); ob=bpy.data.objects.new(name,data); s.collection.objects.link(ob); ob.location=loc; ob.rotation_euler=(Vector(target)-ob.location).to_track_quat('-Z','Y').to_euler(); data.type='ORTHO'; data.ortho_scale=scale; return ob
s.camera=camera('facade',(190,185,95),(0,12,4),215)
s.render.image_settings.file_format='PNG'; bpy.ops.wm.save_as_mainfile(filepath=os.path.join(D,'civitas-central.blend'))
for name,loc,target,scale in [('facade',(135,185,35),(0,20,4),195),('overview',(100,-90,145),(0,0,0),155),('concourse',(0,24,2.5),(0,5,2.5),50)]:
 # Cutaway reveals platforms without pretending the roof is absent from the asset.
 if name=='overview':
  for ob in s.objects:
   if ob.name.startswith(('vault_roof_panel','vault_rib')): ob.hide_render=True
 if name=='concourse':
  for ob in s.objects:
   if ob.name.startswith(('vault_roof_panel','vault_rib')): ob.hide_render=False
 s.camera=camera(name+'_render',loc,target,scale)
 if name=='concourse': s.camera.data.type='PERSP'; s.camera.data.lens=18
 s.render.filepath=os.path.join(D,'renders',name+'.png'); bpy.ops.render.render(write_still=True)
print('CENTRAL: four 40m platform modules, two platforms, three front openings, one 1:12 bridge')
