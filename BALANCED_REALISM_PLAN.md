# Balanced Realism Visual Upgrade

## Accepted target

Match the reference's muted, natural dinosaur-survival atmosphere with original anatomy, skeletal animation, layered vegetation, continuous terrain, overcast lighting and atmospheric depth. Target approximately 60 FPS at 1280×720 on the development Windows machine. Forward+ is the intended primary renderer; Compatibility remains a reduced fallback. Do not claim performance from headless or fixed-FPS tests.

Existing Adventure, Endless, six-species progression, saves and procedural asset fallbacks must remain compatible. Existing modified dinosaur GLBs and local asset packs must be preserved. Verify asset licenses before redistribution. Multiplayer, swimming, flying, extreme gore and photorealism remain excluded.

## Delivery and evidence

| Step | Deliverable | Status / required evidence |
| --- | --- | --- |
| 1 | Repair invalid 3D hit feedback and imported animation paths | Implemented. Restore original material color after impacts; generated tracks resolve relative to the actor. |
| 2 | Active Adventure movement/combat smoke test | Implemented in `tests/active_run_smoke.gd`, integrated into validation. T. rex moved 12 m over 120 physics frames; session and HUD updated; predator impacts and fallback color recovery ran. Rendered Compatibility run passed on Radeon RX 6750 XT, exit 0. Generated animation track targets resolve for all three actor types. |
| 3 | One seamless heightfield biome | Implemented in Nest Basin. Indexed 65×65 visual grid, 33×33 collision samples, shared world-space sampler, six-metre border transition, grounded dressing/quest props, and offline-baked navigation. Old overlapping hero/procedural surfaces and the nest box mound no longer instantiate. |
| 4 | Verify terrain seams, camera, collision and navigation | Automated pilot checks and rendered Adventure smoke pass completed. Maximum grade 29.45°, collision query error 0.000046 m, paths to 13 clearings, three species walking as Hatchling/Adult across both connected borders. Camera obstruction/recovery tested. Controller handling and visual approval remain as manual release checks. |
| 5 | Convert all remaining chunks | Implemented for automated coverage. Every biome now uses the shared heightfield mesh, triangle collision and height-aware navigation links. Legacy `Elevation` and `ElevationCollision` box mounds no longer instantiate. Route, clearing and active Adventure smoke tests pass. Manual rendered walkthrough remains before art acceptance. |
| 6 | Consolidate global lighting, atmosphere and weather | In progress. One live WorldEnvironment and player-centred weather emitter, two-second sky/fog blends, renderer-gated SSAO/volumetric fog implemented. Transition/settings tests and actual-frame Compatibility/Forward+ smoke checks pass. Full Adventure visual/performance review, ambience blending and default-renderer promotion remain. |
| 7 | Tiered streaming and telemetry | In progress. Chunk/creature/token reuse, phased decoration, baked terrain/layouts/foliage, unload hysteresis, five simulated habitats, three visual tiers and distant tree impostors implemented. Cold-load budgets, biome-transition art review and sustained acceptance remain. |
| 8 | Detailed T. rex model and production rig | Benchmark implemented. `t_rex_hero.glb` is now Blender-authored from original geometry with an imported rig, six named material slots, 25k-35k imported triangles, and native gameplay clips for Idle, Walk, Run, Attack, Eat, Hit, Defeat, Roar and PowerBite. Final sculpt-quality textures, LOD1/LOD2 and art approval remain. |
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

### Atmosphere foundation — September 6, 2026

Advanced to this milestone at the user's request. `valley_atmosphere.gd` coordinates the existing global environment and sunlight; transitions use the player's actual biome rather than whichever neighboring chunk loaded last. Live chunk weather emitters are replaced by one player-centered emitter. Standalone biome previews retain their local environment/weather. Weather-off, Reduced Motion and quality settings remain effective; save schemas and chunk IDs are unchanged.

`tests/atmosphere_smoke.gd` verifies one live environment, no per-chunk weather, intermediate and final two-second blend values, player-follow positioning, quality toggles, reduced motion and Compatibility effect restrictions. Actual-frame runs passed on OpenGL Compatibility and Vulkan Forward+ on the RX 6750 XT. Headless Adventure movement/combat and the gameplay suite also passed. Early teardown-only GL texture warnings disappeared after the test awaited real render frames and deferred resource destruction correctly.

Compatibility remains the configured default. A renderer smoke pass is not art or performance acceptance; do not promote Forward+ until live Adventure views and performance budgets are reviewed. Remaining: biome ambience/wind transitions, full renderer-specific atmosphere tuning, rendered travel review, and performance validation.

