"""Regression tests for continuous (not sampled) bounding-footprint envelopes."""
import importlib.util
import math
import random
import unittest
from pathlib import Path

spec=importlib.util.spec_from_file_location('walk_streaming',Path(__file__).resolve().parents[2]/'tools/walkaudit/streaming.py')
m=importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


def part(x=0,z=0,sx=2,sz=2,ry=0):
    return dict(x=x,z=z,sx=sx,sz=sz,ry=ry)


def count(parts,x,z,radius):
    result=0
    for p in parts:
        angle=math.radians(p['ry'])
        dx,dz=x-p['x'],z-p['z']
        px,pz=dx*math.cos(angle)-dz*math.sin(angle),dx*math.sin(angle)+dz*math.cos(angle)
        result += max(0,abs(px)-p['sx']/2)**2+max(0,abs(pz)-p['sz']/2)**2 <= radius**2+1e-8
    return result


class ContinuousEnvelope(unittest.TestCase):
    def test_peak_between_old_samples(self):
        p=[part(x=7,sx=.2),part(x=9,sx=.2)]
        result=m.envelopes(p,[dict(x=0,z=0),dict(x=100,z=0)],(1,))['1']
        self.assertEqual(result['maxIntersectingParts'],2)
        self.assertEqual(count(p,0,0,1),0)
        self.assertEqual(count(p,16,0,1),0)
    def test_rounded_corner_not_expanded_square(self):
        self.assertIsNone(m.part_interval(part(),dict(x=2,z=2),dict(x=2,z=2),1))
    def test_tangent_contact_counts(self):
        self.assertIsNotNone(m.part_interval(part(),dict(x=2,z=1),dict(x=2,z=1),1))
    def test_closed_endpoint_counts(self):
        result=m.envelopes([part(x=11)],[dict(x=0,z=0),dict(x=10,z=0)],(0,))['0']
        self.assertEqual(result['maxIntersectingParts'],1)
        self.assertEqual(result['minIntersectingParts'],0)
    def test_entire_route_inside_large_part(self):
        result=m.envelopes([part(sx=100,sz=100)],[dict(x=0,z=0),dict(x=10,z=0)],(0,))['0']
        self.assertEqual(result['maxIntersectingParts'],1)
        self.assertEqual(result['minIntersectingParts'],1)
    def test_yawed_footprint(self):
        self.assertIsNotNone(m.part_interval(part(sx=2,sz=10,ry=90),dict(x=4,z=0),dict(x=4,z=0),0))
        self.assertIsNone(m.part_interval(part(sx=2,sz=10,ry=90),dict(x=0,z=4),dict(x=0,z=4),0))
    def test_zero_length_route(self):
        result=m.envelopes([part()],[dict(x=0,z=0),dict(x=0,z=0)],(1,))['1']
        self.assertEqual(result['minIntersectingParts'],1)
    def test_invalid_radius_rejected(self):
        with self.assertRaises(ValueError):
            m.envelopes([part()],[dict(x=0,z=0),dict(x=1,z=0)],(-1,))
    def test_dense_reference_cannot_exceed_analytic_peak(self):
        rng=random.Random(2664)
        p=[part(x=rng.uniform(-10,10),z=rng.uniform(-10,10),sx=rng.uniform(.2,5),sz=rng.uniform(.2,5),ry=rng.uniform(-180,180)) for _ in range(40)]
        result=m.envelopes(p,[dict(x=-12,z=-5),dict(x=12,z=5)],(2,))['2']
        samples=[count(p,-12+24*i/10000,-5+10*i/10000,2) for i in range(10001)]
        self.assertGreaterEqual(result['maxIntersectingParts'],max(samples))
        self.assertLessEqual(result['minIntersectingParts'],min(samples))
        peak=result['peakPosition']
        self.assertEqual(count(p,peak['x'],peak['z'],2),result['maxIntersectingParts'])


if __name__=='__main__':
    unittest.main()
