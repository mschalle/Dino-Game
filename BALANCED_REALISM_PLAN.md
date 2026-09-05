# Balanced Realism Visual Upgrade

## Accepted target

Match the reference's muted, natural dinosaur-survival atmosphere with original anatomy, skeletal animation, layered vegetation, continuous terrain, overcast lighting and atmospheric depth. Target approximately 60 FPS at 1280×720 on the development Windows machine. Forward+ is the intended primary renderer; Compatibility remains a reduced fallback. Do not claim performance from headless or fixed-FPS tests.

Existing Adventure, Endless, six-species progression, saves and procedural asset fallbacks must remain compatible. Existing modified dinosaur GLBs and local asset packs must be preserved. Verify asset licenses before redistribution. Multiplayer, swimming, flying, extreme gore and photorealism remain excluded.

## Delivery and evidence

| Step | Deliverable | Status / required evidence |
| --- | --- | --- |
| 1 | Repair invalid 3D hit feedback and imported animation paths | Implemented. Restore original material color after impacts; generated tracks resolve relative to the actor. |
| 2 | Active Adventure movement/combat smoke test | Implemented in `tests/active_run_smoke.gd`, integrated into validation. T. rex moved 12 m over 120 physics frames; session and HUD updated; predator impacts and fallback color recovery ran. Rendered Compatibility run passed on Radeon RX 6750 XT, exit 0. Generated animation track targets resolve for all three actor types. |
| 3 | One seamless heightfield biome | Pending. 65×65 visual vertices, 33×33 collision samples, shared world-space height sampling and six-metre border transitions. |
| 4 | Verify terrain seams, camera, collision and navigation | Pending. Rendered route checks and physics/path tests; no required grade above 30 degrees. |
| 5 | Convert all remaining chunks | Pending. Remove box hills/colliders; align spawns, quests, recovery and water to shared terrain. |
| 6 | Consolidate global lighting, atmosphere and weather | Pending. One WorldEnvironment and player-centred weather; two-second biome blends; Forward+ and fallback validated. |
| 7 | Tiered streaming and telemetry | Pending. Current/full, adjacent/reduced and distant/silhouette tiers; at most five fully simulated chunks; hysteresis and reusable pools. |
| 8 | Detailed T. rex model and production rig | Pending. Original sculpt, retopology, baked PBR textures, skeletal actions and three LODs; rendered art review required. |
| 9 | Tune T. rex movement and camera | Pending. Stride matching, foot planting, growth framing, collision-aware camera, archetype-specific tuning. |
| 10 | Upgrade other playable dinosaurs | Pending. Same asset and animation gates as the T. rex benchmark. |
| 11 | Upgrade predators and prey | Pending. Species-specific anatomy, LODs and materials within budgets below. |
| 12 | Complete vegetation, materials, water, scenery and audio | Pending. Reference-style composition, biome identity and ecological dressing reviewed in rendered gameplay. |
| 13 | Balance all quality/renderer presets | Pending. Measured Low/Medium/High plus Compatibility; no visual gaps or inaccessible routes. |
| 14 | Full acceptance | Pending. All Adventures, Endless soak, saves, paths, asset fallbacks and packaged Windows performance test. |
| 15 | Documentation and GitHub delivery | In progress. Commit intended files after each validated delivery; final acceptance requires all preceding gates. |

## Production specifications

