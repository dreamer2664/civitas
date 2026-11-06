#!/usr/bin/env python3
"""Blender 5.1 geometry review from executed Luau builders; not Studio screenshots."""
from __future__ import annotations
import argparse
import json
import math
from collections import defaultdict
from pathlib import Path

import bpy
from mathutils import Matrix, Vector
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'evidence/norman/renders'
OUT.mkdir(parents=True, exist_ok=True)
parser = argparse.ArgumentParser()
parser.add_argument('--only', default='01-central-arrival', help='Comma-separated camera ids')
parser.add_argument('--samples', type=int, default=24)
args = parser.parse_args()
data = json.loads((ROOT / 'build/review/geometry.json').read_text())
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.cycles.samples = args.samples
scene.cycles.use_denoising = True
scene.render.threads_mode = 'FIXED'
scene.render.threads = 8
scene.render.resolution_x = 1600
scene.render.resolution_y = 1000
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.view_settings.view_transform = 'AgX'
scene.view_settings.exposure = 0
scene.world = bpy.data.worlds.new('European morning · review lighting only')
scene.world.use_nodes = True
nodes = scene.world.node_tree.nodes
nodes.get('Background').inputs['Color'].default_value = (.48, .62, .82, 1)
nodes.get('Background').inputs['Strength'].default_value = .5
light_data = bpy.data.lights.new('Morning sun · review only', 'SUN')
light_data.energy = 2.4
light_data.angle = math.radians(8)
sun = bpy.data.objects.new('Morning sun · review only', light_data)
scene.collection.objects.link(sun)
sun.rotation_euler = (math.radians(30), math.radians(-25), math.radians(-28))

SCALE = .28
CONVERT = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))

def point(v):
    return Vector((v[0] * SCALE, -v[2] * SCALE, v[1] * SCALE))

def make_material(color, kind):
    mat = bpy.data.materials.new(kind + '_' + '_'.join(str(round(c, 3)) for c in color))
    color = tuple(c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4 for c in color)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    bs = mat.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value = (*color, 1)
    bs.inputs['Roughness'].default_value = .72
    if kind == 'Metal':
        bs.inputs['Metallic'].default_value = .45
        bs.inputs['Roughness'].default_value = .36
    elif kind == 'Glass':
        # Opaque glazing matches the authored (Transparency=0) Roblox visual parts.
        bs.inputs['Metallic'].default_value = .5
        bs.inputs['Roughness'].default_value = .2
    elif kind in ('Concrete', 'Brick', 'Cobblestone', 'Asphalt', 'Ground'):
        tex = mat.node_tree.nodes.new('ShaderNodeTexNoise')
        tex.inputs['Scale'].default_value = 20
        tex.inputs['Detail'].default_value = 2
        bump = mat.node_tree.nodes.new('ShaderNodeBump')
        bump.inputs['Strength'].default_value = .16
        bump.inputs['Distance'].default_value = .018
        mat.node_tree.links.new(tex.outputs['Fac'], bump.inputs['Height'])
        mat.node_tree.links.new(bump.outputs['Normal'], bs.inputs['Normal'])
    return mat

