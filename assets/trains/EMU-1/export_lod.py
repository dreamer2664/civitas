"""Export two independent static far LODs from EMU-1-LOD1.blend."""
import bpy,os,sys
D=os.path.dirname(os.path.abspath(__file__));sys.path.insert(0,os.path.join(D,'..','tools'))
from export_common import audit,exports
roots=[bpy.data.objects['CAB_LOD1_ROOT'],bpy.data.objects['INTERMEDIATE_LOD1_ROOT']]
objects=[o for o in bpy.context.scene.objects if o in roots or o.parent in roots]
audit(objects,os.path.join(D,'lod1-mesh-stats.json'))
for root in roots:
 root.location=(0,0,0)
 exports([root]+list(root.children),[root],os.path.join(D,root.name.replace('_ROOT','')))
