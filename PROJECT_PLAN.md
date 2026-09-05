# Roar & Rise — Project Plan

## Vision

Roar & Rise is a bright, kid-friendly 3D dinosaur adventure game. Players choose a dinosaur, explore a connected multi-biome prehistoric reserve, eat suitable food to grow from Hatchling to Adult, learn species abilities, complete a quest chain, and unlock Endless Survival.

The initial release targets Windows PC with keyboard/mouse and gamepad support. It is single-player and avoids graphic violence: dinosaurs bump, flee, recover, and respawn at a safe nest.

## Core Game Loop

1. Select a playable dinosaur and Adventure or unlocked Endless mode.
2. Explore the valley, follow quest markers or Scent Trail, and find suitable food.
3. Restore hunger and earn Growth Points by eating.
4. Grow through Hatchling, Juvenile, Young Adult, and Adult stages.
5. Unlock and use species abilities while completing quests.
6. Finish the Adult finale to complete Adventure and unlock Endless for that species.

## Playable Dinosaurs

| Dinosaur | Role | Diet | Signature abilities |
| --- | --- | --- | --- |
| Young T. rex | Powerful hunter | Prey | Power Bite, Valley Roar |
| Velociraptor | Fast explorer | Prey | Dash, Pack Signal |
| Triceratops | Sturdy guardian | Plants | Horn Push, Shield Stance |

## Adventure Content

Each dinosaur has a stage-aligned main quest chain and an Adult finale.

- T. rex: First Feast → Ancient Nest → Roaring Overlook → Valley Rival
- Velociraptor: Sunstone Sprint → Lost Egg Trail → Pack Signal → Grand Valley Race
- Triceratops: Hidden Meadow → Plant Feast → Clear the Trail → Herd Home

Optional exploration challenges award growth and badges.

## Complete

- Reusable profile, session, growth, quest, food-spawning, AI, HUD, and save systems.
- Four growth stages: Hatchling (0), Juvenile (5), Young Adult (12), Adult (25).
- Hunger, health, safe recovery, stage-floor respawn, and non-graphic defeat effects.
- Renewable food supply with guaranteed tier-1, tier-2, and tier-3 prey.
- Prey flee/recover behavior and predator warning/chase/disengage behavior.
- Adventure quest chains, finales, optional exploration quest, and Endless Survival unlocks.
- Persistent unlocks, badges, ability rewards, records, settings, and last-run summaries.
- High-contrast HUD, pause/restart/selection screens, remappable controls, and gamepad inputs.
- Low-poly dinosaur silhouettes and movement animation for players, prey, and predators.
- Animated trees, waterfall, quest markers, and scent dots.
- Ambient fireflies, layered waterfall shimmer, and pulsing objective landmarks.
- Lightweight procedural sounds for food, abilities, growth, quests, and warnings.
- F1 in-game help guide, F2/F3 effects-volume controls, and saved accessibility settings.
- Persistent color selection with Sunset and Mint unlockable palettes, live selection swatches, and collection totals.
- Automated gameplay-state checks and headless startup validation.

## Current Milestone: Structured Playtest and Balance

Goal: make a first Adventure run understandable, forgiving, and enjoyable for children and families.

- Run a clean-save Adventure with T. rex, Velociraptor, and Triceratops.
- Record the time to each growth stage, number of defeats, food eaten, and quest completion time.
- Confirm each species can find suitable food within the first two minutes.
- Confirm tier-1 food supports Hatchling growth and tier-2/tier-3 food supports later stages.
- Tune one variable at a time: hunger drain, food nutrition, predator awareness, damage, and quest rewards.
- Test every quest marker, Scent Trail route, finale trigger, and optional challenge.
- Play through selection, movement, eating, abilities, pause, restart, and completion using only a gamepad.
- Have at least one child/family-friendly readability review of HUD text, colors, goals, and defeat messaging.

## Detailed Development Steps

### Step 1 — Establish a balance baseline

1. Back up or temporarily move the local save file so testing starts clean.
2. Run the automated Godot test script and record the result.
3. Complete one Adventure run per species without changing settings.
4. Copy each run summary into a small playtest log: stage times, food count, defeats, starvation seconds, and quests.
5. Identify the first point where a player is confused, hungry, lost, or overpowered.

