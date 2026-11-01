"""blender -b platform-kit.blend --python-exit-code 1 -P export_platform.py"""
import bpy,os,sys
D=os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0,os.path.abspath(os.path.join(D,'..','..','trains','tools')))
from export_common import audit,exports
names=['edge','coping','tactile','canopy','bench','bin','lamp','gantry']; roots=[bpy.data.objects[n] for n in names]
objects=[o for o in bpy.context.scene.objects if o in roots or o.parent in roots]
audit(objects,os.path.join(D,'mesh-stats.json'))
for r in roots:
 r.location=(0,0,0); children=[r]+list(r.children); exports(children,[r],os.path.join(D,r.name))
