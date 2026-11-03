"""Guard the Manager's canonical naming source and disabled unbuilt anchors."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('canonical_names',ROOT/'tools/walkaudit/names.py')
names=importlib.util.module_from_spec(spec)
spec.loader.exec_module(names)


class CanonicalNames(unittest.TestCase):
    def generate(self, transform=lambda text:text):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);(root/'audit').mkdir()
            (root/'NAMES.md').write_text(transform((ROOT/'NAMES.md').read_text()))
            (root/'audit/spawn-anchor-ruling.json').write_bytes((ROOT/'audit/spawn-anchor-ruling.json').read_bytes())
            with patch.object(names,'ROOT',root):
                return names.outputs()

    def test_all_four_names_match_and_no_runtime_activation_is_fabricated(self):
        data=json.loads(self.generate()['audit/canonical-spawns.json'])
        self.assertEqual(len(data['spawns']),4)
        self.assertFalse(any(r['runtimeActive'] for r in data['spawns']))
        self.assertFalse(data['spawns'][1]['built'])
        self.assertTrue(data['spawns'][0]['primary'])

    def test_missing_district_is_rejected(self):
        with self.assertRaises(ValueError):
            self.generate(lambda s:'\n'.join(line for line in s.splitlines() if not line.startswith('| SC-04')))

    def test_reserved_harbour_cannot_silently_become_a_teleport(self):
        with self.assertRaises(ValueError):
            self.generate(lambda s:s.replace('teleport disabled','teleport enabled'))

    def test_primary_anchor_must_match_the_centroid_ruling(self):
        with self.assertRaises(ValueError):
            self.generate(lambda s:s.replace('(200, 0.575, 75)','(201, 0.575, 75)'))


if __name__=='__main__':
    unittest.main()