### Step 2 — Tune the survival loop

1. Adjust food positions and spawn quotas before changing player stats.
2. Keep at least five tier-1 prey available in Adventure and enough plant food for Triceratops.
3. Ensure hunger pressure is noticeable but does not require constant eating.
4. Ensure health recovery is understandable after five safe seconds above 50% hunger.
5. Verify defeat returns the player to the nest and resets only progress within the current stage.
6. Repeat the three species runs and compare against the baseline.

### Step 3 — Tune quests and abilities

1. Verify each quest becomes active only at its intended growth stage.
2. Confirm the active marker and Scent Trail always point to the current main objective.
3. Confirm completed quests cannot award Growth Points twice.
4. Check that each ability has a clear locked state, usable state, cooldown, and readable feedback.
5. Make sure every Adult finale is reachable and completes Adventure exactly once.

### Step 4 — Finish collection and accessibility polish

1. Add more original color variants only after the base palette is readable against the valley.
2. Add a collection panel showing species, colors, badges, Adventure records, and Endless bests.
3. Add separate effects and music volume controls when music assets are introduced.
4. Add reduced-motion support for fireflies, markers, and screen transitions.
5. Check large-text, high-contrast, keyboard/mouse, and gamepad play on the target Windows resolution.

### Step 5 — Expand presentation safely

1. Add small animated plant clusters and cloud layers without obscuring quest markers.
2. Add friendly landmark props at each quest destination and verify they do not block movement.
3. Replace procedural tones with original or properly licensed child-friendly audio.
4. Add footstep, eating, ability, reward, and ambient audio mix levels.
5. Capture a short gameplay recording and inspect it for visual clutter, readability, and non-graphic presentation.

### Step 6 — Release validation

1. Run all automated tests and a headless startup check.
2. Test new, valid, corrupt, and older-version save files.
3. Complete all three Adventure routes from a clean save.
4. Verify each Adventure unlocks only its matching Endless mode.
5. Run an extended Endless session to confirm resource renewal and difficulty scaling.
6. Package a Windows build, test it outside the editor, and record the build version.
7. Commit the verified release, tag it, and publish the tagged build to GitHub.

## Next Milestone: Collection and Family Playtest

Goal: make the single valley feel richer without expanding into a second map.

- Add simple animated plant clusters, clouds, and ambient particles.
- Add more friendly landmark props around quest destinations.
- Expand the collection summary into a browsable badges, colors, and records panel.
- Conduct the structured three-species balance playtest described above.
- Add reduced-motion and separate music/effects settings.
- Replace procedural placeholder tones with licensed or original child-friendly audio when assets are available.

## Major Milestone: Immersive Dinosaurs, Combat, and Elevated Valley

### Implemented foundation

- Seven data-driven NPC profiles: Psittacosaurus, Dryosaurus, Parasaurolophus, wild Velociraptor, Dilophosaurus, Carnotaurus, and the Allosaurus rival.
- Tier health, damage, Growth Point rewards, hunger rewards, detection, movement, and respawn values.
- Shared multi-hit combat with brief hit protection; stronger creatures can always be attacked.
- Left-click contextual action for plants, living dinosaurs, and defeated-creature tokens; Power Bite retains longer range and increased damage.
- Non-graphic glowing victory tokens, single-claim rewards, carnivore hunger rewards, and Growth-only rewards for Triceratops.
- Target name, tier, and health display plus combat telemetry in run summaries.
- Handcrafted elevated-valley mesh foundation with a basin, meadow, ridge, overlook, rival rise, and waterfall depression.
- Terrain-ground placement for the player, NPCs, plants, tokens, and quest markers.

### Remaining model-production steps

1. Create three Blender rig archetypes: small biped, large biped, and quadruped.
2. Model the three playable dinosaurs and seven NPC species with `Body`, `Accent`, and `Eyes` materials.
3. Animate Idle, Walk, Run, Attack, Eat, Hit, and Defeat; add player ability animations.
4. Export binary GLB files with applied transforms and feet centered at ground level.
5. Wrap each GLB in a Godot scene with normalized scale, collision, shadows, and procedural fallback.
6. Blend locomotion using AnimationTree and play action animations as one-shots.

### Remaining terrain and AI steps

