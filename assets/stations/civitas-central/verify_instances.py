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
