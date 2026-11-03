"""Generate an unintegrated conditional north-entrance apron in /tmp.

Only valid if a future city agrees to the requested station placement and
provides a Y=.63-stud walking surface there. Not connected to existing city.
"""
import bpy,os,sys
D=os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0,os.path.abspath(os.path.join(D,'..','..','trains','tools')))
from export_common import audit,exports
out=sys.argv[sys.argv.index('--')+1] if '--' in sys.argv else '/tmp/civitas-apron-candidate'
os.makedirs(out,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
s=bpy.context.scene;root=bpy.data.objects.new('CONDITIONAL_APRON_ROOT',None);s.collection.objects.link(root)
material=bpy.data.materials.new('apron_stone');material.diffuse_color=(.48,.5,.47,1)
# Blender metres. Front threshold is y=28, concourse floor z=.76.
# Future square level is .63 studs * .28m/stud = .1764m.
top=.76; bottom=.63*.28; run=(top-bottom)*12; width=1.8; half=width/2

def prism(name,y0,y1,z0,z1):
 v=[(-half,y0,z0),(half,y0,z0),(half,y1,z1),(-half,y1,z1)]
 v += [(x,y,z-.12) for x,y,z in v]
 faces=[(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)]
 result=[]
 for kind in ('VISUAL','COLLISION'):
  mesh=bpy.data.meshes.new(name+'_'+kind);mesh.from_pydata(v,[],faces);mesh.update()
  o=bpy.data.objects.new(name+'_'+kind,mesh);s.collection.objects.link(o);o.parent=root;o.data.materials.append(material);o.hide_render=kind=='COLLISION';result.append(o)
 return result
objects=[root]
objects+=prism('APRON_UPPER',27.9,28.01,top,top)
objects+=prism('APRON_RAMP',28.0,28+run,top,bottom)
objects+=prism('APRON_LOWER',28+run,28+run+1.8,bottom,bottom)
audit(objects,os.path.join(out,'conditional-apron-stats.json'));exports(objects,[root],os.path.join(out,'conditional-apron'))
print('APRON_CANDIDATE: width 1.8m, rise',round(top-bottom,4),'m, run',round(run,4),'m, slope 1:12, not integrated')