1. Replace the generated terrain blockout with the final authored terrain mesh and simplified collision. **Current milestone:** the blockout now uses an exact concave collision mesh generated from the visible hills; final authored art remains.
2. Add a NavigationRegion3D configured initially for 0.8-meter radius, 35-degree maximum slope, and 0.5-meter climb. **Foundation complete:** the current blockout now creates a terrain-aligned region with these settings.
3. Convert prey and predators to physics actors using NavigationAgent3D for flee, patrol, chase, and recovery paths. **Foundation complete:** agents are attached to both creature types; direct movement remains the safe fallback until final navigation art is baked.
4. Add habitat spawn zones by tier and prevent respawns near the safe nest or visible player area. **Foundation complete:** tier quotas now spawn in basin, meadow, and ridge bands while avoiding the safe nest; explicit authored habitat volumes remain.
5. Add below-map recovery volumes and validate every quest route without mandatory jumping.
6. Finish biome vegetation, landmarks, fog, clouds, water, lighting, audio, and performance tuning.

The player and spawned food now follow the authored elevation function with gravity-like settling, and the terrain safety body uses the same triangle surface as the visible valley. Final GLB terrain art and editor-baked navigation remain required before shipping.

### Combat acceptance criteria

- Tier health values are 30, 60, 100, and 160; attack damage is 5, 10, 16, and 22.
- Basic player damage is `10 + strength × 5`, with 2.2-meter range and 0.7-second cooldown.
- Power Bite uses 3.2-meter range and a 1.6 damage multiplier.
- Defeated creatures dissolve without graphic imagery, drop one token, and respawn after their tier delay.
- Carnivores receive hunger and Growth Points; Triceratops receives Growth Points only from creature tokens.
- T. rex First Feast uses claimed tier-one prey tokens, and Valley Rival completes by defeating and claiming the Adult Allosaurus token.

### Twenty-checkpoint execution log

1. Added the seven-species NPC catalog.
2. Added tier-based health values.
3. Added tier-based attack values.
4. Added tier-based Growth Point rewards.
5. Added shared invulnerability windows after hits.
6. Added multi-hit attacks against stronger targets.
7. Added contextual plant, creature, and token interaction.
8. Added non-graphic glowing victory tokens.
9. Added one-time token claiming protection.
10. Added carnivore hunger rewards and Triceratops Growth-only rewards.
11. Added floating target name, tier, and health feedback.
12. Added combat telemetry to run summaries.
13. Changed the T. rex finale to require the Allosaurus token.
14. Added terrain elevation landmarks and ground-height queries.
15. Fixed terrain face culling so the hills render from the gameplay camera.
16. Added player ground settling and gravity-like recovery.
17. Added terrain safety collision matching the visible terrain triangles.
18. Added terrain-aligned NavigationRegion3D data and creature agents.
19. Added automatic GLB loading with procedural fallback.
20. Generated the higher-resolution T. rex hero GLB and named Godot animation clips.
21. Added keyed position tracks to imported hero animation clips.
22. Connected imported Idle, Walk, and Run clips to player movement speed.
23. Added navigation-agent direction queries for prey flee/recovery movement.
24. Added navigation-agent direction queries for predator chase/recovery movement.
25. Preserved direct steering as a fallback when navigation data is not synchronized.
26. Added below-map recovery for creatures and removal of lost tokens.
27. Added a non-graphic hit burst for successful creature attacks.
28. Added a reproducible Blender hero-model generation script.
29. Added hero-asset presence and animation/fallback regression coverage.
30. Re-ran automated gameplay tests and headless startup validation.
31. Added terrain-ground placement for newly spawned prey and plants.
32. Added tier-aware habitat bands for renewable prey and plant spawning.
33. Validated the GLB lookup pipeline for player and NPC models with procedural fallback.
34. Added valley fog and reran automated gameplay plus headless startup validation.
35. Added saved UI-scale and high-contrast settings as the first polished-vertical-slice UI foundation.
36. Applied large-text and high-contrast styling consistently across HUD and menu controls.
37. Added viewport-aware HUD layout for variable window sizes and aspect ratios.
38. Anchored the combat target panel responsively beneath the quest area.
39. Added compact-window HUD sizing to prevent status and quest panel overlap.
40. Added visible keyboard/gamepad focus states and larger styled menu controls.
41. Applied matching focus and contrast styling to species selection and mode buttons.
42. Added high-contrast world-space labels to major valley landmarks.
43. Added subtle biome color zones for wetlands, ridge, and rival arena terrain.
44. Added distance-based landmark label visibility to reduce exploration clutter.
45. Added data-driven six-biome world chunk profiles and connectivity validation.
46. Added a radius-based world stream manager with activation/deactivation signals.
47. Added automated checks for nearby chunk activation and distant chunk deactivation.
48. Connected the stream manager to the current world as a no-op-safe reserve foundation.
49. Added explicit scene paths to every biome chunk profile.
50. Added safe missing-scene resolution checks before chunk instantiation.
51. Added six loadable biome scene shells with biome and landmark metadata.
52. Added chunk scene instantiation with duplicate protection.
53. Added chunk release handling and automated load/release validation.
54. Added per-biome ground palette, vegetation density, and fog-direction data.
55. Added validation for biome presentation metadata.
56. Connected chunk activation/deactivation signals to runtime scene instances.
57. Validated chunk runtime loading through automated tests and headless startup.
58. Added persistent in-memory chunk state for unload/reload continuity.
59. Added automated preservation checks for chunk food and quest state.
60. Added per-biome navigation-layer metadata for future actor-size routing.
61. Added per-biome agent radius, slope, and climb constraints with validation.
62. Added serializable snapshot and restore support for streamed chunk state.
63. Integrated chunk-state snapshots into versioned save data with recovery coverage.
64. Wired live world-stream state restore and save into the game session lifecycle.
65. Added bidirectional biome-connection validation for the reserve graph.
66. Added route-finding validation between distant reserve biomes.

