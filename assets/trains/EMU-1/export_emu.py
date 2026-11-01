"""blender -b EMU-1.blend --python-exit-code 1 -P export_emu.py"""
import bpy, os, sys
D=os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0,os.path.join(D,'..','tools'))
from export_common import audit,exports
roots=[bpy.data.objects['CAB_ROOT'],bpy.data.objects['INTERMEDIATE_ROOT']]
def under(o):
 while o:
  if o in roots: return True
  o=o.parent
 return False
objects=[o for o in bpy.context.scene.objects if under(o) and o.type in {'MESH','EMPTY'}]
audit(objects,os.path.join(D,'mesh-stats.json')); exports(objects,roots,os.path.join(D,'EMU-1'))
