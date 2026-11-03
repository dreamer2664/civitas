"""Export a Y-reflected platform assembly with reflection baked into mesh data.

The alternative has no negative-scale module transform, for an importer that
cannot retain reflections. It is derived from the exact same assembly as the
unreflected `platform-module.glb`; Studio behavior still requires validation.
"""
import bpy,os,sys
from mathutils import Matrix,Vector
D=os.path.dirname(os.path.abspath(__file__));sys.path.insert(0,os.path.abspath(os.path.join(D,'..','..','trains','tools')))
from export_common import audit,exports
s=bpy.context.scene; source=bpy.data.objects['PLATFORM_1_MODULE_1']; mirror=Matrix.Scale(-1,4,Vector((0,1,0)))
root=bpy.data.objects.new('PLATFORM_REFLECTED_ROOT',None);s.collection.objects.link(root)
cache={};objects=[root]
for ob in source.children:
 if ob.type!='MESH': continue
 pointer=ob.data.as_pointer()
 if pointer not in cache:
  data=ob.data.copy(); data.transform(mirror); data.flip_normals(); cache[pointer]=data
 new=ob.copy(); new.data=cache[pointer]; s.collection.objects.link(new);new.parent=root
 new.matrix_parent_inverse=Matrix.Identity(4);new.matrix_basis=mirror @ ob.matrix_basis @ mirror
 new.name='REFLECTED_'+ob.name;objects.append(new)
audit(objects,os.path.join(D,'platform-module-reflected-stats.json'))
exports(objects,[root],os.path.join(D,'platform-module-reflected'))