Biome-trigger follow-up: removed entry announcements and ambience switches from neighbor-chunk activation. They now occur when the player's actual biome changes, alongside the global atmosphere controller. Existing ambience uses a one-second fade-out and one-second fade-in; this is a two-second sequential transition, not overlapping audio crossfade. Added a regression proving loading Fernwood while standing in Nest Basin does not announce Fernwood, while entering Fernwood does. Atmosphere smoke and gameplay tests pass.

Wind and renderer review (2026-09-06): sheltered forest and exposed ridge wind now blend over two seconds through shared foliage materials; Reduced Motion stops the wind. The atmosphere regression covers intermediate wind values and accessibility toggles and is now included in `tools/roadmap_validation.ps1`. Rendered jungle smoke passed on both renderers. Reviewed `.validation/jungle_forward_plus_forest.png`, `jungle_gl_compatibility_forest.png`, and `jungle_forward_plus_pond.png`: Forward+ gives softer shadows and more muted foliage; the player, paths and pond remain visible. Prototype landmark silhouettes and HUD overlap remain visible defects, not accepted final art. Audio audition, renderer-specific sustained performance and final visual tuning remain open. Compatibility stays the default; no renderer promotion or 60 FPS acceptance is claimed.

Initial recovery corrected the Blender-to-Godot axis error in `tools/create_hero_valley.py` and regenerated `assets/environment/hero_valley.glb` (previous vertex-height error 0.00034 m). The heightfield pilot now supersedes that 31×31 mesh: the original GLB and authoring tool remain preserved on disk, but are not loaded as an overlapping terrain layer. Do not re-enable that import until it is reauthored against the shared sampler.

### Forward+ sustained performance gate — 2026-09-06

**FAIL** at Medium, 1280x720, Radeon RX 6750 XT. After 30 seconds warm-up, the unfixed-time live traversal measured 300.047 seconds and reached 28 waypoints: 41.50 average FPS, p95 158.554 ms, p99 260.610 ms, maximum 413.107 ms, and 1,893 frames over 33.33 ms. Route/functionality checks passed, but do not imply performance acceptance. Only 129 measured slow frames had a chunk activation in the preceding second; the remaining stalls require separate CPU/GPU investigation, not an assumption that chunk loading explains them.

Evidence: `.validation/jungle_forward_plus_performance.json` and `.validation/forward_performance.log`. The harness now preserves renderer-specific reports and prints compact summaries instead of thousands of spike records. Next: isolate atmosphere/shadow/foliage costs with controlled diagnostics, then repeat the full traversal after a verified fix. Compatibility stays the default; do not promote Forward+ or mark step 6 accepted yet.

### Rendering isolation and shadow budget — 2026-09-06

Added `tests/jungle_smoke.gd -- --render-diagnostic`: four stationary phases (baseline, no SSAO, no shadows, repeated baseline), each with five seconds settling and fifteen seconds measurement. The test uses a camera-local environment override and restores shadows/environment afterwards; it is diagnostic only, not traversal acceptance. Reports include average FPS, p95, sampled process/physics monitors and draw calls. Monitor samples are engine-reported aggregates, not per-frame CPU attribution.

Original Medium 90 m shadows: baseline 45.29 FPS, repeated baseline 47.21, no SSAO 49.11, no shadows 68.25. Changed Low/Medium/High shadow distance to the planned 20/45/70 m while retaining shadows, foliage density, collision and wildlife. At Medium 45 m, baseline 47.57 FPS and repeat 49.79; sampled draw calls fell from 746/656 to 531/487. P95 remains approximately 61 ms, so this is a modest measured improvement, not the root-cause fix. Evidence logs: `.validation/render_isolation.log`, `.validation/render_shadow_budget.log`. Rendered jungle checks and headless atmosphere quality-cycle regression pass. Next diagnostic must investigate remaining stalls; do not claim 60 FPS or promote Forward+.

### Remaining rendering-cost isolation — 2026-09-06

Extended the stationary harness with `--atmosphere-diagnostic`, `--processing-diagnostic`, and `--foliage-diagnostic` (each also requires `--render-diagnostic`). Diagnostics restore gameplay processing, camera environment, 3D rendering and dressing visibility. A completion assertion prevents an aborted diagnostic from reporting success. Fixed stale dressing references after chunk unload by querying live nodes for each phase.

- Freezing atmosphere: 49.89 FPS versus 57.38/52.26 baseline/repeat, p95 still about 61 ms. No evidence supports removing or throttling atmosphere updates as the fix.
- Freezing gameplay: 53.96 FPS versus 48.00/49.31 baseline/repeat, p95 59.77 ms. Disabling 3D while gameplay continues: 278.53 FPS, p95 7.84 ms. The rendered scene is the dominant remaining cost in this diagnostic, not physics alone.
- Hiding dressing: 105.95 FPS versus 48.21/60.68 baseline/repeat, but p95 remains 55.15 ms. Vegetation contributes substantially; it does not explain every stall. Logs: `.validation/atmosphere_isolation.log`, `processing_isolation.log`, `foliage_isolation.log`.

