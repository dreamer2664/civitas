"""Export the shared north-side 40m assembly as a reusable standalone module.

Run on civitas-central.blend. The base-centre mounting origin is (0,0,0).
Platform-2 placement is the same local assembly reflected across its Y axis.
"""
import bpy,os,sys
D=os.path.dirname(os.path.abspath(__file__));sys.path.insert(0,os.path.abspath(os.path.join(D,'..','..','trains','tools')))
from export_common import audit,exports
module=bpy.data.objects['PLATFORM_1_MODULE_1']
objects=[module]+[o for o in module.children if o.type=='MESH']
audit(objects,os.path.join(D,'platform-module-stats.json'))
module.parent=None;module.location=(0,0,0);module.scale=(1,1,1)
exports(objects,[module],os.path.join(D,'platform-module'))
