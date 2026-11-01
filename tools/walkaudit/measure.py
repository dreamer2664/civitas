"""Static evidence only. Never reports engine draw calls or streamed counts."""
import json
import hashlib
import subprocess
import xml.etree.ElementTree as ET
from pathlib import Path

root = Path(__file__).resolve().parents[2]
result = json.loads((root / 'docs/reports/walkability-results.json').read_text())
project = json.loads((root / 'default.project.json').read_text())
place = ET.parse(root / 'docs/reports/walkability-milestone.rbxlx')
workspace = next((i for i in place.iter('Item') if i.attrib.get('class') == 'Workspace'), None)
classes = {'Part', 'MeshPart', 'UnionOperation', 'WedgePart', 'SpawnLocation', 'TrussPart'}
count = sum(i.attrib.get('class') in classes for i in workspace.iter('Item')) if workspace is not None else 0
metrics = {
    'sourceRevision': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip(),
    'sourceSHA256': {str(path.relative_to(root)):hashlib.sha256(path.read_bytes()).hexdigest()
        for folder in ('src/server/World','src/server/Walkability','src/server/Spawn','tools/walkaudit','tests/walk')
        for path in sorted((root/folder).glob('*')) if path.suffix in ('.luau','.py','.sh')},
    'staticWorkspaceParts': count,
    'generatedWalkableParts': result.get('partCount', result.get('parts')),
    'drawCalls': None,
    'unbatchedMainPassEstimate': result.get('unbatchedMainPassEstimate'),
    'streamingEnvelope': result.get('streamingEnvelope'),
    'reason': 'No generator export available' if result['status'] == 'BLOCKED' else 'Engine profiling required; parts are not draw calls',
    'streaming': project['tree']['Workspace']['$properties'],
}
(root / 'docs/reports/walkability-metrics.json').write_text(json.dumps(metrics, indent=2)+'\n')
print(json.dumps(metrics, indent=2))