The existing vegetation batches already have individual 12 m cell origins and local instance transforms; do not invent a missing spatial-batching fix. Next: measure foliage geometry/material cost and the remaining non-foliage render stalls, then implement verified LOD/culling improvements without removing nearby habitat density. All results here are short diagnostic samples, not sustained acceptance or matched deterministic wildlife captures.

### Preserve imported vegetation LODs — 2026-09-06

Fixed a concrete pipeline defect in `jungle_dressing.gd`: rebuilding normalized surfaces copied full-resolution arrays but discarded importer-generated LODs. The rebuild now retains each simplified index buffer and scales its error distance with the mesh normalization. Nearby geometry, placement, density, materials and trunk collision remain unchanged. `tests/vegetation_lod_smoke.gd` verifies seven CommonTree levels survive, full-detail indices remain intact, normalized height is one metre, missing-asset fallback works, and both 16/32-bit server index buffers decode correctly with scaled thresholds. The standard roadmap gate includes this regression.

Rendered Forward+ jungle smoke passed and the forest capture was reviewed: nearby ferns, grass and canopy remain visible. The short stationary baseline/repeat measured 232.23/300.66 FPS, p95 8.312/4.723 ms (`.validation/foliage_lod_result.log`), substantially better than earlier runs. These sequential diagnostics are not a controlled GPU attribution study or five-minute acceptance. Next: repeat sustained traversal with preserved LODs; keep Compatibility default until that gate and broader visual review pass.

### Sustained Forward+ retest after LOD preservation — 2026-09-06

The starting-region Medium throughput target passes on Radeon RX 6750 XT at 1280x720: 30 seconds warm-up followed by 300.003 real-time seconds, 67,552 frames, **225.17 average FPS**, p95 **6.828 ms**, p99 **17.281 ms**, and **33 waypoints**. Live wildlife remained enabled; plant density and collision were unchanged. Rendered jungle smoke passed without script or animation-track errors. Evidence: `.validation/lod_forward_traversal.log` and `.validation/jungle_forward_plus_performance.json`.

Smoothness is not fully accepted: 24 measured frames exceeded 33.33 ms, maximum 330.989 ms. Every one had a chunk activation in the preceding second, unlike the earlier broad stalls. Largest spikes recur near the same border at X approximately 29 m. Next: address synchronous chunk activation/build work through the planned streaming milestone, preserving ground collision before the player reaches the border. This measured correlation does not prove all activation sub-costs; retain per-build telemetry. The sandbox also prevented user-log/shader-cache creation and certificate access; a normal-permission packaged run remains necessary for release acceptance.

This supersedes the earlier failed sustained result for current starting-region throughput, not for the entire reserve, all quality presets or packaged performance. Compatibility remains default pending broader renderer visual/quality review. Audio audition and prototype visual cleanup remain open.

### Bounded chunk reuse — 2026-09-06

`world_stream_manager.gd` now retains up to eight recently unloaded constructed chunks. Cached chunks are detached from the scene tree (no active physics/navigation/rendering/process work); reentry restores the same instance and latest chunk state instead of rebuilding terrain and dressing. World-owned `cached_chunk_owner.gd` holders prevent orphaned detached scenes during teardown, and oldest cached entries are freed on eviction. Quality/weather changes invalidate inactive entries so old settings cannot return. This does not change the active radius, save schema, wildlife budget or first-time loading yet.

`tests/chunk_cache_smoke.gd` verifies identity reuse, run-state restoration, bounded eviction, world teardown/reset, and physical ground rays before unloading, while detached, and after reuse. The standard roadmap gate includes it. Gameplay suite and targeted cache tests pass. Rendered Forward+ 90-second diagnostic (30 warm-up + 60.014 measured) completed nine waypoints at 226.80 average FPS, p95 6.978 ms, maximum 27.724 ms, **zero measured frames above 33.33 ms**, without script/navigation errors. Evidence: `.validation/cache_traversal_diagnostic.log`. This is short warm-reentry evidence, not a five-minute or cold-loading acceptance result.

Next: stagger first-time construction and implement the full current/adjacent/distant tiers, bounded simulation, and hysteresis; then repeat sustained traversal and camera/navigation checks. Step 6 visual/audio acceptance and renderer promotion remain open, as does complete step 7 acceptance.

### Five-habitat creature simulation budget — 2026-09-06

Separated loaded scenery from simulation membership. `world_stream_manager.gd` computes the current habitat plus its four cardinal neighbors (maximum five); diagonal terrain remains loaded and navigable. Spawn plans and the jungle predator replenisher now use simulation membership. Existing prey/predators outside those five habitats suspend processing while retaining health/state; reentry restores their prior process mode. Runtime telemetry now reports simulated and cached chunk counts independently from loaded chunks. The existing global 25-creature cap and save schema are unchanged.

