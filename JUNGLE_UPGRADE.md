# Prehistoric Jungle — starting-region delivery

Scope: Nest Basin, Fernwood, River Wetlands and Sunstone Ridge only. Compatibility renderer, existing IDs, saves, species and AI remain unchanged.

## Asset intake and layout

- Quaternius Stylized Nature MegaKit FREE: local `License_Standard.txt` explicitly grants CC0 1.0. Selected CommonTree_1/2/3, Bush_Common, Fern_1, Grass_Wispy_Short, Rock_Medium_1 and DeadTree_2. All selected `.bin` and image dependencies were checked on disk before integration. No paid assets, copied reference art or sound-pack license assumptions.
- Original reed leaves: reproducible `tools/create_jungle_reeds.py`, packed original vein texture and smooth leaf surfaces. Blender source under `art_source/`, runtime GLB under `assets/environment/`.
- `jungle_habitat.gd` owns deterministic palette, budgets, six-metre travel masks, quest/spawn clearings, pond and creek definitions. Maximum canopy layout is invariant across quality levels so low quality never hides a blocking trunk. Ground-cover density uses 0.5/1/1.35; other biomes retain their existing quality rules.
- Pond centered (12,72), creek from (22,55); shared height samples produce shallow walkable banks. Navigation must be regenerated after changing layout or terrain.

## Sequential gates

- [x] Asset license/dependency inventory and scoped layout.
- [x] Rendered Nest/Fernwood pilot reviewed: open nest, layered forest and readable travel lanes.
- [x] Four-chunk vegetation, collision and missing-asset fallback validated.
- [x] Terrain materials, stable irregular wetland and offline navigation validated.
- [x] Wildlife escape/pursuit and trunk camera retraction validated in all four habitats.
- [ ] Four reviewed views, quality/reload/routes, five-minute GPU traversal and regression suite.

Pending checkboxes are not claims of completed visual or performance acceptance.

## Implementation evidence — September 6, 2026

- Implemented spatial vegetation batches across the four chunks, original Blender reeds, shared shader wind, deterministic tree collision, protected quest/spawn clearings, and quality-scaled ground cover. Selected assets are cached rather than loaded per frame.
- Implemented shallow pond/creek shaping in the shared terrain sampler, bank-clipped stable water geometry, layered world-space ground material with six-metre outer material transitions, and four offline navigation resources incorporating trunk geometry. Simplifying navigation detail removed the initial edge-merge warnings.
- Wildlife uses the existing state machines and tiers, with starting-region origin-aware bounds and readable habitat anchors. The basin receives three easy prey before distributing additional prey; additional forest-edge predators respect the existing 25-creature ceiling. No save, quest, chunk, or creature-profile identifiers changed.
- `tests/run_tests.gd`: PASS. `tests/active_run_smoke.gd`: PASS, movement 10.84 m, Adventure combat and T. rex visibility exercised. Headless execution reports sandbox log/certificate access errors; the latest active smoke also reported one ObjectDB leak at exit, which remains to investigate.
- `tests/terrain_smoke.gd`: PASS after separating trunk collision from terrain-query collision. Maximum basin grade 29.71 degrees; terrain/physics discrepancy 0.000050 m; 28 clearing support checks and T. rex/raptor/triceratops movement routes, including growth and biome borders.
- Initial rendered `tests/jungle_smoke.gd`: PASS for deterministic placement, quality scaling, missing-asset fallback and water banks. The revised headless fixture also passes, including trunk collision rays. Medium grass counts 1181–1185 per chunk, canopy count 40. Nest and forest show layered habitat; the first pond/overlook captures need improved framing and review. Later framing/material-transition edits still need a rendered rerun.
- Verbose exit diagnostics identify an `AudioStreamGeneratorPlayback` reference left at shutdown. This is an audio teardown issue, not a terrain/navigation runtime failure; no unrelated audio rewrite was attempted. Recheck under rendered execution before release acceptance.
- `git diff --check`: PASS. Existing unrelated work remains preserved; nothing committed or pushed.

## Next acceptance steps (do not skip)

1. Run the revised jungle smoke fixture, including trunk ray checks; inspect fresh nest, forest, pond and overlook PNGs in `.validation/`.
2. Run `Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 --script res://tests/jungle_smoke.gd -- --benchmark`. This uses 30 seconds warm-up followed by 300 seconds of unfixed-time real movement with live AI. Confirm repeated waypoint arrival and inspect `.validation/jungle_performance.json`; do not accept a stationary/stuck benchmark or invent FPS results.
3. Review predator pursuit, prey escape and camera obstruction in each habitat, including Adult-size pond access; finish remaining visual adjustments and investigate the exit leak.
4. Run the full roadmap gates and record visual acceptance before advancing to broader roadmap work.

## Resumed validation — September 6, 2026

Approval became available and the GPU gate ran. The first run failed route acceptance: a zero-length nest approach caused a non-finite distance and admitted trees into travel corridors. Its 251 FPS result is invalid as a traversal measurement. Fixed the segment-distance root cause, added independent finite-distance/corridor regression assertions, and regenerated all four navigation resources. A short rendered diagnostic then crossed the formerly blocked ridge/forest corridor at normal speed without trunk collisions.

The subsequent full run **passed** after a 30-second warm-up and 300.006 measured seconds:

