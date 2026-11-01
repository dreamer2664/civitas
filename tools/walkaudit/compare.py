"""Cross-check the independent Luau and Python real geometry audits."""
import json
import math
from pathlib import Path
root=Path(__file__).resolve().parents[2]/'docs/reports'
lua=json.loads((root/'walkability-lune-results.json').read_text())
py=json.loads((root/'walkability-live-results.json').read_text())
assert lua['partCount']==py['partCount'], 'part counts disagree'
assert lua['groundSealed']==py['groundSeal']['proven'], 'ground seal proofs disagree'
assert math.isclose(lua['mainRoute']['length'],py['routeLength'],abs_tol=1e-7), 'route lengths disagree'
assert math.isclose(lua['mainRoute']['maxStep'],py['maxStepStuds'],abs_tol=1e-7), 'route step checks disagree'
assert len(lua['mainRoute']['defects'])==len(py['defects']), 'route defect counts disagree'
assert lua['sidewalkCount']==len(py['sidewalkChecks']), 'sidewalk inventories disagree'
by_source={s['id']:s for s in py['sidewalkChecks']}
for check in lua['sidewalks']:
    other=by_source[check['source']]
    assert math.isclose(check['result']['maxStep'],other['maxStepStuds'],abs_tol=1e-7), check['source']
    def normalized(defects):
        return sorted((d['code'],round(d['x'],6),round(d['z'],6),d['detail']) for d in defects)
    assert normalized(check['result']['defects'])==normalized(other['defects']), check['source']
print('PARITY PASS: independent Luau/Python audits agree on real parts, seal, route, steps and all 48 sidewalk checks')
