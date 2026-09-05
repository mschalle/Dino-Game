# Roar & Rise

A colorful, all-ages 3D dinosaur growth adventure made with Godot 4.

## Core game loop

Choose a Young T. rex, Velociraptor, or Triceratops and complete a species Adventure in the shared valley. Eat suitable food, manage health, hunger, and energy, unlock abilities, grow through four stages, and complete a unique finale. Finishing Adventure unlocks Endless Survival for that dinosaur.

Progression rewards, badges, ability unlocks, Endless access, settings, and records are stored in `user://savegame.json`. Run-specific growth and position reset between sessions.

## Controls

| Key | Action |
| --- | --- |
| WASD | Move |
| Shift | Sprint |
| Left Mouse Button | Eat a nearby dinosaur |
| Right Mouse Button | Power Bite (longer range; 5-second cooldown) |
| Q | Activate Scent Trail after reaching Juvenile |
| Space | Dash as the Velociraptor |
| Right Mouse Button | Horn Push as Triceratops |
| R | Species special ability |
| Escape | Pause, restart, or return to selection |

Keyboard, mouse, and gamepad are supported. Controls can be remapped from the selection screen.

## Run it

Open `project.godot` in Godot 4 and press **F6** or **F5**. All visuals are procedural, child-friendly placeholder shapes—no external 3D assets are required yet.

## Validate

Run the project headlessly to verify startup, then run `res://tests/run_tests.gd` with Godot's `--script` option for profile, growth, quest, survival, AI, food, and save coverage.

For the complete roadmap gate, run `.\tools\roadmap_validation.ps1`. It runs gameplay tests, headless startup, and `git diff --check` in sequence; it does not stage, commit, or push changes.

## Next milestones

1. Playtest and tune each Adventure toward the target 25–35 minute session.
2. Replace procedural placeholders with child-friendly low-poly models and animations.
