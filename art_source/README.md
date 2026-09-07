# T. rex authoring source

`t_rex_hero.blend` is the editable source for the original juvenile benchmark.
Rebuild from the repository root with:

```powershell
& 'F:\Blender\blender.exe' --background --python tools/create_trex_model.py --python-exit-code 1
& 'F:\GODOT\Godot_v4.7.2-stable_win64_console.exe' --editor --headless --path . --import
& 'F:\GODOT\Godot_v4.7.2-stable_win64_console.exe' --path . --rendering-method gl_compatibility --fixed-fps 60 --script res://tests/trex_model_smoke.gd
```

The deterministic authoring script replaces the generated GLB, source Blender
scene, and four 2048px texture maps. Preserve manual Blender edits separately
before rebuilding. `.gdignore` keeps the source scene out of Godot's runtime
imports; the game loads `assets/models/dinosaurs/t_rex_hero.glb`.

Design coordinates are converted once from Godot Y-up to Blender Z-up before
modeling, binding, and animation. Blender's normal glTF Y-up export then produces
an upright, -Z-facing dinosaur. See the [Blender glTF documentation](https://docs.blender.org/manual/en/5.1/addons/import_export/scene_gltf2.html).

The mesh has 33,000 triangles, smooth vertex normals, six material slots, and
one deforming skin. The body/neck/skull/tail surface is blended with voxel
remeshing; the jaw, eyes, toes, teeth, and claws have their own weights.
Original noise and cellular scale detail are baked into base color, tangent
normal, roughness, and occlusion maps. No downloaded geometry or textures are used.

Actions: Idle, Walk, Run, Attack, Eat, Hit, Stagger, Defeat, Roar, PowerBite.
Walk/run use baked two-link leg positioning, ground clearance during swing,
tail counterbalance, and breathing. Godot blends clip changes and adjusts
locomotion playback rate. Surface-dependent foot IK and cinematic animation
polish remain future work; this pass does not claim photorealistic art quality.

The rendered smoke samples actual deformed vertices for all nine gameplay
actions, rejects collapsed/exploded geometry, checks PBR texture bindings,
checks juvenile/adult grounding, and tests missing-model fallback paths.
It writes review images to `.validation/trex_*.png`.