`tests/stream_simulation_smoke.gd` validates membership at every reserve chunk, spawn eligibility, diagonal scenery retention, actual prey suspension, health preservation, resumption and reset. Added it to standard validation. Targeted test and gameplay suite pass; rendered Adventure moved 10.84 m and passed combat/visibility checks without script errors (`.validation/simulation_adventure.log`). Platform log/cache/certificate permission diagnostics remain. This completes the simulation-count subtask, not distant visual tiers, actor pooling, cold-load scheduling or final streaming acceptance.

### Border unload hysteresis — 2026-09-06

Gameplay now uses `update_player_position()` to retain previously active terrain for an additional six metres beyond the ordinary neighborhood boundary. New destination chunks still activate immediately; only unloading is delayed. Grid-only callers retain their original deterministic behavior. Simulation membership continues to use the actual current grid and remains capped at five, including during the overlap. This reduces border reversal churn without delaying required ground collision or changing saves.

Extended `tests/stream_simulation_smoke.gd` with repeated boundary oscillation, buffer exit and teleport destination checks. Full roadmap validation passes, including physical terrain routes, cache lifecycle, vegetation LODs, Adventure and atmosphere. Evidence: `.validation/hysteresis_roadmap.log`. Loaded scene count may temporarily exceed the base neighborhood while retained chunks overlap; simulation does not. Cold construction scheduling, distant visual tiers and a fresh sustained rendered streaming run remain open.

### First-load decoration staging — 2026-09-06

During live streaming, `world_chunk_visual.gd` builds terrain/collision, trunk colliders, navigation and landmarks immediately, then queues decorative vegetation, imported dressing, water and particles. `world_stream_manager.gd` executes one decorative phase globally per frame and records phase timings; initial setup and standalone callers remain synchronous. Partial queues survive cache detach/reentry and do not execute while inactive. Final profile application preserves legacy density/material settings. Quality changes tolerate the expected not-yet-created dressing node. No required ground collision is deferred.

`tests/chunk_staging_smoke.gd` checks actual ground support before decoration, single-phase advancement, detached-queue inactivity, resumed completion, absence of duplicate trunk collision and final profile density. It is included in standard validation. Targeted and rendered jungle smoke pass (`.validation/staging_rendered.log`). Pending phase count is exposed in runtime metrics. This is phase-level scheduling, not a guaranteed millisecond budget: a jungle dressing phase or terrain build can still be expensive. Next measure cold activation/phase costs, subdivide expensive phases if necessary, and complete visual tiers; do not claim first-load smoothness accepted yet.

### Subdivide cold jungle dressing — 2026-09-06

Added named phase timing to construction telemetry and `--timings` to the staging test. A cold headless CPU sample measured Fernwood core construction at 278 ms, Cloudforest core at 232 ms, and the original all-at-once jungle dressing phase at 168 ms. These are construction-call timings, not rendered frame measurements.

Split jungle dressing into seven scheduled vegetation-type phases sharing the same root, meshes, deterministic placements and immediate trunk collision. The corresponding cold sample's longest decoration call fell to 52.2 ms (other jungle calls approximately 3.6–38 ms), rather than one 168 ms call. The staging regression verifies the first phase creates trees only and eventual completion preserves profile settings. Terrain/core construction and the largest individual dressing phases still exceed a frame budget; first-load smoothness remains unaccepted. Next: profile/precompute core terrain work and subdivide remaining expensive batches, then measure rendered cold traversal. No nearby vegetation was removed.

Validation caveat for the subdivision change: one full-gate attempt printed `Active run smoke: PASS` but its Godot process stalled at shutdown and required targeted termination. The direct Adventure retry exited normally with PASS and the known single ObjectDB shutdown warning (`.validation/subdivided_active_retry.log`). Do not describe the stalled invocation itself as a successful full validation.

### Terrain normal sampling cost — 2026-09-06

Core telemetry now separates ground and navigation construction. Cold CPU samples showed ground at 217.5/227.7 ms for Fernwood/Cloudforest versus navigation around 11 ms. `valley_terrain.gd` now derives normals from the same interpolated heightfield used by terrain/collision, avoiding additional off-lattice authoring-filter evaluations. Ground construction subsequently measured about 117 ms in those fixtures. This is a construction-call improvement, not a rendered cold-load acceptance result.

Added a regression requiring normal sampling to remain on the collision lattice. Terrain physics routes, baked navigation fingerprints and rendered jungle smoke pass; the forest capture was reviewed. An experimental position-only collider path was discarded because it bypassed ArrayMesh quantization and changed collision fingerprints. Existing collision generation and authored navigation resources remain unchanged. Next: precompute or schedule the remaining core terrain work; the approximately 117 ms cold call still exceeds the frame budget.

