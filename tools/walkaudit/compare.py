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
assert len(by_source)==len(py['sidewalkChecks']), 'sidewalk IDs must identify unique constructed pieces'
for check in lua['sidewalks']:
    other=by_source[check['source']]
    assert math.isclose(check['result']['maxStep'],other['maxStepStuds'],abs_tol=1e-7), check['source']
    def normalized(defects):
        return sorted((d['code'],round(d['x'],6),round(d['z'],6),d['detail']) for d in defects)
    assert normalized(check['result']['defects'])==normalized(other['defects']), check['source']
assert lua['crossingCount']==len(py['crossingChecks']), 'crossing inventories disagree'
by_crossing={(c['x'],c['z'],c['axis']):c for c in py['crossingChecks']}
for crossing in lua['crossings']:
    other=by_crossing[(crossing['x'],crossing['z'],crossing['axis'])]
    assert math.isclose(crossing['result']['length'],other['length'],abs_tol=1e-7), 'crossing lengths disagree'
    assert math.isclose(crossing['result']['maxStep'],other['maxStepStuds'],abs_tol=1e-7), 'crossing step checks disagree'
    assert normalized(crossing['result']['defects'])==normalized(other['defects']), 'crossing defects disagree'
print(f"PARITY PASS: independent Luau/Python audits agree on parts, seal, route, steps, {lua['sidewalkCount']} sidewalk pieces and {lua['crossingCount']} crossing axes")

stream=json.loads((root/'walkability-streaming-exact.json').read_text())
assert stream['streamingEnvelope']==py['streamingEnvelope'], 'streaming report and audit integration disagree'
print('STREAMING PARITY PASS: report and audit use identical continuous bounding-footprint envelopes')
