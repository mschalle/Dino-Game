# Generated terrain geometry

These 32 original terrain resources contain the 65x65 visual and 33x33 collision meshes for the sixteen reserve chunks, plus exact authoring height samples. They are generated data, not manually edited assets.

Regenerate after editing `valley_terrain.gd` or `jungle_habitat.gd`:

```powershell
& 'F:\GODOT\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tools/bake_terrain.gd
```

Run `tests/terrain_bake_smoke.gd` or the full roadmap validation before delivery. The parity test compares all mesh arrays, faces and saved height samples against procedural generation, and exercises stale-version/source and missing-bake fallback.

Runtime checks the bake version, origin, resolution and source fingerprint when source files are present. If exported compiled scripts omit source, the version/coordinate checks remain, but source parity must have passed before packaging. Increment the bake version for incompatible format changes. Missing or stale resources use procedural construction, so fallback remains functional but slower. Keep these resources in the exported project; packaged validation is still required.
