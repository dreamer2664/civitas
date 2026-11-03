"""Audit pantograph contact height and surface clearance to HVAC in Blender."""
import bpy
from mathutils.bvhtree import BVHTree
D=bpy.context.evaluated_depsgraph_get()
def meshes(parent):return [o for o in parent.children if o.type=='MESH']
def tree(ob):
 ev=ob.evaluated_get(D); me=ev.to_mesh(); coords=[ev.matrix_world@v.co for v in me.vertices]; t=BVHTree.FromPolygons(coords,[list(p.vertices) for p in me.polygons]); ev.to_mesh_clear();return t,coords
p=meshes(bpy.data.objects['INTERMEDIATE_PANTOGRAPH']); h=meshes(bpy.data.objects['INTERMEDIATE_ROOF_EQUIPMENT']); overlaps=0
for a in p:
 ta,pa=tree(a)
 for b in h:
  tb,hb=tree(b); overlaps+=len(ta.overlap(tb))
pz=max(v.z for ob in p for v in tree(ob)[1]); hz=max(v.z for ob in h for v in tree(ob)[1])
assert abs(pz-5.65)<.002 and overlaps==0,(pz,overlaps)
print('PANTOGRAPH contact height m',round(pz,3),'studs',round(pz/.28,3))
print('HVAC maximum height m',round(hz,3),'pantograph/HVAC surface overlaps',overlaps)
print('NOTE: fixed raised pose; no wire contact or dynamic movement test')