### Offline terrain mesh and sample bake — 2026-09-06

Added reproducible `tools/bake_terrain.gd` and 32 generated resources under `assets/environment/terrain/` (about 4.7 MB). They preserve every visual/collision array and exact authoring height samples for all sixteen chunks. Runtime loads validated bakes instead of regenerating terrain; missing/stale bakes retain procedural fallback. Source fingerprints invalidate changed authoring scripts in development; compiled exports rely on version checks plus mandatory prepackaging parity validation. See the asset-folder README for regeneration and limitations.

`tests/terrain_bake_smoke.gd` compares all 32 meshes/faces and saved samples exactly against procedural generation, confirms baked-path use and exercises stale version/source and missing-resource fallback. It is included in the standard roadmap gate, which passes. Cold CPU ground loading measured 9.5 ms in Fernwood and 8.4 ms in Cloudforest, compared with approximately 117 ms before baking. Cloudforest core measured 16.3 ms; Fernwood core still measured 87.4 ms because non-ground setup remains. Evidence: `.validation/baked_construction_timings.log` and `.validation/baked_terrain_roadmap.log`. These CPU timings do not establish rendered cold-load acceptance. Next: address remaining jungle layout/asset preparation costs and complete visual tiers, then measure cold traversal.

### Three visual streaming tiers — 2026-09-06

Current habitats retain full detail. Adjacent habitats retain terrain/collision/landmarks and canopy, with small vegetation reduced to 55% of the selected quality's count. Entering restores full density. Outer-ring distant scenes use the baked 33x33 surface and shadow-free, LOD-biased tree silhouettes; they have no colliders, navigation, weather or wildlife. Only one distant scene is created per update, and full activation removes its distant counterpart. Their tree representations are mesh LODs, not final billboard impostors. Non-jungle distant forest layouts remain provisional art.

Added `distant_chunk_visual.gd`, reversible visual-tier application, and separate full/adjacent/distant telemetry. `tests/visual_tiers_smoke.gd` verifies reduced/restored detail, unchanged trunks, bounded creation, absent distant physics/navigation, promotion replacement and out-of-range release. It is included in the roadmap gate. Gameplay suite and rendered jungle smoke pass; `.validation/jungle_overlook.png` was reviewed with nearby canopy/ground cover intact. Evidence: `.validation/visual_tiers_rendered.log`. Sustained performance, edge-transition art review and final distant impostors remain; do not infer final streaming acceptance from these checks.

### Habitat creature pooling — 2026-09-06

Inactive prey and predators now enter a bounded 25-actor detached pool. Habitat reentry restores the same actor, health and signal connections within the live creature cap. Defeat cooldowns advance while pooled, but respawning and rewards still use the normal active-creature logic. Oldest entries are evicted at capacity; run cleanup frees detached actors. Nearby danger, roar and event selection exclude detached predators. Pool size is exposed in streaming telemetry.

`tests/actor_pool_smoke.gd` checks both actor types, preserved health, expired cooldowns, single defeat rewards, signal identity, restoration limits, eviction and world cleanup. It is integrated into roadmap validation. Rendered Compatibility Adventure moves 10.84 m and passes combat/visibility checks (`.validation/actor_pool_rendered.log`). Sandbox log/cache/certificate diagnostics remain distinct from gameplay failures. This completes creature reuse, not token pooling, final impostors, cold-load budgets or sustained streaming acceptance.

### Offline habitat placement — 2026-09-06

Cold Fernwood profiling separated placement, asset preparation and batching. Grass layout cost 43.204 ms versus 4.595 ms for batching; dry-forest reed rejection cost 29.229 ms even though no reeds were placed. Added 28 original deterministic layout resources (four habitats, seven vegetation kinds), a reproducible bake tool, source/version validation and procedural fallback. Rebuilt terrain fingerprints after the habitat source change. No density, positions, paths or collision exclusions changed.

`tests/habitat_bake_smoke.gd` compares every saved transform exactly against fresh procedural generation and exercises stale-resource regeneration. It is included in the roadmap gate. The same cold CPU diagnostic now measures grass layout loading at 2.008 ms and reeds at 0.841 ms (`.validation/jungle_baked_costs.log`), with batch costs unchanged. `tests/jungle_construction_profile.gd` preserves the diagnostic. First-time tree mesh normalization still costs approximately 34 ms, and these CPU timings do not prove rendered traversal smoothness; continue cold-load optimization and sustained testing.

Full roadmap validation and rendered jungle smoke pass (`.validation/habitat_roadmap.log`, `.validation/habitat_rendered.log`); the forest capture was reviewed with canopy, ground cover and the path intact. Diff whitespace checks pass. This is a verified placement-cost improvement, not final environment art or sustained performance acceptance.

