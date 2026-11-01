"""Run train-door and station-route sampling together against the two GLBs.

The checks share a representative platform-2 point (x=-10m, y=-3.2m).
This is not a continuous collision sweep, Studio test, or street connection.
"""
import os,runpy,sys
if '--gltf' not in sys.argv:
 raise RuntimeError('Run from factory startup with -- --gltf to audit the exported GLBs')
D=os.path.dirname(os.path.abspath(__file__))
runpy.run_path(os.path.join(D,'verify_passenger_route.py'))
runpy.run_path(os.path.join(D,'verify_boarding.py'))
print('SEAM_SAMPLES_PASS: representative open train door -> platform 2 -> ramps -> bridge -> concourse threshold')
print('SEAM_LIMIT: 0.10m unsupported step, sparse sample corridors, no continuous humanoid, street or Studio validation')