## Release Readiness

- Complete all three Adventure routes from a clean save.
- Verify each completed Adventure unlocks only its matching Endless mode.
- Test new, valid, corrupt, and older save files.
- Run extended Endless sessions to confirm food renewal and difficulty scaling.
- Playtest keyboard/mouse and gamepad with large-text settings enabled.
- Confirm no blood, wounds, carcasses, or graphic defeat imagery appears.
- Package and test a Windows build, then publish a tagged release to GitHub.

## Roadmap 2.0 — From Base Game to Polished Release

### Milestone development loop

The roadmap is executed only when manually triggered. Each run selects the earliest incomplete milestone, implements one focused slice, runs the automated Godot tests and headless startup check, updates this plan with evidence, and creates a local commit. The loop does not push to GitHub automatically.

The loop may make routine implementation decisions using the defaults in this document. It pauses for consequential gameplay, scope, art, save-schema, missing-asset, validation, credential, or external-collaboration decisions. A milestone is complete only when its behavior is implemented, existing behavior remains compatible, relevant tests pass, headless startup passes, `git diff --check` passes, and the completion is recorded here.

Validation commands:

```powershell
& "F:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path "." --script res://tests/run_tests.gd
& "F:\GODOT\Godot_v4.7.2-stable_win64.exe" --headless --path "." --quit-after 5
git diff --check
```

After validation, only milestone files are staged and committed locally. GitHub pushes require an explicit request. The loop ends when all milestones are complete and the packaged Windows build, save migration, accessibility, performance, Adventure, and Endless validation gates pass.

### Product target

The first polished release should provide a 30–45 minute Adventure for each playable dinosaur, a replayable Endless mode, six distinct playable species, and one connected 600×600-meter reserve containing six recognizable biomes. The current three-species, 60×60-meter valley remains the vertical slice used to validate systems before expansion.

The larger reserve does not require Godot large-world coordinates. Godot documents ordinary single-precision coordinates as suitable for third-person worlds extending several thousand units from the origin; keeping this reserve centered near the origin avoids unnecessary engine and asset-pipeline complexity.

### Target playable roster

| Species | Diet | Play style | Signature mechanics | Production priority |
| --- | --- | --- | --- | --- |
| T. rex | Carnivore | Powerful hunter | Power Bite, Valley Roar | Existing; polish first |
| Velociraptor | Carnivore | Fast explorer | Dash, Pack Signal | Existing; polish first |
| Triceratops | Herbivore | Defensive guardian | Horn Push, Shield Stance | Existing; polish first |
| Ankylosaurus | Herbivore | Armored defender | Tail Swing, Brace | Expansion wave 1 |
| Parasaurolophus | Herbivore | Social navigator | Herd Call, Endurance Run | Expansion wave 1 |
| Carnotaurus | Carnivore | Burst chaser | Charge, Intimidate | Expansion wave 1 |