### Prepared foliage meshes — 2026-09-06

Nine normalized foliage resources preserve source geometry, LOD indices/distances, textures and foliage shader parameters. Runtime checks modification-time/size stamps; the full gate checks content hashes including glTF buffers, images and import options. Missing/stale resources use source normalization; missing source models still use procedural fallback. Reproducible export: `tools/bake_foliage_meshes.gd`. Local stamps may need rebaking after checkout; compiled exports require pre-export parity validation.

The first experiment hashed all textures at runtime and regressed tree preparation to 155 ms; that path was replaced, not accepted. The revised cold CPU sample measures tree preparation at 18.164 ms versus 34.352 ms, and deadwood at 6.029 ms versus 12.414 ms. Small asset preparation is not uniformly faster. Evidence: `.validation/foliage_baked_costs.log`. `tests/foliage_bake_smoke.gd` verifies all nine meshes' exact arrays, LODs, texture bytes, material parameters, Reduced Motion and stale/missing fallbacks. Standard roadmap validation passes. Rendered and sustained streaming acceptance remain separate from CPU preparation timing.

The subsequent five-minute Forward+ Medium traversal completed 33 waypoints but regressed to 52.68 FPS, p95 58.359 ms, maximum 84.818 ms and 3,574 frames over 33 ms. Only 253 slow frames were near recent activation, so the new dominant slowdown is not confined to cold construction. Evidence: `.validation/prepared_streaming_performance.log`. This supersedes throughput acceptance for the current worktree; source-versus-prepared foliage isolation is in progress. Do not promote the renderer or call streaming accepted.

Follow-up isolation did not identify a single cause: source-normalized foliage also runs slowly (58.86 FPS baseline, 29.43 repeat); hiding distant scenery barely changes throughput (62.83 to 63.46 FPS). Freezing gameplay improves 88.88 to 99.22 FPS, while disabling 3D reaches 231.91 FPS, but restoring 3D produces a much worse 11.47 FPS repeat. These unstable sequential samples point toward a rendering-side investigation, not proof of an individual feature regression. Logs: `.validation/source_mesh_isolation.log`, `.validation/distant_isolation.log`, `.validation/current_processing_isolation.log`. Diagnostic flags are retained in `tests/jungle_smoke.gd`. Next capture renderer primitive/memory counters and repeat matched render-state samples before adjusting art budgets. No reduced foliage density or renderer promotion has been used to hide the failure.

### GPU contention identified; token pooling — 2026-09-06

Added viewport CPU/GPU timing, primitive count, video memory and window-focus measurements to the render diagnostic using Godot's documented RenderingServer measurement API. Three steady phases show render CPU around 0.8–0.9 ms versus GPU 55–64 ms, approximately 549k–588k primitives and 365 MB reported video memory. Windows GPU Engine counters concurrently show a separate `llama-server` process using approximately 51% of its compute engine, reaching approximately 100% in a subsequent sample. Other desktop GPU activity is also present. This is a verified benchmark confounder, not proof that every earlier slowdown was external. No unrelated process was stopped. User was asked to pause that workload before clean performance acceptance. Evidence: `.validation/render_counter_isolation.log`; counter samples were collected live with PowerShell Get-Counter.

Continued functional streaming work with a 25-entry reward-token pool. Claims, expiry and recovery retire tokens without leaving them targetable or processing; reuse resets lifetime, profile, claim state and placement while retaining the visual. Run cleanup frees the pool. Active and pooled counts are included in diagnostics. `tests/token_pool_smoke.gd` checks identity, single rewards, expiration, bounded retention, teardown and actual Adventure claims for carnivore/herbivore hunger behavior. The standard gameplay suite and targeted test pass; the new test is included in roadmap validation. Existing sandbox diagnostics and the known headless shutdown ObjectDB warning remain separate from gameplay script errors.

Token-pool full roadmap validation passes (`.validation/token_pool_roadmap.log`). Rendered Compatibility Adventure moves 10.84 m and passes visibility/combat checks (`.validation/token_pool_rendered.log`); this is functional evidence, not a GPU throughput claim. Next functional streaming item is final distant impostors while clean performance acceptance awaits an uncontended GPU.

### Distant tree impostors — 2026-09-06

Three licensed CommonTree variants now use transparent 512-pixel mipmapped, fixed-Y billboard cards in distant chunks. Two triangles per tree replace distant full meshes; current/adjacent foliage and trunk collision are untouched. The original deterministic transforms are divided into three variant batches. Missing/stale captures fall back to normalized geometry and its procedural fallback. Regeneration uses the rendered Godot tool `tools/bake_tree_impostors.gd`; source fingerprints and local freshness stamps are checked as for other prepared assets.

