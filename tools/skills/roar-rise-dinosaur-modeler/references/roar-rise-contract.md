# Live project integration contract

Repository: `C:/Users/mscha/OneDrive/Documents/ChatGPT/Game Development`.
Verify paths and current code before use; these are discovery pointers, not immutable behavior.

- Assets: `assets/models/dinosaurs/`; documentation: `MODEL_PIPELINE.md`.
- Blender: `F:/Blender/blender.exe`; Godot console: `F:/GODOT/Godot_v4.7.2-stable_win64_console.exe`.
- Generators: `tools/create_trex_model.py`, `tools/generate_5_dinosaurs.py`. Inspect before invoking; a primitive generator is not a realistic modeling solution by itself.
- Loaders: `player.gd`, `prey.gd`, `predator.gd`; profiles: `dinosaur_profiles.gd`, `creature_profiles.gd`.
- Current T. rex candidates: `t_rex.glb`, `t_rex_hero.glb`. Read `_imported_model_paths()` to determine live precedence. The supplied baseline was recently prioritized; the larger file is not automatically the active model.
- Stegosaurus is currently a library candidate, not an approved playable profile. Verify roster rather than inferring gameplay from a filename.

## Scale migration warning

At the 2026-09-06 inspection, `player.gd::_normalize_imported_model()` normalized T. rex to 2.05 m visual height and other species to 1.6 m. `grow_to()` applied a uniform scale. This is a compatibility convention, **not paleontological scale or age-specific anatomy**. Do not carry it into a scientific-scale implementation without explicit species/stage targets. Inspect all player/NPC loading and growth consumers before changing it.

Author Blender Z-up, facing -Y, feet at Z=0, and export glTF Y-up. Check actual Godot forward orientation rather than compensating for errors through camera placement. Keep the pivot under the torso and collision/navigation geometry separate from the visual mesh.

## Materials and animation

Preserve core names Body, Accent and Eyes where used by cosmetics. Realistic assets additionally use Teeth, Claws and optionally Mouth. Inspect whether runtime cosmetics overwrite authored PBR materials.

Expected shared clips: Idle, Walk, Run, Attack, Eat, Hit, Defeat. T. rex also requires Roar and PowerBite; inspect other profile abilities. Existing baseline PowerBite may alias Attack: preserve as a fallback, but author and validate distinct motion for the realism upgrade. Retain imported skeletal tracks and working fallbacks.

## Commands and gates

Use staged exports; do not regenerate the entire roster for a one-species change. Run an import check with the installed engine when required, followed by:

```powershell
& 'F:/GODOT/Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/new_models_smoke.gd
& 'F:/GODOT/Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/run_tests.gd
& 'F:/GODOT/Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/active_run_smoke.gd -- --capture
git diff --check
```

`tests/trex_model_smoke.gd` is the separate rendered hero PBR/skin benchmark. Run it for hero edits. Existing tests may encode old default selection or generic size: change those assertions only for an authorized new contract and retain independent realistic-quality checks. Add measured stage-scale and motion validation, not only required clip names.

Full gate: `tools/roadmap_validation.ps1 -Godot <console executable>`. Read its coverage before claiming completion. Logs and cache permission errors must be distinguished from runtime script failures; never suppress genuine animation or model errors.
