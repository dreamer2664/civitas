"""Regression tests for conservative spawn anchor sightlines."""
import importlib.util
import unittest
from pathlib import Path

spec=importlib.util.spec_from_file_location('sightlines',Path(__file__).resolve().parents[2]/'tools/walkaudit/sightlines.py')
m=importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


def part(name='box',x=0,y=0,z=0,sx=2,sy=2,sz=2,ry=0,transparency=0):
    return dict(id=name,name=name,x=x,y=y,z=z,sx=sx,sy=sy,sz=sz,ry=ry,transparency=transparency,walk=True,collide=True,shape='Block')


class Sightlines(unittest.TestCase):
    def test_ray_hit(self):
        interval=m.ray_interval(part(),dict(x=-4,y=0,z=0),dict(x=4,y=0,z=0))
        self.assertEqual(interval,(.375,.625))
    def test_ray_misses_above(self):
        self.assertIsNone(m.ray_interval(part(),dict(x=-4,y=2,z=0),dict(x=4,y=2,z=0)))
    def test_yaw_transform(self):
        self.assertIsNotNone(m.ray_interval(part(sx=2,sz=10,ry=90),dict(x=4,y=0,z=-4),dict(x=4,y=0,z=4)))
    def test_first_hit_not_insertion_order(self):
        hit=m.first_hit([part('far',x=6),part('near',x=2)],dict(x=0,y=0,z=0),dict(x=10,y=0,z=0))
        self.assertEqual(hit[2]['id'],'near')
    def test_transparent_collision_not_a_visual_blocker(self):
        hit=m.first_hit([part('invisible',x=2,transparency=1),part('visible',x=6)],dict(x=0,y=0,z=0),dict(x=10,y=0,z=0))
        self.assertEqual(hit[2]['id'],'visible')
    def test_no_clear_anchor_not_global_visibility_claim(self):
        spawn=part('CoreSidewalkSpawn',y=-1)
        target=part('World.BuildingMassing.Tower.Crown',x=10,y=4.5)
        target['name']='Crown'
        block=part('blocking mass',x=5,y=4.5,sx=1,sy=10,sz=10)
        result=m.audit(dict(parts=[spawn,target,block],landmarks=[dict(name='Tower')]))
        self.assertEqual(result['visibleAnchorCount'],0)
        self.assertEqual(result['status'],'NO_TESTED_ANCHOR_CLEAR')
        self.assertEqual(result['anchors'][0]['blocker'],'blocking mass')
    def test_candidate_uses_actual_highest_support(self):
        self.assertEqual(m.surface_top([part(sx=10,sz=10,y=0),part('upper',sx=10,sz=10,y=2)],dict(x=0,z=0)),3)
    def test_candidate_rejects_narrow_footprint(self):
        with self.assertRaises(ValueError):
            m.surface_top([part(sx=1)],dict(x=0,z=0))
    def test_clear_anchor_found(self):
        spawn=part('CoreSidewalkSpawn',y=-1)
        target=part('World.BuildingMassing.Tower.Crown',x=10,y=4.5)
        target['name']='Crown'
        result=m.audit(dict(parts=[spawn,target],landmarks=[dict(name='Tower')]))
        self.assertEqual(result['visibleAnchorCount'],1)


if __name__=='__main__':
    unittest.main()
