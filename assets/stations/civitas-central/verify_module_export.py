"""Blender reimport of standalone module, not Roblox import validation."""
import bpy,os,sys
from mathutils import Vector
D=os.path.dirname(os.path.abspath(__file__))
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
mode='FBX' if '--fbx' in sys.argv else 'GLB'
if mode=='FBX': bpy.ops.import_scene.fbx(filepath=os.path.join(D,'platform-module.fbx'))
else: bpy.ops.import_scene.gltf(filepath=os.path.join(D,'platform-module.glb'))
root=bpy.data.objects.get('PLATFORM_1_MODULE_1');assert root is not None
assert root.matrix_world.translation.length<1e-4,root.matrix_world.translation
for kind in ('VISUAL','COLLISION'):
 ob=bpy.data.objects.get('PLATFORM_1_MODULE_1_surface_'+kind); assert ob is not None,kind
 pts=[ob.matrix_world@Vector(c) for c in ob.bound_box]
 dims=[max(p[i] for p in pts)-min(p[i] for p in pts) for i in range(3)]; top=max(p.z for p in pts)
 assert abs(dims[0]-40/.28)<.001 and abs(dims[1]-6/.28)<.001 and abs(top)<.001,(kind,dims,top)
 print('MODULE_SURFACE',kind,'studs',tuple(round(x,3) for x in dims),'top',round(top,3))
for name,expected in [('edge',10),('coping',10),('tactile',10),('canopy',10),('bench',1),('bin',1),('lamp',1),('gantry',1)]:
 objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and name+'_VISUAL' in o.name]
 assert len(objects)==expected,(name,len(objects))
 print('MODULE_KIT',name,len(objects))
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
assert len(meshes)==81,('mesh count',len(meshes))
print('MODULE_'+mode+'_PASS: zero mounting root; 81 meshes; 40m x 6m visual and proxy surfaces; eight kit categories')
print('LIMIT: Blender round-trip only, not Roblox Studio, actual MeshPart counts, physics or rendering')
