"""Physical grade is not a walkability quality score; preserve separate gates."""
import importlib.util
from pathlib import Path
import unittest
spec=importlib.util.spec_from_file_location('parks',Path(__file__).resolve().parents[2]/'tools/walkaudit/parks.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)


def part(**kw):
    p=dict(id='base',name='CollidableGround',x=0,y=-1,z=0,sx=20,sy=2,sz=20,rx=0,ry=0,rz=0,shape='Block',walk=True,collide=True,anchored=True)
    p.update(kw);return p


R=dict(minX=-1,maxX=1,minZ=-1,maxZ=1)
class Parks(unittest.TestCase):
    def inventory(self):
        return dict(parts=[part()],blocks=[dict(name='A',superblock=True,cells=[dict(xi=1,zi=1),dict(xi=2,zi=1)])],
            declaredSuperblocks=[dict(name='A',cells=[[1,1],[2,1]])],gridX=[-1,0,1],gridZ=[-1,1],
            plaza=dict(centerX=0,centerZ=0,width=1,depth=1),pocketSquares=[])
    def test_missing_declared_superblock_cannot_pass(self):
        data=self.inventory();data['declaredSuperblocks'][0]['name']='B'
        with self.assertRaises(ValueError):m.build(data)
    def test_declared_membership_must_match(self):
        data=self.inventory();data['declaredSuperblocks'][0]['cells']=[[1,1]]
        with self.assertRaises(ValueError):m.build(data)
    def test_flat_mean_is_zero(self):
        r=m.region('test','block',[R],[part()])
        self.assertEqual(r['meanGrade'],0)
        self.assertTrue(r['groundSealed'])
    def test_tilt_not_silently_zero(self):
        r=m.region('test','block',[R],[part(rx=10)])
        self.assertIsNone(r['meanGrade'])
        self.assertFalse(r['geometryEvidencePass'])
    def test_noncollidable_base_no_seal(self):
        self.assertFalse(m.region('test','block',[R],[part(collide=False)])['groundSealed'])
    def test_l_domain_does_not_fill_missing_cell(self):
        block=dict(cells=[dict(xi=1,zi=1),dict(xi=2,zi=1),dict(xi=1,zi=2)])
        cells=m.cell_domain(block,[0,1,2],[0,1,2])
        self.assertEqual(sum((r['maxX']-r['minX'])*(r['maxZ']-r['minZ']) for r in cells),3)
    def test_yawed_polygon_clip(self):
        self.assertAlmostEqual(m.intersection_area(part(sx=2,sz=2,ry=45),dict(minX=0,maxX=10,minZ=-10,maxZ=10)),2)
    def test_invalid_cell_fails(self):
        with self.assertRaises(ValueError):m.cell_domain(dict(cells=[dict(xi=3,zi=1)]),[0,1],[0,1])
    def test_tiny_edge_shortfall_fails(self):
        self.assertFalse(m.contains(part(sx=1.9999999,sz=2),R))
    def test_zero_grade_does_not_hide_unclimbable_step(self):
        r=m.region('test','block',[R],[part(),part(id='raised',name='raised',y=1,sy=2)])
        self.assertEqual(r['meanGrade'],0)
        self.assertEqual(r['supportStepUpperBoundStuds'],2)
        self.assertFalse(r['geometryEvidencePass'])


if __name__=='__main__':unittest.main()
