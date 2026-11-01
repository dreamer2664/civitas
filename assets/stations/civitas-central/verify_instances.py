"""Verify four platform modules share each category's Blender mesh datablock."""
import bpy
mods=[o for o in bpy.context.scene.objects if o.type=='EMPTY' and o.name.startswith('PLATFORM_')]
assert len(mods)==4, len(mods)
print('PLATFORM_MODULES',len(mods))
for kind,expected in [('edge',40),('coping',40),('tactile',40),('canopy',40),('bench',4),('bin',4),('lamp',4),('gantry',4)]:
 obs=[o for o in bpy.context.scene.objects if o.type=='MESH' and kind+'_VISUAL' in o.name]
 datablocks={o.data.as_pointer() for o in obs}
 assert len(obs)==expected and len(datablocks)==1,(kind,len(obs),len(datablocks))
 print(kind,'instances',len(obs),'shared mesh datablocks',len(datablocks))
# Compare the entire assembly, including furniture and separately named proxies.
# Platform 2 applies a reflection to the same local assembly, not a new kit.
def signature(root):
 return sorted((o.data.as_pointer(),tuple(round(x,5) for x in o.location),tuple(round(x,5) for x in o.rotation_euler),tuple(round(x,5) for x in o.scale),o.hide_render) for o in root.children if o.type=='MESH')
baseline=signature(bpy.data.objects['PLATFORM_1_MODULE_1'])
for root in mods:
 assert signature(root)==baseline,('module differs from base assembly',root.name)
 expected=-1 if root.name.startswith('PLATFORM_2_') else 1
 assert abs(root.scale.y-expected)<.0001,(root.name,root.scale.y)
print('IDENTICAL_MODULES_PASS',len(mods),'assemblies,',len(baseline),'mesh instances per assembly; platform 2 reflected')