Flying, swimming, and very small burrowing species are deferred because each requires a separate locomotion, camera, navigation, quest, and level-design layer. New ground dinosaurs must use the shared profile, abilities, animation, combat, quest, save, and selection systems without adding species conditionals to `main.gd`.

### World structure and biome plan

Build the reserve as a 4×4 grid of approximately 150-meter authored chunks. Keep a 3×3 neighborhood around the player loaded; distant chunks retain lightweight simulation data rather than full scenes. Every chunk owns its terrain, collision, navigation region, spawn volumes, landmarks, ambient audio, and decorative instances.

| Biome | Gameplay purpose | Terrain language | Typical inhabitants |
| --- | --- | --- | --- |
| Nest Basin | Safe onboarding hub | Gentle grass slopes, broad sightlines | Tier-1 prey, plants |
| Fernwood | Close-range exploration | Forest paths, logs, shallow gullies | Raptors, Dryosaurus |
| River Wetlands | Food-rich risk/reward zone | Riverbanks, islands, mud flats | Parasaurolophus, herd prey |
| Sunstone Ridge | Traversal and races | Switchback ramps, arches, overlooks | Fast prey, Carnotaurus |
| Redstone Badlands | Higher-tier combat | Dry terraces, rock pillars, sparse cover | Dilophosaurus, Allosaurus |
| Ancient Meadow | Herd and guardian quests | Rolling hills, flowers, nesting grounds | Triceratops, Ankylosaurus |

Required routes stay under a 30-degree slope and require no precision jumping. Rivers are shallow traversal features until swimming is deliberately implemented. Each biome needs one skyline landmark, one safe resting point, one repeatable activity, at least two food habitats, and multiple routes into neighboring biomes.

### Large-map technical architecture

1. Create a `WorldChunkProfile` resource containing chunk ID, scene path, grid position, biome, neighbor IDs, navigation region IDs, spawn tables, and landmark metadata.
2. Create a `WorldStreamManager` that loads the player chunk plus adjacent chunks and unloads distant chunks after actors and quest state are serialized.
3. Use background resource loading for chunk scenes and prewarm shaders/materials before revealing a newly loaded chunk.
4. Partition navigation into one baked `NavigationRegion3D` per chunk. Align shared border vertices exactly so Godot can join neighboring regions, and use navigation links only for deliberate transitions such as bridges or ramps.
5. Use navigation layers for small, medium, and large dinosaurs where their traversable spaces differ. Limit large-map path queries to relevant nearby regions when profiling shows navigation cost is material.
6. Replace per-object grass, flowers, pebbles, and fern nodes with biome-level `MultiMeshInstance3D` batches. Keep collision only on gameplay-relevant trunks, rocks, and landmarks.
7. Enable automatic mesh LOD for imported scenery and dinosaurs, then add visibility ranges for distant clusters and landmarks. Use occlusion culling only where ridges, cliffs, or dense forest blocks provide meaningful occlusion.
8. Pool prey, predators, tokens, hit effects, and ambient effects to reduce allocation spikes during chunk transitions.
9. Cap detailed simulation to approximately 25 nearby roaming creatures. Distant populations update as low-frequency records and instantiate when their chunk becomes active.
10. Add a loading-boundary fallback: if a destination chunk is not ready, keep the player inside the current safe path and show a brief friendly “Discovering the trail…” indicator.

### Data-driven species expansion

Expand `DinosaurProfile` and `CreatureProfile` rather than adding new species branches:

- Model wrapper and animation-set resources.
- Locomotion archetype and turning radius.
- Stage-specific scale, health, damage, speed, and camera offset.
- Diet tags and food reward rules.
- Ability loadout with reusable effects and targeting rules.
- Habitat affinities and AI relationship tags.
- Quest-chain resource and finale definition.
- Selection-screen statistics, difficulty rating, description, and preview pose.
- Cosmetic material palettes and unlock requirements.

