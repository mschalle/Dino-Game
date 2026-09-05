# Roar & Rise — Project Plan

## Vision

Roar & Rise is a bright, kid-friendly 3D dinosaur adventure game. Players choose a dinosaur, explore one welcoming valley, eat suitable food to grow from Hatchling to Adult, learn species abilities, complete a quest chain, and unlock Endless Survival.

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

## Release Readiness

- Complete all three Adventure routes from a clean save.
- Verify each completed Adventure unlocks only its matching Endless mode.
- Test new, valid, corrupt, and older save files.
- Run extended Endless sessions to confirm food renewal and difficulty scaling.
- Playtest keyboard/mouse and gamepad with large-text settings enabled.
- Confirm no blood, wounds, carcasses, or graphic defeat imagery appears.
- Package and test a Windows build, then publish a tagged release to GitHub.

## Out of Scope for This Release

- Multiplayer or online accounts.
- Additional valleys or species beyond the first three playable dinosaurs.
- Realistic/graphic combat.
- Mobile or console-specific releases.