| Medium, Compatibility, 1280×720, RX 6750 XT | Result |
| --- | ---: |
| Average FPS | 152.42 |
| 95th percentile frame time | 7.33 ms |
| 99th percentile frame time | 7.575 ms |
| Worst frame | 303.632 ms |
| Frames above 33.33 ms | 23 / 45,728 |
| Route waypoints reached | 33 |

Evidence: `.validation/jungle_benchmark.log` and `.validation/jungle_performance.json`. This demonstrates the average performance target on the development GPU, not hitch-free streaming. Investigate the isolated 304 ms hitch before release polish acceptance.

Fresh four-region images were reviewed. Forest corridors are open, the nest stays protected, and the pond has an irregular planted bank. Reduced water specularity/raised roughness removed the harsh white surface highlights. The pond capture still needs a player-readable camera framing check, and the ridge retains its earlier landmark art.

Full `tools/roadmap_validation.ps1` returned **PASS** after the fix (gameplay, startup, active Adventure, terrain routes, diff and roadmap integrity). Existing sandbox log/certificate warnings remain; Windows export templates are still missing. No checkpoint was invented and no files were committed or pushed.

Remaining before closing this milestone: habitat-specific predator/prey pursuit/escape review, Adult pond access and camera-obstruction review, and follow-up on the isolated hitch/audio teardown warning. Do not advance to broad atmosphere work yet.

### Pond access follow-up

`tests/jungle_smoke.gd -- --pond-walk` passes in rendered Compatibility mode. The fixture now advances the actual GrowthSystem to Adult, verifies the 1.75 collider scale, and walks from the wetland approach through (12,60), (12,66), (12,72), then back to the approach. Each destination requires real input-driven movement and terrain-height agreement; no teleport is used between waypoints. Fresh `.validation/jungle_adult_pond.png` shows the Adult in the shallow pond with the creek behind it.

Fixed-view capture now uses a temporary camera with the gameplay FOV rather than fighting SpringArm's internal physics. It restores the gameplay camera afterward, preventing capture transforms from leaking into traversal measurements. The new pond view includes the dinosaur, pond, creek and planted banks. The earlier five-minute result remains a recorded baseline; rerun final performance validation after remaining presentation/performance changes.

Next: habitat-specific predator/prey pursuit and escape, dedicated camera obstruction checks, and hitch/audio teardown investigation. Adult pond traversal is no longer an outstanding gate.

### Habitat and camera follow-up

The `--wildlife` fixture exercises real prey notice/flee movement and predator warn/chase movement against an explicitly weaker player in each starting habitat, checks origin-relative bounds, and tests the actual trunk colliders against the gameplay SpringArm. Camera retraction below four metres and recovery above eight metres passed in all four regions.

Rendered validation found a real zero-direction `look_at()` error when predator and target overlapped. Predator player/prey facing now preserves its last direction when no nonzero horizontal direction exists; attack rules are unchanged. Repeated rendered encounter checks passed without those errors, and the gameplay unit suite passed.

Reviewed encounter imagery exposed close canopy occlusion. The shared tree shader now cuts out fragments within a small camera-clearance radius, opening the center view without per-tree updates or collision changes. Forest encounter framing improved; this is not a claim that every possible foliage/camera angle is perfect.

Remaining work is performance-spike attribution and final validation after these changes. The clean rendered encounter runs did not reproduce the previously logged headless audio teardown leak; retain that earlier diagnostic in release notes rather than claiming an audio fix.

### Spike attribution

Added a bounded 32-entry chunk-activation timing history and a 90-second rendered diagnostic that correlates frames over 33 ms with recent chunk builds. This diagnostic does not replace the five-minute acceptance run. It passed nine route waypoints; its measured 60-second portion averaged 250 FPS, with four frames over 33 ms and a 192.66 ms maximum.

Every recorded large traversal spike coincided with neighboring legacy chunks being constructed synchronously: Cloudforest about 71 ms, Ancient Meadow/Coastal Marsh/Fossil Flats about 58/57/63 ms in a single transition, and Badlands/Volcanic Foothills about 55/64 ms together. Evidence: `.validation/jungle_spike_diagnostic.json`. The starting-region foliage budget is not implicated by these recorded activation samples. Do not reduce jungle density to hide legacy chunk construction; address this measured bottleneck in the subsequent tiered-streaming milestone. This is attribution, not a claim of zero renderer or driver stalls.

Final post-camera-change five-minute validation remains required before closing the scoped jungle milestone. Keep the synchronous-build hitch visible as a follow-up acceptance risk for the larger roadmap.

### Latest benchmark and user-directed advancement

The final benchmark completed: 300.086 measured seconds, 33 waypoints, 78.68 FPS average, 64.505 ms p95, 130.961 ms p99, 288.532 ms maximum, and 2,295 frames above 33.33 ms. Its route assertion passed, but its frame-time consistency is substantially worse than the earlier baseline. Many recorded spikes have no recent chunk activation, so legacy loading alone does not explain this run; GPU/host-load and presentation costs remain unresolved. Do not cite the earlier 152 FPS run as the latest result or claim smooth performance.

The user explicitly requested moving to the next milestone. Atmosphere development has therefore begun, carrying this performance risk forward rather than marking all jungle acceptance gates complete. Functional/visual checks remain recorded above; final performance polish is still open.