`tests/tree_impostor_smoke.gd` verifies source freshness, two-triangle geometry, alpha background/content, mipmaps, scale-preserving billboard setup and stale/missing fallback. Visual-tier tests verify distant use, shadow exclusion, unchanged near collision and promotion replacement. Front/oblique captures and a rendered jungle overlook were reviewed; tree silhouettes remain visible without opaque rectangular borders. Full roadmap and jungle smoke pass (`.validation/impostor_roadmap.log`, `.validation/impostor_jungle.log`). These are single-view, baked-color distant representations, not multi-angle close-up trees; final biome-transition art and performance acceptance remain separate.

### Uncontended starting-region traversal — 2026-09-06

After the previously observed `llama-server` workload disappeared, Windows GPU Engine samples before/during traversal showed no competing compute engine above 5%. Nothing was terminated by this work. Forward+ Medium at 1280x720 on Radeon RX 6750 XT completed 300.005 measured seconds after 30 seconds warm-up: 247.08 FPS average, p95 5.920 ms, p99 7.375 ms, maximum 19.357 ms, zero measured frames over 33 ms, 33 waypoints. Gameplay/jungle checks pass. Evidence: `.validation/impostor_clean_performance.log` and `.validation/jungle_forward_plus_performance.json`. This supersedes the contended throughput failure for the current starting-region sample; it does not prove that contention caused every historical spike.

Two warm-up stalls remain at elapsed 0.08/0.21 seconds (76.57/38.09 ms). First-entry readiness, full-reserve traversal, other quality presets, biome-transition art and packaged Windows acceptance remain. Do not relabel this warmed-up starting-region result as full-release acceptance. Compatibility stays configured until the broader renderer/art gate is satisfied.

### Full-reserve physical traversal — 2026-09-06

Added `tests/reserve_traversal_smoke.gd`: an actual Adventure T. rex walks connected cardinal routes through all 16 habitat centers and back to the nest at Hatchling and Adult sizes. The harness waits for asynchronous navigation initialization, then follows baked paths with normal movement and live streaming/AI. It does not teleport across borders or disable terrain collision. Every route checks continuous grounding (under 0.5 m discrepancy), arrival, five simulated habitats and the 25-creature limit. Both passes succeed; included in standard roadmap validation.

An initial straight-line fixture stopped in vegetation beyond Sunstone. Following the authored navigation path resolved that test assumption without deleting vegetation or weakening collision. Evidence: `.validation/reserve_traversal.log`. This is fixed-time headless functional coverage for T. rex and habitat-center routes, not rendered full-map performance, all quest routes, all species, or art acceptance. The known headless shutdown ObjectDB warning remains. Startup readiness and broader rendered/release gates are still open.

The expanded standard roadmap gate passes (`.validation/reserve_roadmap.log`), including the full-reserve traversal. Next extend rendered habitat review and startup readiness evidence; do not infer those results from this headless pass.

### Seamless Reserve Terrain — 2026-09-05

- `valley_terrain.gd` owns the reserve-wide terrain shape, smoothing, clearings, edge transition, indexed visuals, collision faces and ground queries. The visual grid subdivides the coarse collider's triangles exactly; cached lattice heights avoid repeated authoring calculations during movement. All streamed biomes now sample the same world-space surface so chunk borders match physically and visually.
- `world_chunk_visual.gd` now uses the shared heightfield for every biome. Vegetation, rocks, optional pack props, water and landmarks are grounded. `main.gd` grounds eggs, scent dots, spawns and waterfall motion, and no longer creates duplicate central terrain/collision/navigation.
- Player movement now has an actual capsule, gravity and floor snapping instead of being assigned a sampled Y every render frame. The camera uses a sphere-casting spring arm with immediate obstruction retraction and gradual recovery. This is the collision foundation, not the later cinematic camera/art tuning milestone.
- Navigation is generated per chunk from the same simplified heightfield collision grid and stores a terrain fingerprint so stale navigation can be detected after terrain edits. Inter-chunk navigation links are placed at the shared border and projected to terrain height instead of using flat centre-to-centre shortcuts.
- `tests/terrain_smoke.gd` checks grid counts, clockwise winding, all-cell grades, world-space edge sampling, 900 physical ground rays, representative loaded chunk borders, 28 grounded clearings, and real three-species Hatchling/Adult route traversal without a main-controller grounding override. The T. rex route also crosses multiple converted biomes. `tests/active_run_smoke.gd` checks Adventure, combat, grounded eggs, camera obstruction/recovery and no overlapping hero surface. The gameplay suite now rejects any reintroduced box elevation mound or flat-pad collision.
- Rendered Compatibility smoke passed on Radeon RX 6750 XT: approximately 11.9 m of movement from input, camera recovery and predator impacts, no runtime or animation-track errors. The local `.validation/active_run.png` was inspected; the terrain is visible and correctly oriented. Fixed-FPS tests are correctness evidence, not a measured 60 FPS performance result.

