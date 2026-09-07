# Dinosaur Model Pipeline

The game accepts original GLB models through the species loaders.

## Local raptor and restored hero (2026-09-07)

T. rex now prefers `t_rex_hero.glb`, then the preserved `t_rex.glb`, then procedural visuals. The researched candidate remains an explicit opt-in.

The playable Velociraptor prefers `local_downloads/pbr_velociraptor_animated.glb`, with the original `velociraptor.glb` and procedural visuals retained as fallbacks. This local directory is Git-ignored; other checkouts continue using their baseline. Prepare the downloaded GLB with `tools/prepare_downloaded_raptor.py` in a factory-startup Blender process, passing `--source` and `--output` after `--`. Keep the original download outside the project. Runtime aliases retain native skeletal Idle1, Walk, Run1, Bite1, EatPrey, Hit1 and Death1 clips rather than substituting generated root motion. This preserves current gameplay scale/growth conventions, not historical juvenile anatomy. NPC models, combat rules and save formats are unchanged.

## Researched T. rex candidate

The evidence dossier is `docs/dinosaurs/t_rex.md`. Original stage candidates are in `assets/models/dinosaurs/researched/`; their `.blend` sources and measurements are in `art_source/researched_trex/`. They do not overwrite the baseline or hero assets.

Reproduce all stages (Blender 5.2; first stage bakes shared original 2K maps):

```powershell
& 'F:/Blender/blender.exe' --background --factory-startup --python-exit-code 1 --python tools/create_researched_trex.py -- --stage 0
foreach ($modelStage in 1..3) {
    & 'F:/Blender/blender.exe' --background --factory-startup --python-exit-code 1 --python tools/create_researched_trex.py -- --stage $modelStage --reuse-textures
    if ($LASTEXITCODE -ne 0) { throw "Stage export failed" }
}
```

Preview in the actual game with `Godot --path . -- --researched-trex`, then select T. rex Adventure. The opt-in player uses native metre dimensions and per-stage meshes, adjusts the capsule/camera, and uses exported stride metadata (Godot imports this under node `extras`). Missing candidates restore the original loader and collider conventions. Default launches remain unchanged until art acceptance.

Validate with `Godot --headless --fixed-fps 60 --path . --script res://tests/researched_trex_smoke.gd -- --researched-trex`; omit headless and add `--capture` after the separator for rendered gameplay views. `tools/review_researched_trex.py -- --stage 3 --video`, run through Blender, checks bone stance drift/loop continuity, samples deformed extents, and creates review renders plus a two-cycle walking video. It does not certify exact paleobiology or final animation polish.

Pending acceptance: closer facial/skin art review, visible toe contact on slopes, turning/strafe transitions, full-sized adult combat reach/quest clearances and sustained performance. The current combat still measures reach from the player pivot; no silent reach rebalance was made. Adult length/hip targets are SUE-based, while younger dimensions are explicitly inferred—not literal hatchling measurements. Do not promote this candidate solely because numerical tests pass.

## Supplied replacements (2026-09-06)

The new `t_rex.glb`, `velociraptor.glb`, `triceratops.glb`, and `ankylosaurus.glb` are connected to their existing playable profiles. T. rex now prefers the supplied baseline, then the preserved hero GLB, then procedural geometry. Historical hero-first notes below describe the previous setup. The baseline T. rex reuses its native skeletal Attack clip for PowerBite because that export has no separate PowerBite action. Other imported clips remain native. `tests/new_models_smoke.gd` checks replacement selection, grounding, scale and clips; `tests/trex_model_smoke.gd` explicitly retains the separate textured hero benchmark checks.

Stegosaurus remains a library asset pending a gameplay-role decision; no new species, quests or save identifiers were introduced. These supplied assets are low-poly and should not be mistaken for the final realistic art milestone.

## File locations

Place models in:

`assets/models/dinosaurs/`

Use these filenames:

- `t_rex.glb`
- `velociraptor.glb`
- `triceratops.glb`
- `psittacosaurus.glb`
- `dryosaurus.glb`
- `parasaurolophus.glb`
- `raptor_predator.glb`
- `dilophosaurus.glb`
- `carnotaurus.glb`
- `allosaurus.glb`
- `stegosaurus.glb` (generated asset library; not yet a playable profile)

## Export requirements

- Export binary glTF 2.0 (`.glb`) from Blender.
- Apply transforms and keep the model’s feet at local Y=0.
- Face the model toward Godot’s forward direction and keep one meter close to one Blender unit.
- Use simple low-poly geometry and three material groups: `Body`, `Accent`, and `Eyes`.
- Include `Idle`, `Walk`, `Run`, `Attack`, `Eat`, `Hit`, and `Defeat` animations.
- Player models should also include their species ability animation.
- Keep collision and navigation geometry in Godot wrapper scenes rather than exporting complex collision meshes.

If a file is absent or cannot be loaded, the game automatically uses its current procedural dinosaur visual.

The first T. rex silhouette is generated by `tools/create_trex_model.py` and exported to `assets/models/dinosaurs/t_rex.glb`. The higher-resolution player hero is exported to `assets/models/dinosaurs/t_rex_hero.glb` and is preferred automatically. Its animation clips are intentionally deferred to the shared rig pass so all ten dinosaurs use one consistent animation setup.

`tools/generate_5_dinosaurs.py` generates the baseline T. rex, Velociraptor, Triceratops, Ankylosaurus, and future-ready Stegosaurus assets. Each export contains a joined low-poly mesh, `Body`, `Accent`, and `Eyes` materials, a skinning armature, the seven shared animation tracks, and one species ability track. Run it from the repository root with Blender 4.4 or newer; its default output is this directory. The game continues to prefer `t_rex_hero.glb` for T. rex.
