"""Continuous route/bounding-footprint radius envelopes, NOT engine streaming.

For a yawed rectangular footprint, disk intersection is equivalent to a point
inside the rounded rectangle (two strips plus four corner disks). Clip a route
segment against those primitives, then sweep entry/exit events over the entire
segment. Closed-boundary contacts count; no 16-stud sampling can miss a peak.
Cylinder parts retain their conservative exported box bounds.
"""
import json
import math
from pathlib import Path


def rect_interval(ax, az, dx, dz, hx, hz):
    low, high = 0.0, 1.0
    for origin, delta, half in ((ax, dx, hx), (az, dz, hz)):
        if delta == 0:
            if abs(origin) > half:
                return None
        else:
            u, v = sorted(((-half-origin)/delta, (half-origin)/delta))
            low, high = max(low, u), min(high, v)
            if low > high:
                return None
    return low, high


def disk_interval(ax, az, dx, dz, cx, cz, radius):
    ox, oz = ax-cx, az-cz
    aa = dx*dx+dz*dz
    cc = ox*ox+oz*oz-radius*radius
    if aa == 0:
        return (0.0, 1.0) if cc <= 0 else None
    bb = 2*(ox*dx+oz*dz)
    discriminant = bb*bb-4*aa*cc
    if discriminant < 0:
        return None
    root = math.sqrt(discriminant)
    low = max(0.0, (-bb-root)/(2*aa))
    high = min(1.0, (-bb+root)/(2*aa))
    return (low, high) if low <= high else None


def part_interval(part, a, b, radius):
    """Parameter interval where a moving disk touches the part bounding footprint."""
    angle = math.radians(part['ry'])
    cosine, sine = math.cos(angle), math.sin(angle)
    px, pz = a['x']-part['x'], a['z']-part['z']
    ax, az = px*cosine-pz*sine, px*sine+pz*cosine
    wx, wz = b['x']-a['x'], b['z']-a['z']
    dx, dz = wx*cosine-wz*sine, wx*sine+wz*cosine
    hx, hz = part['sx']/2, part['sz']/2
    candidates = [rect_interval(ax,az,dx,dz,hx+radius,hz),
                  rect_interval(ax,az,dx,dz,hx,hz+radius)]
    candidates += [disk_interval(ax,az,dx,dz,x,z,radius)
                   for x in (-hx,hx) for z in (-hz,hz)]
    intervals = [i for i in candidates if i is not None]
    # A rounded rectangle is convex, so its line intersection is one interval.
    return (min(i[0] for i in intervals),max(i[1] for i in intervals)) if intervals else None


def segment_counts(parts, a, b, radius):
    events = {0.0:[0,0],1.0:[0,0]}
    for part in parts:
        interval = part_interval(part,a,b,radius)
        if interval is None:
            continue
        low, high = interval
        events.setdefault(low,[0,0])[0] += 1
        events.setdefault(high,[0,0])[1] += 1
    current, maximum, minimum, peak_t = 0, -1, len(parts), 0.0
    for t, (starts, ends) in sorted(events.items()):
        current += starts
        if current > maximum:
            maximum, peak_t = current, t
        minimum = min(minimum,current)
        current -= ends
        # Do not count the non-domain interval after t=1 as an empty scene.
        if t < 1:
            minimum = min(minimum,current)
    return minimum, maximum, peak_t


def envelopes(parts, route, radii=(64,256,384,512,1024)):
    if len(route) < 2 or not parts:
        raise ValueError('Nonempty real geometry and route required')
    results = {}
    for radius in radii:
        if not math.isfinite(radius) or radius < 0:
            raise ValueError('Radius must be finite and nonnegative')
        low, high, peak = len(parts), -1, None
        for index,(a,b) in enumerate(zip(route,route[1:])):
            small, large, t = segment_counts(parts,a,b,radius)
            low = min(low,small)
            if large > high:
                high = large
                peak = dict(x=a['x']+(b['x']-a['x'])*t,z=a['z']+(b['z']-a['z'])*t,segment=index+1,t=t)
        results[str(radius)] = dict(minIntersectingParts=low,maxIntersectingParts=high,
            peakPosition=peak,method='continuous analytic rounded-rectangle interval sweep',
            engineMeasured=False)
    return results


if __name__=='__main__':
    root=Path(__file__).resolve().parents[2]
    data=json.loads((root/'docs/reports/walkability-world.json').read_text())
    result=dict(engineMeasured=False,partCount=len(data['parts']),
        assumptions='All exported bounding footprints; cylinders conservatively boxed; no model retention/culling/shadow simulation',
        streamingEnvelope=envelopes(data['parts'],data['route']))
    (root/'docs/reports/walkability-streaming-exact.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2))
