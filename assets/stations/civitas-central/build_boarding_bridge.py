"""Generate two experimental static boarding-step poses; no runtime controller.

Invoke Blender with -- /tmp/output-directory. Root is at the door's track
centre and rail top, facing a platform on local -Y; +X runs along the track.
Outputs are generated outside the repository by default.
"""
import bpy,os,sys
D=os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0,os.path.abspath(os.path.join(D,'..','..','trains','tools')))
from export_common import audit,exports
out=sys.argv[sys.argv.index('--')+1] if '--' in sys.argv else '/tmp/civitas-boarding-bridge'
os.makedirs(out,exist_ok=True)
for pose,y in [('stowed',-1.47),('deployed',-1.65)]:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 root=bpy.data.objects.new('BRIDGE_'+pose.upper()+'_ROOT',None);bpy.context.scene.collection.objects.link(root)
 m=bpy.data.materials.get('boarding_step_metal') or bpy.data.materials.new('boarding_step_metal');m.diffuse_color=(.38,.4,.4,1)
 objs=[root]
 for kind in ('VISUAL','COLLISION'):
  bpy.ops.mesh.primitive_cube_add(size=1);o=bpy.context.object;o.name='BRIDGE_'+kind
  o.dimensions=(1.10,.26,.04);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
  o.parent=root;o.location=(0,y,.74);o.data.materials.append(m);o.hide_render=kind=='COLLISION';objs.append(o)
 audit(objs,os.path.join(out,'boarding-bridge-'+pose+'-stats.json'))
 exports(objs,[root],os.path.join(out,'boarding-bridge-'+pose))
print('BRIDGE_PROTOTYPE: stowed reaches 1.60m; deployed reaches 1.78m; motion and interlocks NOT provided')