- Terrain: broad valleys, forest shelves, rolling meadows, ridges, rocky outcrops and streambeds. Flatten nest, quest and combat clearings. Visual and collision heights must agree; navigation comes from simplified collision. Skirts may conceal cracks only below ground and without collision. Inspect Blender-to-Godot up-axis conversion before accepting imported hero terrain.
- Renderer: filmic/ACES-style tonemapping, cool overcast skylight and soft directional sunlight. Nearby contact detail, SSAO on supported Medium/High configurations, volumetric fog on Forward+ High and depth-fog fallback. World colors use moss/pine green, wet brown, gray stone and blue-gray haze; UI, threats and tokens retain contrast.
- T. rex: LOD0 25–35k triangles, LOD1 12–18k, LOD2 4–7k. Bake 2K base color, normal, roughness and AO with optional dirt/injury masks. Model jaw, mouth, teeth, eyes and claws; rig neck, hips, limbs and tail with deformation review. Higher triangle count alone is not art acceptance.
- NPCs: major predators 15–25k, medium dinosaurs 10–18k and small prey 5–10k LOD0 triangles. Common NPC textures 1K; playable/boss textures 2K. Use large-biped, small-biped and quadruped rig families; wrappers normalize feet, scale, forward axis, collision and materials.
- Animation: real Blender Idle, Walk, Run, Turn Left/Right, Attack, Eat, Hit, Stagger, Defeat, Roar and ability actions. AnimationTree locomotion and one-shots; stride-speed matching, planted feet, breathing, target tracking, tail balance and turning/acceleration lean. Reduced Motion suppresses camera shake and secondary motion.
- Camera: 55–65 degree configurable FOV, lower view with a visible horizon, growth-aware distance and archetype tuning. Collision shortens the arm immediately with smooth recovery; restrained look-ahead respects Reduced Motion.
- Vegetation: ground cover, grass, flowers, ferns, reeds, shrubs, litter, roots, stones, saplings and canopy. MultiMesh repeated small plants; three tree LODs and distant impostors. Only movement-blocking trunks receive simplified collision; navigation corridors stay clear.
- Materials: world-space grass/soil/mud/rock blend using slope, height, biome, moisture and masks. Triplanar cliffs, macro variation, wetness, normal/roughness detail; Low uses two layers. Footprints, roots, fossils, cracked mud and weathered strata add grounded detail.
- Water: terrain-cut streams/pools, shallow beds, shoreline mud, wet stones, reeds, ripples, foam and mist. Reflections depend on renderer and measured budget. Distant ridges/forest silhouettes carry no AI or gameplay collision.
- Streaming: separate simulation and visual activation. Full current chunk plus up to four cardinal neighbours; reduced adjacent dressing and distant silhouettes. Hysteresis avoids border thrashing. Pool reusable creatures, tokens, props and weather resources with reset/state compatibility tests. Track frame time, draw calls, visible instances, particles, bodies, creatures and chunk tiers.

| Quality budget | Low | Medium | High |
| --- | ---: | ---: | ---: |
| Grass instances per visible chunk | 400 | 900 | 1500 |
| Detailed nearby trees | 20 | 40 | 65 |
| Vegetation shadow distance | 20 m | 45 m | 70 m |
| Atmospheric particles | Minimal | Moderate | Full |
| Volumetric fog | Off | Optional | Forward+ on |
| Water reflections | Simplified | Half-resolution if supported | Configured full quality |

## Validation limits and outstanding gates

Initial recovery also corrected `tools/create_hero_valley.py`: the old GLB extended 60 metres on its vertical axis because the generator supplied Y-up vertices to Blender. Export now converts Blender Z-up correctly, uses the existing collision height formula and triangulation, and hides overlapping procedural ground only when the imported terrain loads. Regenerated `assets/environment/hero_valley.glb`; the runtime vertex-height check measured 0.00034 m maximum error. This repairs the vertical terrain sheet, but does not complete seamless terrain steps 3–5. The current 31×31 central mesh will be replaced by their accepted 65×65/33×33 system.

Rendered screenshot `.validation/active_run.png` confirms a functioning HUD and corrected terrain orientation. It still shows box elevation, washed-out colors, atlas striping, primitive model silhouettes and clipped HUD text. These remain outstanding visual work, not accepted art. Run the smoke script with `-- --capture` on a rendered Godot build to refresh that local screenshot.

`tools/roadmap_validation.ps1` now rejects script/parse errors and unresolved animation tracks even when a test prints PASS. It includes actual frame-driven Adventure movement and combat, using an isolated disposable save. This does not prove final terrain, visual quality, all-species completion or sustained 60 FPS.

Known remaining validation diagnostics: sandbox log/certificate permissions and an ObjectDB leak at shutdown. The former detached-node transform error in the legacy streaming test was corrected by adding the actor before assigning its global transform. Windows export templates remain a packaging prerequisite, to recheck at release acceptance.

Do not mark later steps complete based on small UI edits, checkpoint count, synthetic population simulations or selection-screen startup. Each visual deliverable needs rendered inspection; performance requires real elapsed frame measurements without fixed-FPS simulation.
