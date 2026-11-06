# Norman's geometry review

This pipeline executes `CityBuilder` and `RailGeometry` in **Lune's data model**, records each visible part's authored size, Position, Orientation, colour, material and collision flag, then renders those boxes/cylinders in Blender. No invented train or architecture is substituted. Source SurfaceGui text is reproduced from the SignText attribute. Lighting, shader roughness, framing and atmospheric sky are Blender presentation, **not game lighting**. This is not a Studio capture or a physics/streaming test.

Lune does not couple Position/Orientation/CFrame properties like Roblox. The exporter deliberately reads Position and Orientation, the properties authored by these builders; runtime door animation is not executed. Geometry is the initial doors-closed pose. New builder changes using CFrame must extend the exporter rather than silently misrepresent transforms.

```
bash tools/install-tools.sh
lune run tools/review/export_geometry.luau
python -m pip install bpy==5.1.2 pillow
bash tools/review/render_all.sh
```

The JSON and native `.blend` go to `build/review/` (generated, ignored); inspected PNGs go to `evidence/norman/renders/`. The native scene can be regenerated, and is supplied in the final local handoff if space permits. Original game units are studs; rendering uses 0.28 metres per stud with X east, Blender Y = -Roblox Z, Blender Z = Roblox Y. Rotations use Roblox Y-X-Z order before the coordinate conversion.

System libraries for the PyPI Blender wheel on minimal Debian: `sudo apt-get install libxkbcommon0 libxrender1 libxi6 libxxf86vm1 libsm6 libgl1`. Render each camera in a separate process (the shell script does this); batching cameras in one Cycles process exceeded the 2 GiB review machine memory.