# Combine by material, preserving all authored dimensions and transforms.
buckets = defaultdict(lambda: ([], []))
for p in data['parts']:
    key = (tuple(round(c, 5) for c in p['color']), p['material'])
    verts, faces = buckets[key]
    x, y, z = [a / 2 for a in p['size']]
    if p['shape'] == 'Cylinder':
        n = 40
        local = [Vector((end * x, math.cos(t * math.tau / n) * y, math.sin(t * math.tau / n) * z)) for end in (-1, 1) for t in range(n)]
        pf = [tuple(reversed(range(n))), tuple(range(n, 2 * n))]
        pf += [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
    else:
        local = [Vector(v) for v in [(-x,-y,-z),(x,-y,-z),(x,y,-z),(-x,y,-z),(-x,-y,z),(x,-y,z),(x,y,z),(-x,y,z)]]
        pf = [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
    rx, ry, rz = [math.radians(v) for v in p['orientation']]
    rotation = Matrix.Rotation(ry, 3, 'Y') @ Matrix.Rotation(rx, 3, 'X') @ Matrix.Rotation(rz, 3, 'Z')
    transform = CONVERT @ rotation
    origin = point(p['position'])
    offset = len(verts)
    verts.extend(tuple(origin + (transform @ v) * SCALE) for v in local)
    faces.extend(tuple(i + offset for i in face) for face in pf)
for (color, kind), (verts, faces) in buckets.items():
    mesh = bpy.data.meshes.new(kind)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(kind + ' · exact part surfaces', mesh)
    scene.collection.objects.link(obj)
    obj.data.materials.append(make_material(color, kind))

# Reproduce the production signs on both authored SurfaceGui faces.
font_mat = make_material((.94, .91, .82), 'Sign lettering')
for p in data['parts']:
    if not p.get('sign'):
        continue
    for side in (-1, 1):
        text = bpy.data.curves.new(p['sign'], 'FONT')
        text.body = p['sign']
        text.align_x = 'CENTER'
        text.align_y = 'CENTER'
        text.size = .57
        text.extrude = .001
        obj = bpy.data.objects.new('SurfaceGui · ' + p['sign'], text)
        scene.collection.objects.link(obj)
        pos = p['position'].copy()
        pos[2] += side * (p['size'][2] / 2 + .02)
        obj.location = point(pos)
        obj.rotation_euler = (math.radians(90), 0, 0 if side == 1 else math.pi)
        obj.data.materials.append(font_mat)

camera_data = bpy.data.cameras.new('Review camera')
camera = bpy.data.objects.new('Review camera', camera_data)
scene.collection.objects.link(camera)
scene.camera = camera
camera_data.clip_end = 5000
camera_data.lens = 40

CAMERAS = {
    '01-central-arrival': ((290, 55, 1140), (95, 10, 970), 42, 'CENTRAL / ARRIVAL', 'Executed train, station and city geometry · initial doors-closed pose'),
    '02-garden-platform': ((-275, 16, 1120), (-440, 8, 1014), 44, 'WEST GARDENS / HALT', 'Second provisional stop · connected forecourt walk · shared rail datum'),
    '03-historic-core': ((136.75, 9, 80), (136.75, 13, -120), 32, 'HISTORIC CORE / STREET STUDY', 'District A façade geometry · original procedural blockout, not final city art'),
    '04-network-context': ((1020, 750, 1550), (0, 0, 380), 42, 'DISTRICT A / RAIL CONTEXT', 'Two-stop experimental shuttle · final 12–16-station network is not integrated'),
    '06-station-front': ((235, 22, 745), (120, 14, 855), 42, 'CENTRAL / FORECOURT', 'Original portico, station lettering and roof pass · walk openings retained'),
    '05-shuttle-detail': ((192, 29, 1075), (145, 8, 1027), 47, 'S1 / TWO-CAR SHUTTLE', 'Hollow procedural body, sliding leaves and seating · not the imported EMU-1'),
}
FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
BOLD = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'

def stamp(path, title, caption):
    image = Image.open(path).convert('RGB')
    overlay = Image.new('RGBA', image.size)
    draw = ImageDraw.Draw(overlay)
    draw.rectangle((0, 0, image.width, 112), fill=(15, 28, 32, 225))
    draw.text((38, 22), 'C I V I T A S', font=ImageFont.truetype(BOLD, 31), fill=(239,232,211))
    draw.text((40, 68), title, font=ImageFont.truetype(FONT, 17), fill=(212,190,132))
    draw.text((image.width-440, 30), 'NORMAN  /  GEOMETRY REVIEW', font=ImageFont.truetype(FONT, 16), fill=(239,232,211))
    draw.text((image.width-440, 61), 'BLENDER · NOT ROBLOX STUDIO', font=ImageFont.truetype(FONT, 14), fill=(185,200,200))
    draw.rectangle((0, image.height-74, image.width, image.height), fill=(15,28,32,245))
    draw.text((38, image.height-53), caption, font=ImageFont.truetype(FONT, 16), fill=(239,232,211))
    draw.text((38, image.height-28), 'SOURCE GEOMETRY / LUNE DATA MODEL     •     REVIEW LIGHTING ONLY     •     06 NOV 2026', font=ImageFont.truetype(FONT, 12), fill=(174,192,190))
    Image.alpha_composite(image.convert('RGBA'), overlay).convert('RGB').save(path)

# Save before rendering so a bounded-memory review process always leaves the native scene.
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / 'build/review/civitas-norman-review.blend'), compress=True)
for name, (eye, target, lens, title, caption) in CAMERAS.items():
    if args.only and name not in args.only.split(','):
        continue
    camera.location = point(eye)
    camera.rotation_euler = (point(target) - camera.location).to_track_quat('-Z', 'Y').to_euler()
    camera_data.lens = lens
    scene.render.filepath = str(OUT / (name + '.png'))
    bpy.ops.render.render(write_still=True)
    stamp(scene.render.filepath, title, caption)
    print('RENDERED', name, flush=True)
# Native scene retains the exact geometry and the last camera; all camera recipes are above.
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / 'build/review/civitas-norman-review.blend'), compress=True)
print('Saved native review scene and', len(CAMERAS), 'camera recipes', flush=True)
