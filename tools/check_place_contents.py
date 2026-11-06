#!/usr/bin/env python3
"""Check essential Rojo place instances exist at expected paths; not a runtime test."""
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

EXPECTED = {
    'ReplicatedStorage/Shared/Rail/ShuttleService': 'ModuleScript',
    'ServerScriptService/Services/RailDemo/RailGeometry': 'ModuleScript',
    'StarterPlayer/StarterPlayerScripts/Client/ServiceInterface': 'LocalScript',
    'ReplicatedStorage/Shared/Rail/DriverControl': 'ModuleScript',
    'ReplicatedStorage/Shared/Rail/ControlGate': 'ModuleScript',
    'ReplicatedStorage/Shared/Rail/BoardingRules': 'ModuleScript',
    'ReplicatedStorage/Shared/Rail/TrainSimulation': 'ModuleScript',
    'ReplicatedStorage/Shared/Rail/Kinematics': 'ModuleScript',
    'ServerScriptService/Services/World/WorldBootstrap': 'Script',
    'ServerScriptService/Services/RailDemo/RailDemo': 'Script',
    'StarterPlayer/StarterPlayerScripts/Client/CityInterface': 'LocalScript',
    'StarterPlayer/StarterPlayerScripts/Client/ShuttleInterface': 'LocalScript',
    'StarterPlayer/StarterPlayerScripts/Client/PassengerInterface': 'LocalScript',
}

def collect(item, prefix, found):
    props = item.find('Properties')
    name = props.find("string[@name='Name']") if props is not None else None
    if name is None or not name.text:
        raise SystemExit(f'unnamed {item.get("class")} in place')
    path = f'{prefix}/{name.text}' if prefix else name.text
    if path in found:
        raise SystemExit(f'duplicate instance path: {path}')
    found[path] = item.get('class')
    for child in item.findall('Item'):
        collect(child, path, found)

path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('build/civitas.rbxlx')
found = {}
for root in ET.parse(path).getroot().findall('Item'):
    collect(root, '', found)
for path, kind in EXPECTED.items():
    if found.get(path) != kind:
        raise SystemExit(f'expected {kind} at {path}; got {found.get(path)}')
print(f'place contents: {len(EXPECTED)} essential instances found; runtime not verified')
