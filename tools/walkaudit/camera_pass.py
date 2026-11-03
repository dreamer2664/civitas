"""Ten deterministic perspective box-geometry previews; NEVER engine screenshots.

Requires an actually merged fixes PR unless --prepare-only is specified. Geometry
comes from the untouched main World builder export. Cylinders are conservatively
boxed; material colours are approximations; no Roblox lighting/streaming/rig runs.
"""
import argparse
import base64
import hashlib
import html
import json
import math
from pathlib import Path
import urllib.request

import numpy as np
from PIL import Image, ImageDraw


def surface(parts, x, z):
    tops = []
    for p in parts:
        if not (p['walk'] and p['collide'] and p['shape'] == 'Block'):
            continue
        a = math.radians(p['ry'])
        dx, dz = x-p['x'], z-p['z']
        xx, zz = dx*math.cos(a)-dz*math.sin(a), dx*math.sin(a)+dz*math.cos(a)
        if abs(xx) <= p['sx']/2 and abs(zz) <= p['sz']/2:
            tops.append(p['y']+p['sy']/2)
    if not tops:
        raise ValueError(f'No support at camera foot point {x}, {z}')
    return max(tops)


def poses(world):
    route = world['route']
    lengths = [math.hypot(b['x']-a['x'], b['z']-a['z']) for a,b in zip(route,route[1:])]
    total = sum(lengths)
    # First capture is the selected spawn. Nine captures then cover the ENTIRE
    # original route, not a falsely shortened plaza-to-station remainder.
    out = [dict(label='SC-01 / Old Town Square', routeDistance=None,
                eye=[200, surface(world['parts'],200,75)+4.5,75],
                target=[520,44.7,75], targetLabel='Museum of Navigation')]
    for i in range(9):
        distance = total*i/8
        remaining = distance
        for index, length in enumerate(lengths):
            if remaining <= length or index == len(lengths)-1:
                a,b = route[index:index+2]
                t = 1. if i == 8 else min(1.,remaining/length)
                x,z = a['x']+(b['x']-a['x'])*t, a['z']+(b['z']-a['z'])*t
                y = surface(world['parts'],x,z)+4.5
                dx,dz = (b['x']-a['x'])/length,(b['z']-a['z'])/length
                if i == 8:  # Look back toward the station entry from the concourse.
                    dx,dz = -dx,-dz
                out.append(dict(label=f'Route {distance:.1f} / {total:.1f} studs',
                    routeDistance=distance, eye=[x,y,z], target=[x+dx*30,y-2,z+dz*30],
                    targetLabel='route tangent' if i < 8 else 'station entry / city-facing'))
                break
            remaining -= length
    return out


def clipped(vertices, near=.1):
    result=[]
    for a,b in zip(vertices,vertices[1:]+vertices[:1]):
        ia,ib = a[2]>=near,b[2]>=near
        if ia: result.append(a)
        if ia != ib:
            result.append(a+(b-a)*((near-a[2])/(b[2]-a[2])))
    return result


BASE_COLOURS={'Ground':(97,119,81),'Asphalt':(69,74,77),'Concrete':(183,178,165),
    'Cobblestone':(163,153,132),'Glass':(91,142,151),'Metal':(111,123,128),
    'Brick':(170,144,119),'Slate':(112,126,128),'Wood':(133,103,78)}
FACES=[(0,1,3,2),(4,6,7,5),(0,4,5,1),(2,3,7,6),(0,2,6,4),(1,5,7,3)]


def scene(parts):
    boxes=[]
    signs=np.array([[-1,-1,-1],[-1,-1,1],[-1,1,-1],[-1,1,1],
                    [1,-1,-1],[1,-1,1],[1,1,-1],[1,1,1]],dtype=float)
    for p in parts:
        if p['transparency'] >= .999: continue
        corners=signs*np.array([p['sx'],p['sy'],p['sz']])/2
        a=math.radians(p['ry']);c,s=math.cos(a),math.sin(a)
        corners=corners@np.array([[c,0,-s],[0,1,0],[s,0,c]])
        corners+=np.array([p['x'],p['y'],p['z']])
        colour=np.array(BASE_COLOURS.get(p['material'],(183,164,139)),dtype=float)
        boxes.append((corners,colour))
    return boxes


