"""Generate a shared, deterministic 1K base-colour swatch atlas and UVs.

Colours are intentionally flat pending an authored weathering/detail pass. UVs
are mapped to separate solid swatches, not a substitute for bespoke UV artwork.
"""
import bpy, os, struct, zlib, math
from array import array
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PATH=os.path.join(ROOT,'textures','rail_palette.png')
COLORS={
 'body_porcelain':(194,201,199),'window_smoked':(7,18,27),'door_vermilion':(143,15,10),'undercarriage':(9,11,13),'metal':(94,107,112),'headlamp':(232,219,168),'interior':(89,97,92),'cab_windscreen_glazing':(41,87,102),
 'cast_concrete':(135,143,138),'coping_stone':(194,194,181),'tactile_buff':(186,156,82),'painted_steel':(33,48,56),'bench_timber':(110,64,31),'sign_offwhite':(199,204,194),'dark_detail':(14,19,20)}
NAMES=list(COLORS)
def generate():
 os.makedirs(os.path.dirname(PATH),exist_ok=True)
 # 4x4 swatch grid; every tile is 256x256.
 raw=bytearray()
 for y in range(1024):
  raw.append(0)
  for x in range(1024):
   i=(y//256)*4+(x//256); raw.extend(COLORS[NAMES[min(i,len(NAMES)-1)]])
 def chunk(t,data):return struct.pack('>I',len(data))+t+data+struct.pack('>I',zlib.crc32(t+data)&0xffffffff)
 png=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',1024,1024,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw,9))+chunk(b'IEND',b'')
 with open(PATH,'wb') as f:f.write(png)
def setup():
 generate(); image=bpy.data.images.load(PATH,check_existing=True); image.name='rail_palette_1k'; image.pack()
 for m in bpy.data.materials:
  if m.name not in COLORS: continue
  m.use_nodes=True; p=m.node_tree.nodes.get('Principled BSDF'); tex=m.node_tree.nodes.new('ShaderNodeTexImage'); tex.name='Shared 1K base colour'; tex.image=image; m.node_tree.links.new(tex.outputs['Color'],p.inputs['Base Color'])
  if m.name=='cab_windscreen_glazing': p.inputs['Alpha'].default_value=.24; m.surface_render_method='DITHERED'
 for ob in bpy.context.scene.objects:
  if ob.type!='MESH': continue
  mesh=ob.data; uv=mesh.uv_layers.active or mesh.uv_layers.new(name='PaletteUV')
  for poly in mesh.polygons:
   material=mesh.materials[poly.material_index] if len(mesh.materials)>poly.material_index else None
   if not material or material.name not in COLORS: continue
   idx=NAMES.index(material.name); col=idx%4; row=idx//4
   # Individual face UVs occupy a small, nondegenerate area inside their swatch.
   # Image rows run top-down while UV V runs bottom-up.
   cx=(col+.5)/4; cy=1-(row+.5)/4; n=poly.loop_total
   for j,li in enumerate(poly.loop_indices):
    angle=2*math.pi*j/n; uv.data[li].uv=(cx+.075*math.cos(angle),cy+.075*math.sin(angle))
