"""Regression tests for exact yawed clipping / audit over constructed-part exports."""
import importlib.util
from pathlib import Path
import unittest

spec=importlib.util.spec_from_file_location('world_audit',Path(__file__).resolve().parents[2]/'tools/walkaudit/audit_world.py')
m=importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


def part(name='CollidableGround',x=800,z=0,sx=1600,sz=20,y=-1,sy=2,walk=True,collide=True,ry=0):
    return dict(name=name,id=name,x=x,y=y,z=z,sx=sx,sy=sy,sz=sz,rx=0,ry=ry,rz=0,walk=walk,collide=collide,shape='Block',anchored=True)


def data(parts):
    return dict(parts=parts,route=[dict(x=2,z=0),dict(x=1598,z=0)],bounds=dict(minX=0,maxX=1600,minZ=-10,maxZ=10))


class ExactWorldAudit(unittest.TestCase):
    def test_full_base_solid_seals_every_coordinate(self):
        r=m.audit(data([part()]))
        self.assertTrue(r['groundSeal']['proven'])
        self.assertEqual(r['defects'],[])
    def test_missing_collidable_base_cannot_pass_seal(self):
        r=m.audit(data([part(collide=False)]))
        self.assertFalse(r['groundSeal']['proven'])
    def test_narrow_gap_not_masked_by_base_when_above_it(self):
        # No base: gap should be detected even though far below sample spacing.
        r=m.audit(data([part(x=50,sx=100),part(x=850.005,sx=1499.99)]))
        self.assertTrue(any(d['code']=='ROUTE_GAP' for d in r['defects']))
    def test_1_21_step_fails(self):
        r=m.audit(data([part(),part('raised',x=1200,sx=800,y=0.605,sy=1.21)]))
        self.assertTrue(any(d['code']=='STEP' for d in r['defects']))
    def test_thin_wall_detected(self):
        r=m.audit(data([part(),part('wall',sx=0.001,y=3,sy=6,walk=False)]))
        self.assertTrue(any(d['code']=='BODY_BLOCKED' for d in r['defects']))
    def test_yawed_rectangle_interval(self):
        p=part(x=0,z=0,sx=2,sz=10,ry=90)
        lo,hi=m.clip(p,dict(x=-10,z=0),dict(x=10,z=0),0)
        self.assertAlmostEqual(lo,0.25)
        self.assertAlmostEqual(hi,0.75)
    def test_supported_centerline_is_not_enough(self):
        r=m.audit(data([part(sz=1)]))
        self.assertTrue(any(d['code']=='ROUTE_GAP' for d in r['defects']))
    def test_overhead_canopy_clearance(self):
        r=m.audit(data([part(),part('canopy',sx=10,y=9,sy=1,walk=False)]))
        self.assertFalse(any(d['code']=='BODY_BLOCKED' for d in r['defects']))
    def test_visual_false_floor_rejected_even_with_sealed_base(self):
        r=m.audit(data([part(),part('false_floor',y=0.5,collide=False)]))
        self.assertTrue(any(d['code']=='NONCOLLIDABLE_SURFACE' for d in r['defects']))
    def test_tiny_ground_edge_shortfall_not_accepted(self):
        r=m.audit(data([part(sx=1599.999999)]))
        self.assertFalse(r['groundSeal']['proven'])
    def test_station_and_city_spawn(self):
        r=m.audit(data([part()]))
        self.assertTrue(all(p['geometrySafe'] for p in r['spawnChecks']))


if __name__=='__main__':
    unittest.main()
