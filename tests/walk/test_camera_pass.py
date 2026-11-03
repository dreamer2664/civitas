"""Camera-proxy recipe tests. These do not represent an engine camera run."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
import numpy as np
from PIL import Image

root=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('camera_pass',root/'tools/walkaudit/camera_pass.py')
camera=importlib.util.module_from_spec(spec)
spec.loader.exec_module(camera)


class CameraRecipe(unittest.TestCase):
    def test_ten_poses_keep_spawn_and_full_original_route(self):
        import json
        world=json.loads((root/'docs/reports/walkability-world.json').read_text())
        poses=camera.poses(world)
        self.assertEqual(len(poses),10)
        self.assertEqual([poses[0]['eye'][i] for i in (0,2)],[200,75])
        self.assertEqual([poses[1]['eye'][i] for i in (0,2)],
                         [world['route'][0][i] for i in ('x','z')])
        self.assertEqual([poses[-1]['eye'][i] for i in (0,2)],
                         [world['route'][-1][i] for i in ('x','z')])
        self.assertGreater(poses[-1]['routeDistance'],1500)

    def test_near_plane_rejects_triangles_behind_camera(self):
        vertices=[np.array([-1.,0.,-2.]),np.array([1.,0.,-2.]),np.array([0.,1.,-2.])]
        self.assertEqual(camera.clipped(vertices),[])

    def test_near_plane_clips_instead_of_projecting_behind_camera(self):
        vertices=[np.array([-1.,0.,-2.]),np.array([1.,0.,2.]),np.array([0.,1.,2.])]
        polygon=camera.clipped(vertices)
        self.assertEqual(len(polygon),4)
        self.assertTrue(all(v[2]>=.1-1e-9 for v in polygon))

    def test_rendered_proxy_has_expected_dimensions_and_visible_geometry(self):
        corners=np.array([[-1,-1,3],[-1,-1,5],[-1,1,3],[-1,1,5],
                          [1,-1,3],[1,-1,5],[1,1,3],[1,1,5]],dtype=float)
        with tempfile.TemporaryDirectory() as directory:
            target=Path(directory)/'test.png'
            camera.render([(corners,np.array([190.,140.,100.]))],
                          {'eye':[0,0,0],'target':[0,0,1],'label':'fixture'},target,1)
            image=Image.open(target)
            self.assertEqual(image.size,(960,540))
            self.assertNotEqual(image.getpixel((480,270)),(164,190,205))


if __name__=='__main__':
    unittest.main()