Next: run a rendered walkthrough across Ancient Nest, Overlook, Sunstone, the egg trail, meadow, arena and several converted biome borders. Check controller targeting and camera comfort at Hatchling/Adult sizes. Then proceed to step 6: consolidate global lighting, atmosphere and weather so the reserve stops looking washed out and prototype-bright.

Rendered screenshot `.validation/active_run.png` confirms a functioning HUD and the new starting terrain. It still shows washed-out global lighting, primitive model silhouettes and clipped HUD text; the full reserve terrain now needs a fresh rendered capture and art review. These remain outstanding visual work, not accepted art. Run the smoke script with `-- --capture` on a rendered Godot build to refresh that local screenshot.

### T. rex benchmark model - 2026-09-05

- `tools/create_trex_model.py` now exports an original juvenile T. rex benchmark through Blender. The model includes separated body, accent, eyes, teeth, claws and mouth materials; a simple production-direction rig; subdued natural colors; teeth, claws, dorsal scales, tail and readable skull/body proportions.
- `assets/models/dinosaurs/t_rex_hero.glb` replaces the previous tiny placeholder and remains the first T. rex path loaded by `player.gd`. The older `t_rex.glb` and procedural fallback remain available.
- `player.gd` now prefers complete native imported animation clips before creating wrapper fallback animations. Power Bite can play the imported `PowerBite` clip, while normal combat falls back to `Attack`.
- `tests/run_tests.gd` verifies the hero GLB imports, exposes required material slots, contains all nine gameplay animation names, stays within the 25k-35k imported triangle benchmark range and is used through native imported animations.
- The initial visibility claim was invalidated by subsequent rendered captures: its Y-up authoring coordinates were exported through Blender's Z-up conversion, turning its length vertical. See the repair evidence below.

### T. rex visibility and smooth-surface repair - 2026-09-06

- Rebuilt the benchmark with an explicit Godot-to-Blender coordinate conversion, a smooth continuous torso/neck/skull/tail, rounded anatomical parts, a bound skeleton, and 33,000 triangles. Removed the forced rigid-animation workaround. The older GLB and procedural fallbacks remain.
- Added original 2048px base-color, normal, roughness, and AO textures; six material slots; and editable `art_source/t_rex_hero.blend`. `art_source/.gdignore` prevents duplicate runtime imports. `art_source/README.md` documents reproducible export and rendered validation.
- Native actions deform the visible skin: Idle, Walk, Run, Attack, Eat, Hit, Defeat, Roar, PowerBite, plus Stagger. Added clip blending, locomotion rate adjustment, real Roar/Hit triggers, and a short defeat animation before the existing nest recovery. Run replacement cancels the pending recovery.
- Corrected model placement at non-origin spawns. Juvenile height remains 2.05 m, and existing growth multiplies the complete mesh up to 1.75 at Adult. No gameplay growth thresholds were changed.
- Rendered `tests/trex_model_smoke.gd` samples actual skinned vertices, validates material maps, checks head-to-tail orientation and growth grounding, and exercises both fallback paths. `tests/active_run_smoke.gd` covers live visibility, movement, Power Bite, ability/damage reactions, defeat recovery, and restart during defeat. Review images are `.validation/trex_juvenile.png`, `trex_run.png`, `trex_adult.png`, and `active_run.png`.
- Remaining art gates: user visual approval, terrain-aware foot IK, refined anatomical sculpting/retopology, authored LOD1/LOD2, and sustained performance measurement. Smooth shading and normal maps reduce the faceted appearance; this is not final photorealistic art acceptance.
- Validation result: rendered skin smoke PASS (PBR maps, every required action, growth, both fallback paths); rendered Adventure PASS; full roadmap validation PASS including restart during defeat and terrain route checks. The skin test uses actual deformed vertices, not only imported rest bounds or action names.

`tools/roadmap_validation.ps1` now rejects script/parse errors and unresolved animation tracks even when a test prints PASS. It includes actual frame-driven Adventure movement and combat, using an isolated disposable save. This does not prove final terrain, visual quality, all-species completion or sustained 60 FPS.

Known remaining validation diagnostics: sandbox log/certificate permissions and an ObjectDB leak at shutdown. The former detached-node transform error in the legacy streaming test was corrected by adding the actor before assigning its global transform. Windows export templates remain a packaging prerequisite, to recheck at release acceptance.

Do not mark later steps complete based on small UI edits, checkpoint count, synthetic population simulations or selection-screen startup. Each visual deliverable needs rendered inspection; performance requires real elapsed frame measurements without fixed-FPS simulation.