Create reusable ability effects for dash, cone knockback, radial roar, temporary defense, charge, stamina recovery, and ally/herd signal. A new ground dinosaur is accepted only when it can be added through resources and composition without editing the central session loop.

### Animation and model quality pass

1. Replace root-transform placeholder animations with rigged clips for Idle, Walk, Run, Attack, Eat, Hit, Defeat, and each species ability.
2. Standardize three skeleton archetypes: small biped, large biped, and quadruped. Share clips only where proportions remain believable.
3. Wrap every GLB in a Godot scene that controls scale, ground offset, capsule collision, shadow settings, materials, animation tree, and attachment points.
4. Use `AnimationTree` locomotion blending and action one-shots so attacks and hit reactions do not permanently interrupt movement.
5. Add foot-contact events, attack-impact events, and reward events to synchronize sound and effects.
6. Validate silhouettes at normal gameplay distance, not only in Blender close-ups.

### Gameplay UI redesign

#### Shared theme

- Build one project-wide Godot `Theme` for fonts, panels, buttons, focus indicators, outlines, spacing, and species accent colors.
- Use anchors and containers at 16:9, 16:10, ultrawide, and 1280×720 minimum resolution.
- Provide UI scales of 100%, 125%, 150%, and 175% using the root content scale factor.
- Target at least 4.5:1 contrast for important standard text, 3:1 for large text, and a configurable high-contrast mode targeting 7:1.
- Use color plus shape/icon/text; never make color the only way to communicate health, danger, diet suitability, quest status, or rarity.

#### Gameplay HUD

- Top-left: compact health, hunger, energy, growth stage, and Growth Points.
- Top-center: contextual compass with quest, nest, food, and danger pips; avoid a full minimap until the larger reserve has been playtested.
- Top-right: one active objective with progress and a short optional hint.
- Bottom-center: contextual interaction prompt and temporary reward/combat messages.
- Bottom-right: ability icons, controller/keyboard binding, cooldown fill, and locked-stage requirement.
- Near target: name, tier, health, diet suitability, and danger indicator only while noticed or engaged.
- Collapse nonessential HUD elements during exploration and restore them when state changes.

#### Menus and onboarding

- Replace text-only selection with rotating dinosaur previews, readable stat bars, diet, role, abilities, difficulty, Adventure completion, and Endless records.
- Add a first-run tutorial that advances when the player moves, eats, attacks, scents, uses an ability, and completes a quest action.
- Add a field guide containing discovered species, habitats, diets, abilities, badges, cosmetics, and records.
- Ensure every menu can be completed with keyboard, mouse, or gamepad and always shows a strong focus state.
- Keep instructional text short, concrete, and appropriate for younger readers.

### Graphics and environment art pass

1. Write a one-page art bible defining shape language, polygon budgets, palette, material roughness, lighting, fog, particle density, and forbidden graphic imagery.
2. Produce terrain materials for grass, forest soil, mud, stone, red rock, sand, and shallow water with restrained texture detail and clear walkable-path contrast.
3. Create modular biome kits: trees, ferns, flowers, grasses, rocks, logs, nests, bones-as-fossils, arches, and water-edge props.
4. Use warm/cool color shifts and landmark silhouettes to differentiate biomes while keeping the game bright.
5. Add a time-of-day presentation cycle only after the daytime readability target is met; gameplay visibility must remain stable.
6. Add distance fog, cloud layers, wind animation, water movement, ambient insects, leaf particles, and biome audio with reduced-motion/effects alternatives.
7. Give quest objectives a world-space visual language that remains readable without overpowering the environment.
8. Create low, medium, and high graphics presets controlling shadows, vegetation density, particles, render scale, and view distance.

### Content structure for the larger reserve

Each species Adventure contains:

- One short onboarding quest at Hatchling.
- One food/survival quest at Juvenile.
- One traversal or ability quest at Young Adult.
- One story encounter or rescue quest before Adult.
- One non-graphic Adult finale.
- Two optional exploration challenges.
- One species-specific cosmetic reward and one badge.

Add reusable quest templates for reach, follow trail, collect, eat, defeat-and-claim, escort, race, defend, signal, and discover. Every quest must define a recovery path for lost targets, failed escorts, unloaded chunks, or player defeat.

