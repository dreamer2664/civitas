"""Export local station at stud scale; place root at (4000,0,3400) in world."""
import bpy, os, sys
D=os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0,os.path.abspath(os.path.join(D,'..','..','trains','tools')))
from export_common import audit,exports
root=bpy.data.objects['CENTRAL_ROOT']
def desc(o):
 while o:
  if o==root: return True
  o=o.parent
 return False
objects=[o for o in bpy.context.scene.objects if o.type in {'MESH','EMPTY'} and desc(o)]
audit(objects,os.path.join(D,'mesh-stats.json')); exports(objects,[root],os.path.join(D,'civitas-central'))