def render(boxes, pose, output, number):
    width,height=960,540
    eye=np.array(pose['eye'],dtype=float);forward=np.array(pose['target'],dtype=float)-eye;forward/=np.linalg.norm(forward)
    right=np.cross(forward,np.array([0.,1.,0.]));right/=np.linalg.norm(right)
    up=np.cross(right,forward)
    basis=np.stack([right,up,forward],axis=1)
    focal=width/2/math.tan(math.radians(70)/2)
    image=np.empty((height,width,3),dtype=np.uint8);image[:]=(164,190,205)
    depth=np.full((height,width),np.inf)
    light=np.array([-.3,.8,-.5]);light/=np.linalg.norm(light)
    for corners,base in boxes:
        camera=(corners-eye)@basis
        if np.max(camera[:,2])<.1 or np.min(camera[:,2])>1400: continue
        for face in FACES:
            ids=list(face)
            normal=np.cross(corners[ids[1]]-corners[ids[0]],corners[ids[2]]-corners[ids[0]])
            normal/=max(np.linalg.norm(normal),1e-9)
            colour=np.clip(base*(.67+.33*abs(float(normal@light))),0,255)
            polygon=clipped([camera[j] for j in ids])
            for j in range(1,len(polygon)-1):
                triangle=np.array([polygon[0],polygon[j],polygon[j+1]])
                xx=width/2+focal*triangle[:,0]/triangle[:,2]
                yy=height/2-focal*triangle[:,1]/triangle[:,2]
                xmin=max(0,int(math.floor(min(xx))));xmax=min(width-1,int(math.ceil(max(xx))))
                ymin=max(0,int(math.floor(min(yy))));ymax=min(height-1,int(math.ceil(max(yy))))
                if xmin>xmax or ymin>ymax: continue
                denominator=(yy[1]-yy[2])*(xx[0]-xx[2])+(xx[2]-xx[1])*(yy[0]-yy[2])
                if abs(denominator)<1e-9: continue
                gridx,gridy=np.meshgrid(np.arange(xmin,xmax+1)+.5,np.arange(ymin,ymax+1)+.5)
                wa=((yy[1]-yy[2])*(gridx-xx[2])+(xx[2]-xx[1])*(gridy-yy[2]))/denominator
                wb=((yy[2]-yy[0])*(gridx-xx[2])+(xx[0]-xx[2])*(gridy-yy[2]))/denominator
                wc=1-wa-wb
                mask=(wa>=0)&(wb>=0)&(wc>=0)
                inverse=wa/triangle[0,2]+wb/triangle[1,2]+wc/triangle[2,2]
                z=1/np.maximum(inverse,1e-12)
                local=depth[ymin:ymax+1,xmin:xmax+1]
                mask &= z<local
                mask &= z<1400
                local[mask]=z[mask]
                image[ymin:ymax+1,xmin:xmax+1][mask]=colour
    picture=Image.fromarray(image);draw=ImageDraw.Draw(picture)
    draw.rectangle((0,0,width,47),fill=(15,25,32))
    draw.text((12,8),f"{number:02d}/10 | {pose['label']}",fill='white')
    draw.text((12,27),'HEADLESS BOX-GEOMETRY PREVIEW - NOT A ROBLOX ENGINE SCREENSHOT',fill=(255,204,101))
    draw.rectangle((0,height-25,width,height),fill=(15,25,32))
    draw.text((12,height-18),'70deg horizontal FOV | radius/rig/lighting/streaming NOT simulated | materials approximated',fill='white')
    picture.save(output)


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--world',type=Path,required=True)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--main-sha',required=True)
    parser.add_argument('--prepare-only',action='store_true')
    args=parser.parse_args();world=json.loads(args.world.read_text());args.out.mkdir(parents=True,exist_ok=True)
    cameras=poses(world)
    manifest={'engineCaptured':False,'mainRevision':args.main_sha,'geometrySHA256':hashlib.sha256(args.world.read_bytes()).hexdigest(),
        'status':'POSES_PREPARED' if args.prepare_only else 'HEADLESS_PREVIEW_ONLY',
        'horizontalFOVDegrees':70,'resolution':[960,540],'cameraCount':len(cameras),'cameras':cameras,
        'limitations':['Not an engine camera pass','Cylinders conservatively boxed','Approximate material colours',
            'No rig, physics, streaming, engine lighting, texture or mobile validation']}
    if not args.prepare_only:
        url='https://api.github.com/repos/dreamer2664/civitas/pulls/15'
        with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'CIVITAS-WALK-camera'}),timeout=20) as response:
            pr=json.load(response)
        if not pr['merged']: raise SystemExit('PR #15 not merged; final post-merge camera evidence is gated')
        manifest['fixesPRMergedAt']=pr['merged_at'];manifest['fixesPRMergeCommit']=pr['merge_commit_sha']
        boxes=scene(world['parts']);cards=[]
        for number,pose in enumerate(cameras,1):
            filename=f'frame-{number:02d}.png';path=args.out/filename
            render(boxes,pose,path,number)
            data=base64.b64encode(path.read_bytes()).decode()
            cards.append(f'<figure><img src="data:image/png;base64,{data}" alt="{html.escape(pose["label"])}"><figcaption>{number:02d}: {html.escape(pose["label"])}</figcaption></figure>')
            print('RENDERED',filename,flush=True)
        page='<!doctype html><html><meta charset="utf-8"><title>WALK route camera geometry previews</title><style>body{background:#101b24;color:#e3edf5;font:16px system-ui;max-width:1100px;margin:40px auto;padding:20px}img{width:100%;height:auto}figure{margin:28px 0}p{line-height:1.6}code{color:#ffcc65}</style><h1>10 route camera geometry previews</h1><p><strong>Not Roblox screenshots.</strong> Actual exported main box geometry, CPU depth buffer, approximate materials. Engine first-frame, streaming, rig and visual acceptance remain unverified.</p><p>Main: <code>'+html.escape(args.main_sha)+'</code></p>'+''.join(cards)+'</html>'
        (args.out/'index.html').write_text(page)
    (args.out/'camera-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print(manifest['status'],len(cameras),'camera poses')


if __name__=='__main__':
    main()