### Production milestones and gates

#### Milestone A — Polished vertical slice

- Finish the shared UI theme, HUD hierarchy, onboarding, target feedback, and selection screen.
- Replace placeholder root animations for the T. rex with a proper rig and animation tree.
- Art-pass Nest Basin and one adjacent biome.
- Complete and playtest the T. rex Adventure at target quality.

Gate: a new player can finish the T. rex Adventure without developer guidance; HUD remains readable across both biomes; the packaged build maintains 60 FPS on the target Windows test machine.

#### Milestone B — Scalable world foundation

- Implement chunk profiles, streaming, navigation-region borders, actor persistence, and loading feedback.
- Expand from 60×60 meters to a four-chunk 300×300-meter prototype.
- Convert vegetation to MultiMesh batches and establish LOD/visibility settings.

Gate: cross all chunk borders repeatedly without visible holes, navigation loss, duplicate actors, quest loss, or frame-time spikes above the agreed budget.

#### Milestone C — Existing roster polish

- Finish production models and animations for Velociraptor and Triceratops.
- Complete their Adventures, finales, tutorials, cosmetics, and Endless unlocks.
- Complete the first four final-quality biomes.

Gate: all three Adventures pass clean-save, defeat-recovery, gamepad, and accessibility playtests.

#### Milestone D — Expanded roster and full reserve

- Add Ankylosaurus, Parasaurolophus, and Carnotaurus using data-driven resources.
- Complete all 16 world chunks and six biomes.
- Add field-guide discovery, expanded quest templates, and biome population simulation.

Gate: all six species can complete Adventure; no species-specific central-loop conditionals are required; the reserve supports a 60-minute Endless session without resource exhaustion.

#### Milestone E — Release candidate

- Finalize audio, graphics presets, controller remapping, UI scale, contrast, reduced motion, save migration, credits, and build metadata.
- Profile CPU, GPU, memory, navigation, draw calls, and shader stutter on at least two Windows hardware tiers.
- Run family readability sessions and fix the highest-frequency confusion points.

Gate: zero critical/high defects, saves migrate safely, all required text meets the chosen accessibility targets, and packaged builds pass three complete Adventures plus a two-hour Endless soak test.

### Quality metrics

- First suitable food discovered within 90 seconds for at least 90% of new-player sessions.
- First main objective understood without opening Help by at least 80% of family playtest participants.
- No more than five persistent HUD groups visible during ordinary exploration.
- Stable 60 FPS at 1280×720 on the baseline machine, with a 30 FPS low-preset floor on the minimum machine.
- No more than 25 fully simulated roaming creatures and no unbounded token/effect growth.
- Chunk transition completes without blocking gameplay under the target storage conditions.
- All Adventures completable using keyboard/mouse or gamepad alone.
- No blood, wounds, carcasses, dismemberment, or realistic distress audio.

### Research references

- [Godot 4.7 large-world coordinates](https://docs.godotengine.org/en/4.7/tutorials/physics/large_world_coordinates.html)
- [Godot 4.7 navigation maps](https://docs.godotengine.org/en/4.7/tutorials/navigation/navigation_using_navigationmaps.html)
- [Godot 4.7 navigation path-query region filtering](https://docs.godotengine.org/en/4.7/tutorials/navigation/navigation_using_navigationpathqueryobjects.html)
- [Godot 4.7 connecting navigation meshes](https://docs.godotengine.org/en/4.7/tutorials/navigation/navigation_connecting_navmesh.html)
- [Godot 4.7 AnimationTree](https://docs.godotengine.org/en/4.7/tutorials/animation/animation_tree.html)
- [Godot performance guidance](https://docs.godotengine.org/en/4.7/tutorials/performance/index.html)
- [Godot 3D importing](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/index.html)
- [Godot UI anchors](https://docs.godotengine.org/en/4.7/tutorials/ui/size_and_anchors.html)
- [Microsoft Xbox Accessibility Guideline: text display](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101)
- [Microsoft Xbox Accessibility Guideline: contrast](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102)

## Out of Scope for This Release

- Multiplayer or online accounts.
- Procedural worlds or a second disconnected reserve map.
- Flying, swimming, or burrowing playable species.
- Realistic/graphic combat.
- Mobile or console-specific releases.
