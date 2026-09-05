# Roar & Rise — Project Plan

## Vision

Roar & Rise is a bright, kid-friendly 3D dinosaur adventure game. Players choose a dinosaur, explore a connected multi-biome prehistoric reserve, eat suitable food to grow from Hatchling to Adult, learn species abilities, complete a quest chain, and unlock Endless Survival.

The initial release targets Windows PC with keyboard/mouse and gamepad support. It is single-player and avoids graphic violence: dinosaurs bump, flee, recover, and respawn at a safe nest.

## Active Roadmap 3.0 — Living Reserve and Endless Adventures

Updated September 5, 2026. Prioritize living ecosystems and Endless replayability within the existing reserve and six playable species before adding maps or dinosaurs. Stages F–K below are pending implementation; completed checkpoints through 313 remain historical evidence, not proof that every release acceptance gate has passed.

### Current milestone: F — Establish the gameplay expansion baseline

Make subsequent improvements measurable and protect the existing game. The next milestone is G — Herds and readable predator behavior.

- [ ] Inventory the current playable roster, connected chunks, Adventure routes, and Endless objective rotation from implementation; reconcile outdated roadmap descriptions.
- [ ] Record one 20-minute Endless baseline per species: food availability, defeats, encounter frequency, objective completion, frame times, and active actor counts.
- [ ] Define shared creature behavior states: idle, forage, travel, alert, flee/chase, and recover.
- [ ] Add deterministic simulation hooks for behavior/event tests; retain existing movement and navigation fallbacks.
- [ ] Track packaging prerequisites separately so missing templates do not prevent gameplay development. Windows export templates were missing at the September 5 review; recheck before packaging acceptance.

Gate: all six species start both permitted modes correctly; baseline results and existing failures are documented; gameplay tests and headless startup pass.

Evidence: pending — record validation results, six baseline run summaries, and known failures here.

### Stage G — Herds and readable predator behavior

Depends on F.

- [ ] Introduce habitat-local herds of up to four compatible herbivores, using existing actors rather than extra decorative creatures.
- [ ] Implement loose following, separation, shared threat alerts, flight, and regrouping.
- [ ] Allow predators to approach and chase eligible NPC prey, followed by disengagement and recovery. Reuse existing combat and non-graphic feedback.
- [ ] Give NPC-only encounters no player growth, quest progress, or collectible victory tokens. Preserve existing player combat rewards.
- [ ] Preserve safe-nest exclusions and renewable food floors; ecosystem activity must not exhaust the player's food supply.
- [ ] Count every participating creature toward the existing 25-actor simulation budget; unloaded habitats retain lightweight population records.

Gate: automated scenarios verify regrouping, target loss, disengagement, habitat boundaries, and population recovery. A 30-minute session shows no stuck herd, endless chase, duplicate actor, or food collapse.

Evidence: pending — record behavioral test results and the observed session here.

### Stage H — Habitat events

Depends on G. Enable scheduled events in Endless first.

- [ ] Implement Herd Journey: an existing herd travels between two reachable habitat points.
- [ ] Implement Fresh Growth: temporarily increase edible plants within existing spawn limits.
- [ ] Implement Predator Passage: an existing predator traverses a permitted route, with a readable warning and retreat opportunity.
- [ ] Allow one event at a time; begin checking after three minutes, with at least three minutes between events. Finish or cancel each event within two minutes.
- [ ] Select only reachable, eligible active habitats; defer when no valid event exists.
- [ ] Pause event timers with gameplay. Cancel cleanly on defeat, restart, or owning-chunk unload.

Gate: deterministic tests cover eligibility, timing, cancellation, resource restoration, and actor caps. Events never obstruct mandatory routes or force combat.

Evidence: pending — record event lifecycle tests and route observations here.

### Stage I — Varied Endless challenges

Depends on H.

- [ ] Replace the fixed rotation with four reusable challenge families: forage, discover, observe a herd journey, and evade a predator passage.
- [ ] Keep one tracked challenge; support skipping without penalty and prevent immediate repetition.
- [ ] Filter objectives by diet, growth stage, reachable habitats, and active event availability.
- [ ] Preserve existing survival difficulty scaling initially; events must not add hidden damage or hunger multipliers.
- [ ] Award three Growth Points once per completed challenge, matching the existing Endless Feast reward. Skipped, cancelled, or repeated completion signals grant nothing.
- [ ] Fall back to a reachable forage challenge when event content is unavailable.
- [ ] Add concise objective text, progress, direction, and completion feedback usable with muted audio and a gamepad.

Gate: all six species receive completable challenges. Tests cover duplicate rewards, target disappearance, chunk unloading, skipping, pause, and defeat recovery.

Evidence: pending — record challenge eligibility/reward tests and six-species play checks here.

### Stage J — Discovery and personal progression

Depends on I.

- [ ] Add field-guide discovery for the three event types, with short explanations of observed behavior.
- [ ] Record per-species challenge completions and best completed-challenge total per run.
- [ ] Award one badge for discovering all three events and one per-species badge for completing ten challenges cumulatively.
- [ ] Add no permanent combat advantages, currencies, daily requirements, or online services.
- [ ] Persist discoveries and records through additive save defaults; preserve existing unlocks, cosmetics, settings, and records.
- [ ] Continue the current new-run behavior on application restart; resumable runs are outside this expansion.

Gate: old and incomplete saves load safely; rewards cannot duplicate; records remain species-specific; menus work with keyboard and gamepad.

Evidence: pending — record save compatibility, reward, and menu navigation results here.

### Stage K — Balance and expansion acceptance

Depends on J.

- [ ] Playtest 60 minutes of Endless per species and one two-hour soak.
- [ ] Run Adventure regression routes to ensure ecosystem changes preserve quest targets, food access, and finales.
- [ ] Conduct five observed family-friendly sessions. Target at least four participants understanding their first challenge without developer explanation.
- [ ] Profile representative event-heavy routes and optimize measured bottlenecks, following [Godot's profiling guidance](https://docs.godotengine.org/en/latest/tutorials/performance/general_optimization.html).
- [ ] Check warning readability, input accessibility, muted-audio play, and reduced motion against the [Xbox Accessibility Guidelines](https://learn.microsoft.com/en-us/xbox/accessibility/guidelines).
- [ ] Complete actual Windows export and interactive packaged-build checks once prerequisites are resolved.

Gate: no progression blockers, duplicate rewards, unbounded populations, or critical defects; existing performance targets hold; remaining issues have explicit severity and reproduction evidence.

Evidence: pending — record six-species runs, soak results, observed playtests, hardware/profile results, and packaged-build checks here.

### Interfaces, validation, and execution rules

- Extend existing creature profiles with optional behavior settings and add shared event/challenge definitions. Keep `main.gd` responsible for coordination rather than species-specific rules. Preserve existing quest callers and save keys.
- Execute the earliest incomplete stage in focused implementation slices. Require targeted behavioral tests, existing gameplay validation, headless startup, and `git diff --check` for each slice. Tests of fixed constants alone do not constitute a completed gameplay feature.
- Keep pending work as checkboxes. Record checkpoint 314 only after the first new implementation slice passes validation; continue sequentially thereafter. Preserve the earlier checkpoint log and its automation-compatible format.
- Distinguish automated checks, observed playtests, and packaged-build verification in each evidence field. Mark a stage complete only when its deliverables and gate pass; document blockers explicitly.
- Retain existing Windows, accessibility, non-graphic combat, asset licensing, and performance requirements. No new maps, dinosaurs, multiplayer, or automatic publication are included.
- Retain the manual-trigger development loop and local-commit policy below; this document update does not implement gameplay or create a completion checkpoint.

## Historical roadmap context

The earlier summaries, development steps, and Roadmap 2.0 below preserve production history and reference requirements. Their former current/next labels are superseded by Roadmap 3.0. Unverified release gates remain outstanding rather than being marked complete by this planning update.

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

## Historical Milestone: Structured Playtest and Balance

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

## Historical Milestone: Collection and Family Playtest

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
67. Added three expansion playable species through data-driven profiles.
68. Updated selection layout with scrollable six-species support.
69. Authored and exported the Ankylosaurus playable GLB through the Blender pack generator.
70. Added playable-model asset coverage for Ankylosaurus, Parasaurolophus, and Carnotaurus.
71. Added data-driven visual landmark generation to every loaded biome chunk scene.
72. Added regression coverage proving every biome scene instantiates a visible landmark mesh and readable label.
73. Positioned streamed chunk scenes from their authored grid coordinates to prevent biome overlap.
74. Applied persisted chunk state when streamed biome scenes are instantiated after reload.
75. Applied authored navigation constraints to loaded biome scene roots for runtime alignment.
76. Added lightweight per-biome ground meshes and static collision to streamed chunk scenes.
77. Added biome-specific elevated terrain forms with matching collision for ridge, wetlands, meadow, and badlands chunks.
78. Added deterministic low-cost MultiMesh vegetation batches to every streamed biome chunk.
79. Added a shallow translucent water surface to the River Wetlands chunk with biome-specific validation.
80. Added lightweight biome ambient particle effects with dry-biome color variation.
81. Added per-biome NavigationRegion3D meshes aligned to streamed ground pads and authored agent limits.
82. Added streamed NavigationLink3D connectors between loaded neighboring biome chunks with unload cleanup.
83. Added shared active-chunk world-position checks for navigation and actor recovery logic.
84. Connected active-chunk confinement to the world actor grounding pass for safe NPC recovery.
85. Added reusable habitat spawn rules and applied them to predator spawning and tier validation.
86. Added an active-chunk spawn plan combining biome rules with valid prey and predator tiers.
87. Connected active habitat prey tiers to renewable food spawning.
88. Added per-tier population caps derived from the active habitat spawn plan.
89. Added inactive-habitat NPC pruning so streamed prey and predators release simulation budget cleanly.
90. Added per-chunk prey and predator population snapshots for stable streaming respawn state.
91. Added persisted active population budgets to cap renewable prey replenishment after streaming reloads.
92. Added persistent per-chunk respawn cooldown timers with runtime ticking and save-state compatibility.
93. Connected creature defeat events to chunk respawn cooldowns using each profile's respawn delay.
94. Deferred renewable food replenishment while active habitat respawn cooldowns are still running.
95. Added independent per-role and per-tier respawn cooldowns to chunk state.
96. Connected active tier cooldowns to prey replenishment so only affected tiers pause.
97. Added role-neutral tier readiness checks for independent predator and prey respawn behavior.
98. Added an injectable predator respawn gate so tier cooldowns can control hidden-to-visible recovery.
99. Connected spawned predators to the stream manager's actual tier readiness callback.
100. Connected renewable prey instances to the same biome and tier readiness gate.
101. Added mixed-population integration coverage for independent prey and predator cooldowns across active chunks.
102. Added a 600-step streaming-session validation for bounded populations and cooldown expiry.
103. Added runtime streaming metrics for active chunks, loaded scenes, NPC count, and population utilization.
104. Added a compact diagnostics HUD with a warning threshold near the 25-NPC performance target.
105. Added configurable diagnostics visibility for development versus release-style builds.
106. Added rolling frame-time sampling and a sustained-performance warning to the diagnostics HUD.
107. Added headless performance-budget validation for repeated streaming and cooldown simulation.
108. Added automated six-species Adventure startup, ability/quest coverage, and persistence validation.
109. Added cross-species authored-asset and save-isolation validation for the expanded roster.
110. Added deterministic six-card selection layout coverage for keyboard and gamepad focus navigation.
111. Added reusable row-wrapping selection navigation rules with keyboard/gamepad regression tests.
112. Wired explicit focus neighbors into the six Adventure selection buttons and auto-focused the first card.
113. Added controller-binding regression coverage for selection activation and gameplay movement actions.
114. Added accessibility validation for large text, high contrast, and focusable HUD controls.
115. Added pause, restart, and return-to-selection flow signal validation for input recovery paths.
116. Extended save-recovery validation for settings defaults and chunk state across run transitions.
117. Added six-species Adventure reward validation proving independent Endless unlock persistence.
118. Added six-species Endless progression validation for survival time, repeatable quests, and personal records.
119. Added Endless difficulty-scaling validation for predator awareness and bounded resource scarcity.
120. Added consolidated release-readiness validation for startup artifacts, roster, save schema, and test coverage.
121. Added distinct low-poly landmark silhouettes for each biome destination.
122. Added biome identity metadata to landmark silhouettes for runtime presentation and future navigation cues.
123. Connected active chunk selection to the player's world position instead of a fixed origin chunk.
124. Added boundary-transition validation for activating adjacent chunks and releasing distant chunks.
125. Corrected playable-species validation to use the profile's typed adventure quest chain.
126. Hardened food-spawner and low-level supply validation against stale or non-prey group members.
127. Removed invalid manual frees of reference-counted save fixtures and hardened the replenishment assertion.
128. Added a stream-manager landmark lookup API for quest and navigation destination targeting.
129. Added world-space landmark destination queries for translated streamed chunks.
130. Added aggregate active-landmark positions for HUD, quest, and accessibility consumers.
131. Wired active streamed landmarks into scent-trail fallback targeting while preserving quest priority.
132. Centralized nearest-active-landmark selection in the stream manager for consistent destination guidance.
133. Added loaded-landmark counts to streaming diagnostics for performance and accessibility validation.
134. Stabilized active-landmark enumeration order for deterministic destination guidance.
135. Expanded the authored reserve with Cloudforest Rise and Coastal Marsh chunk profiles.
136. Expanded the authored reserve with Volcanic Foothills and Fossil Flats tiered habitats.
137. Expanded the authored reserve with Redwood Canyon and Highland Plateau tiered habitats.
138. Expanded the authored reserve with Moonlit Grove and Saltwind Dunes tiered habitats.
139. Completed the planned sixteen-chunk reserve with Glacier Valley and Cypress Basin.
140. Added distinct materials and elevation forms for all ten newly authored biomes.
141. Added water surfaces to Coastal Marsh and Cypress Basin with biome-specific styling.
142. Tuned batched vegetation density and scale for sparse, wetland, forest, and highland biomes.
143. Added restrained biome-specific ambient particle profiles for wetland, volcanic, icy, and moonlit zones.
144. Assigned distinct landmark offsets by biome so destination silhouettes no longer overlap at one generic corner.
145. Added reserve uniqueness validation for chunk IDs, biome names, and landmark destinations.
146. Added full-reserve reachability validation from the safe nest across symmetric chunk links.
147. Added authored-scene validation for non-empty landmark presentation kinds.
148. Added per-biome streamed environments with fog density and background color derived from chunk profiles.
149. Added exact profile-to-runtime fog density validation for every authored chunk.
150. Added biome-aware ambient light color and energy for bright, readable streamed scenes.
151. Applied per-profile navigation layers and agent radius after streamed chunk instantiation; slope and climb remain profile metadata for editor baking.
152. Exposed per-profile slope and climb limits on streamed navigation regions for runtime inspection.
153. Added spawn-table versus habitat-rule consistency validation for all sixteen chunks.
154. Added plant-food availability consistency validation for every habitat profile.
155. Added distinct volcanic-cone and ice-beacon landmark geometry for highland reserve zones.
156. Added translated-chunk placement validation for non-origin terrain and landmarks.
157. Added validation that visible landmark labels match their authored profile names.
158. Added runtime validation that every streamed biome derives a visible non-black background palette.
159. Added `tools/roadmap_validation.ps1` as a repeatable three-gate validator for tests, headless startup, and Git whitespace.
160. Documented the roadmap validator workflow in `README.md` for repeatable milestone handoff.
161. Hardened the validator to require the explicit gameplay PASS marker and reject reported test failures.
162. Added roster GLB resource-load validation while retaining procedural fallback coverage.
163. Added playable imported-model animation-library validation for all required child-friendly motion states.
164. Added imported prey and predator animation-library validation for the complete required motion set.
165. Updated README asset guidance to distinguish imported GLB models from procedural fallbacks.
166. Hardened the validator startup gate to reject script and parse errors while preserving known environment warnings.
167. Added a shared stream-manager profile lookup for readable biome names in UI and quest systems.
168. Added readable biome-entry feedback when a new streamed chunk activates during gameplay.
169. Added null-safe validation for unknown streamed chunk profile lookups.
170. Added null-safe validation for unknown streamed landmark and position lookups.
171. Added stable active-biome name enumeration for UI and accessibility consumers.
172. Added deterministic ordering validation for active-biome name enumeration.
173. Included ordered active biome names in runtime streaming diagnostics data.
174. Added empty-state validation for active biome enumeration before first stream activation.
175. Extended streamed chunk snapshot coverage to the expanded Glacier Valley biome, including nested state restoration and scene reload compatibility.
176. Added active-biome context to the developer HUD diagnostics, with compact multi-biome display for streamed-world debugging.
177. Added defensive HUD formatting and automated coverage for empty, malformed, and multi-biome diagnostics payloads.
178. Validated that clearing the streamed-world configuration resets active-biome diagnostics to a clean empty state.
179. Hardened active-biome enumeration to deduplicate profile names before sorting and exposing them to HUD diagnostics.
180. Added a direct regression case with distinct chunks sharing one biome name to verify diagnostic deduplication.
181. Added an explicit `active_biome_count` runtime metric with consistency validation against the deduplicated biome list.
182. Updated the developer HUD to display the exact active-biome count alongside readable biome names.
183. Added playable-roster integrity checks ensuring all six species IDs and display names remain unique.
184. Added roster progression validation for the four growth stages and ordered, in-range ability unlock stages.
185. Expanded legacy-save migration coverage to preserve species Endless unlocks and per-species records.
186. Added roster-wide Adventure quest validation for unique IDs, ordered growth stages, valid stage bounds, and Adult finales.
187. Added diet and quest-target validation so carnivore and herbivore progression cannot reference incompatible food sources.
188. Added optional-quest metadata validation to prevent ID collisions and ensure optional entries are explicitly flagged.
189. Added NPC catalog validation for supported roles and tier bounds across all seven creature profiles.
190. Added `tools/roadmap_status.ps1` to report the latest checkpoint and optionally run the complete validation gate in one command.
191. Added duplicate-checkpoint rejection to the roadmap status runner before milestone validation runs.
192. Added roadmap checkpoint integrity as the fourth gate in the main validation script.
193. Added chronological ordering for checkpoints 162–165 in the roadmap execution history.
194. Added ascending-order enforcement for roadmap checkpoints in the status runner.
195. Added NPC tier-balance validation for health, damage, Growth Point rewards, and respawn delays.
196. Added NPC movement and sensing validation for positive speeds, flee capability, ranges, and attack cooldowns.
197. Added NPC role-to-tier validation so prey remains below finale tier and rivals remain tier four.
198. Added NPC presentation validation for non-empty display names and visible body colors.
199. Added reward-scaling validation for positive hunger rewards and nondecreasing Growth Point rewards by NPC tier.
200. Added a checked-in Windows Desktop export preset and automated coverage for its platform and runnable settings.
201. Added the Windows export-template prerequisite to release documentation after a headless export smoke test reached the preset but found no installed 4.7.2 templates.
202. Added reserve-wide navigation slope and climb validation to protect accessible quest routes across all authored chunks.
203. Added a repeatable Windows export smoke-test script and explicit export-filter defaults for the checked-in preset.
204. Added export-template availability reporting to roadmap status so packaging blockers are visible without obscuring code validation.
205. Added a strict `-RequireExportTemplates` roadmap-status flag for release-candidate packaging gates.
206. Added strict export-template forwarding to the main roadmap validator for one-command release-candidate checks.
207. Added case-mismatch detection to the Windows export smoke test to protect packaged resource paths.
208. Added release viewport and HUD-scaling validation for the documented 1280×720 Windows baseline.
209. Added input-map validation for eat, Power Bite, scent, dash, and special dinosaur abilities.
210. Added direct mouse-binding validation for left-click Eat and right-click Power Bite controls.
211. Added playable-ability metadata validation for readable names, descriptions, and positive cooldowns.
212. Added per-species ability-ID uniqueness validation to prevent skill-state collisions.
213. Added validation that every playable ability declares a nonempty runtime input action.
214. Added release validation for the configured `res://Main.tscn` main scene to prevent launch regressions.
215. Added runtime input-bootstrap coverage so gamepad ability bindings are validated alongside keyboard and mouse controls.
216. Added idempotence validation for repeated runtime input initialization to prevent duplicate bindings.
217. Added quest-value validation for positive objective amounts and nonnegative Growth Point rewards.
218. Added finite-coordinate validation for main and optional quest markers used by scent trails and navigation.
219. Added playable-roster presentation validation for child-friendly taglines and visible body/accent colors.
220. Added playable-profile AI relationship validation for declared prey and threat categories.
221. Added AI relationship value-type validation so prey and threat categories remain arrays for data-driven encounter logic.
222. Added AI relationship identifier validation for nonempty string entries in prey and threat categories.
223. Added authored-chunk metadata validation for readable IDs, biome labels, and landmark names.
224. Added reserve-wide scene-path existence and resource-load validation for every streamed chunk.
225. Added chunk-neighbor validation for nonempty, non-self string IDs to protect streamed border connectivity.
226. Added scene-extension validation so streamed chunk profiles reference Godot `.tscn` scenes.
227. Added authored-reserve bounds validation for streamed chunk grid coordinates.
228. Added grid-position uniqueness validation to prevent overlapping streamed chunks.
229. Added habitat spawn-table validation so every authored chunk declares at least one population category.
230. Added spawn-table key validation for the supported prey, predator, and plant habitat categories.
231. Added habitat spawn-tier validation to keep prey and predator entries within supported tiers 1–4.
232. Added strict boolean validation for authored plant-availability habitat flags.
233. Added authored-chunk visual and navigation tuning validation for bounded vegetation density, fog density, and positive navigation layers.
234. Added authored vegetation-density profiles to streamed MultiMesh instance counts and validated runtime scaling per biome.
235. Added authored ground-palette application to streamed terrain meshes and validated per-biome terrain colors at runtime.
236. Added authored palette propagation to streamed biome fog and ambient lighting, with runtime environment-color validation.
237. Added applied fog-density metadata to streamed chunk visuals and validated diagnostics reflect runtime values.
238. Added authored palette tinting for streamed landmark silhouettes and validated landmark color coherence per biome.
239. Added authored palette tinting for streamed wetland water surfaces and validated water color coherence per biome.
240. Added authored palette tinting for streamed ambient particle materials and validated atmospheric color coherence per biome.
241. Added authored palette tinting for streamed batched vegetation materials and validated foliage color coherence per biome.
242. Added authored palette propagation to streamed fog light colors and validated complete biome environment color coherence.
243. Added explicit visibility ranges to streamed batched vegetation and validated bounded foliage distance culling.
244. Added explicit visibility ranges to streamed landmark silhouettes and validated bounded landmark distance culling.
245. Added explicit visibility ranges to streamed ambient particles and validated bounded atmospheric distance culling.
246. Added explicit visibility ranges to streamed water surfaces and validated bounded wetland distance culling.
247. Added landmark-label visibility-range validation to preserve readable but bounded destination signage.
248. Added an explicit visibility range to streamed ground meshes and validated controlled terrain draw distance.
249. Added explicit visibility ranges to streamed elevated terrain features and validated bounded hill/ridge rendering.
250. Added per-chunk vegetation and ambient-particle budget validation to protect the target roaming-world performance envelope.
251. Added bounded visibility ranges to legacy valley tree trunks and crowns, with integration coverage for all animated trees.
252. Added bounded visibility ranges to legacy valley fireflies, with integration coverage for all ambient fireflies.
253. Added bounded visibility ranges to legacy valley waterfall layers, with integration coverage for all animated layers.
254. Added bounded visibility ranges to legacy habitat landmark markers, with integration coverage for marker geometry and labels.
255. Added an explicit visibility range to the legacy valley ground mesh and validated the integration scene draw-distance budget.
256. Added visible-color validation for every authored chunk ground palette to protect child-friendly environment contrast.
257. Added opaque, in-range channel validation for authored chunk palettes before material application.
258. Added an explicit legacy-environment node and integration validation for global child-friendly fog.
259. Added bounded-density and visible-color validation for the legacy valley fog and background environment.
260. Added an explicit ValleySun node and integration validation for bounded directional and ambient lighting energy.
261. Added integration validation for legacy habitat-label font sizing and outline strength at gameplay distance.
262. Added streamed-chunk landmark-label font and outline validation for consistent reserve signage readability.
263. Added streamed-chunk landmark-label contrast validation to require a non-white outline against bright terrain.
264. Added legacy habitat-label contrast validation to require a non-white outline against bright terrain.
265. Added bounded sky-affect validation for legacy valley fog to protect atmospheric readability.
266. Enabled bounded directional shadows for ValleySun and validated shadow coverage for readable terrain depth.
267. Added explicit shadow-casting settings to streamed ground, elevation, and landmark meshes with runtime validation.
268. Added explicit legacy-scene shadow policy for trees, crowns, habitat markers, and non-shadowing waterfall layers.
269. Added explicit streamed shadow policy for batched vegetation and non-shadowing water surfaces with runtime validation.
270. Added non-shadowing configuration for legacy fireflies with integration validation to reduce ambient-effect cost.
271. Added explicit shadow casting for the legacy valley ground mesh with integration validation.
272. Added validation that streamed ambient particles use unshaded materials for bright, low-cost presentation.
273. Added authored water tint alpha preservation during profile application and validated translucent wetland surfaces.
274. Added bounded roughness and metallic validation for authored wetland water materials.
275. Added bounded lifetime validation for streamed ambient particles to protect effect churn budgets.
276. Added restrained sky-affect tuning to streamed biome fog and validated bounded atmospheric blending.
277. Added exact target validation for streamed fog sky-affect application to preserve authored landmark readability.
278. Added bounded roughness validation for streamed batched vegetation materials.
279. Added bounded metallic-response validation for streamed batched vegetation materials.
280. Added non-empty visibility-volume validation for streamed ambient particle effects.
281. Added positive-dimension validation for streamed elevation meshes to protect authored hill and ridge geometry.
282. Added authored ground-palette propagation to streamed elevation meshes and validated hill/ridge color coherence.
283. Added bounded roughness validation for streamed elevation materials under the shadowed terrain pass.
284. Added bounded metallic-response validation for streamed elevation materials under directional lighting.
285. Added explicit elevation collision-shape naming and validated collision dimensions match visible hill geometry.
286. Added elevation collision-position validation to keep streamed hill physics aligned with visible terrain.
287. Added explicit ground collision-shape naming and validation that streamed collision covers the visible terrain pad.
288. Added positive-dimension validation for streamed landmark silhouettes to protect destination geometry.
289. Added camera-range validation so streamed landmarks remain visible throughout their authored presentation distance.
290. Added navigation-span validation so every streamed navigation pad covers the visible terrain footprint.
291. Added navigation-height validation so streamed walkable surfaces align with ground collision height.
292. Added an out-of-bounds actor recovery test to verify safe return to an active navigable chunk.
293. Added landmark-bound validation so streamed destination silhouettes remain inside their 60×60 chunk footprint.
294. Added readable-distance validation so streamed landmark labels remain visible with their destination markers.
295. Added vertical-placement validation so streamed landmark labels remain above their marker geometry.
296. Added `tools/roadmap_loop.ps1`, a bounded validation loop that advances only after a new checkpoint is recorded and stops safely when work is unchanged.
297. Added roadmap-file preflight validation so the loop refuses to run against a missing or malformed project plan.
298. Added checkpoint-integrity preflight so the loop rejects duplicate or out-of-order roadmap entries before gameplay validation.
299. Added sequential-advance enforcement so the roadmap loop cannot skip a milestone between validation passes.
300. Added a hard 100-iteration safety cap to prevent unbounded roadmap automation.
301. Added `ROADMAP_AUTOMATION.md` documenting the milestone loop contract, gates, stop conditions, and packaging prerequisite.
302. Added optional JSON result reporting to the roadmap loop for scheduled-run observability.
303. Added end-to-end validation evidence for JSON loop reporting, including checkpoint, iteration count, stop reason, and pass status.
304. Added explicit automation safety documentation: the loop validates authored milestones and never fabricates completion checkpoints.
305. Added packaging-gate evidence: Windows export templates are missing, and the export smoke test reports case-mismatched imported asset paths that must be normalized before release packaging.
306. Added packaging diagnosis confirming no direct `res://textures/` references remain in authored source; remaining case warnings originate in imported asset metadata.
307. Added packaging-gate error ordering so missing export templates are reported before secondary imported-asset case warnings.
308. Added export-smoke preflight checks for both required Godot 4.7.2 Windows templates, avoiding a noisy export scan when the prerequisite is absent.
309. Added optional packaging-smoke execution to the roadmap loop for release-gate validation.
310. Added packaging-loop validation evidence confirming the optional gate halts before checkpoint advancement when export templates are missing.
311. Added strict-loop template preflight so `-RequireExportTemplates` fails before gameplay validation when release prerequisites are absent.
312. Added result-path preflight so scheduled runs reject an invalid JSON output directory before validation begins.
313. Added end-to-end observability evidence covering both valid JSON result output and invalid-directory rejection.
314. Added deterministic AI recovery-transition coverage for prey and predators, confirming both return from recovery to wandering while preserving valley bounds.
315. Added reusable prey herd context with tier-local leader/anchor assignment and deterministic follower-context coverage.
316. Added shared threat alerts so nearby members of the same prey herd enter flee state together after an attack.
317. Added non-player predator pursuit of eligible NPC prey with warn, chase, disengage, and recover states isolated from player combat rewards.
318. Added NPC predator territory-disengagement regression coverage to prevent endless chases beyond the readable valley boundary.
319. Added reusable herd regrouping toward shared anchors with recovery-state coverage for separated members.
320. Added lightweight herd-count persistence to streamed chunk state alongside existing prey and predator population records.
321. Added active herd-budget reporting so streamed and unloaded habitats contribute to ecosystem population accounting.
322. Added herd counts to runtime metrics for population observability and budget diagnostics.
323. Added a four-member herd-size cap so excess compatible prey seed separate herd anchors.
324. Added spawn-maintenance coverage confirming tiered prey herds remain capped at four members during replenishment.
## Release Readiness

- Complete all three Adventure routes from a clean save.
- Verify each completed Adventure unlocks only its matching Endless mode.
- Test new, valid, corrupt, and older save files.
- Run extended Endless sessions to confirm food renewal and difficulty scaling.
- Playtest keyboard/mouse and gamepad with large-text settings enabled.
- Confirm no blood, wounds, carcasses, or graphic defeat imagery appears.
- Package and test a Windows build, then publish a tagged release to GitHub.

## Historical Roadmap 2.0 — From Base Game to Polished Release

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

### Asset-pack integration execution steps (reviewed September 4, 2026)

Status: inventory and integration planning complete; runtime integration and in-engine acceptance remain pending. Execute the steps below within milestones A–E, starting with A1. These refine Detailed Development Step 5 and the graphics/environment pass; they do not mark existing milestone gates complete or start a separate expansion. Continue the unfinished UI, dinosaur rigging, and playtest work alongside these slices.

#### Reviewed inputs and decisions

| Input in repository | Evidence and intended use | Decision |
| --- | --- | --- |
| `KayKit_Forest_Nature_Pack_1.0_FREE/Assets/gltf/` | 105 glTF models; trees, bushes, grass, bare trees, and several rock families. The supplied contents image shows broad, simple silhouettes that fit the friendly dinosaur presentation. `License.txt` identifies CC0. | Primary environment kit for Nest Basin and Ancient Meadow; reuse its rocks and sparse vegetation across other biomes. |
| `glTF/`, `Textures/`, `FBX/`, `FBX (Unity)/`, `OBJ/` | Quaternius Stylized Nature MegaKit FREE: 68 glTF models, matching the count in `License_Standard.txt` (CC0). Includes `Fern_1`, common/twisted/dead trees, pines, grasses, flowers, pebbles, and rock paths. | Supplement KayKit with forest undergrowth and biome accents. Use glTF plus its referenced buffers/textures; the alternate formats are source alternatives, not extra model sets. Do not assume the paid edition's shaders or models are supplied. |
| `Sound FX Starter Pack Vol. 1/` | 144 WAV files across 12 categories; includes environment loops, UI sounds, reward stingers, and unsuitable horror/weapon material. A `Royalty-Free License (Link).pdf` is present; its linked terms have not been verified in this review. | Audition a small shortlist and verify the actual license/source before shipping any clip. Filenames alone do not establish child-friendly sound or permission. |
| `addons/proton_scatter/` | ProtonScatter 4.2.0, MIT, according to local plugin metadata/license. | Optional authoring experiment in B; existing deterministic MultiMesh vegetation remains the baseline. |
| `addons/terrain_3d/`, `addons/terrabrush/` | Terrain3D 1.0.2 and TerraBrush are MIT terrain tools. Their extension manifests declare minimum Godot versions 4.4 and 4.5 respectively; this is not proof of runtime compatibility. | Evaluate only if authored terrain needs an editor tool. Select at most one after an isolated comparison; no automatic terrain replacement. |
| `addons/sky_3d/` | Sky3D 2.1, MIT; local README explicitly supports Compatibility rendering and supplies renderer-specific adjustments. Separate shader and texture license files are also present. | Optional fixed-daylight sky trial after the biome art pass; defer the day/night cycle. |
| `addons/godot_ai/` | Godot AI 3.2.1 describes an MCP server and AI editor tools. | Development tooling, not game content; no runtime dependency or automatic enablement is needed for this plan. |
| `demo/`, pack samples/previews, `__MACOSX/` | Imported examples and distribution material; demo textures cite ambientCG CC0 sources. | Reference material only. Do not make demo scenes the game's entry scene or ship unused sample/archive content. |

Review validation: parsed all 173 nature glTF files and checked their external buffer/image paths; no missing referenced files were found. This verifies dependency presence, not rendering, scale, collision, animation, or performance. Sound clips were not auditioned. Existing modified dinosaur GLBs and `tests/run_tests.gd` are separate work and were left untouched.

#### A1 — Curate an importable vertical-slice kit

1. Record selected source paths, pack/version, license location, destination, and any material changes in an asset manifest/credits document. Retain supplied notices with the selected assets; inspect secondary shader/texture notices if using add-ons.
2. Select a small KayKit tree/bush/rock set and Quaternius `Fern_1`, `Grass_Common_Short`, and pebble accents. Compare them beside the T. rex at gameplay distance before expanding selection; unify palette, roughness, scale, and foliage treatment without flattening required texture detail.
3. Put selected runtime scenery under `assets/models/environment/` with Godot wrapper scenes. Preserve glTF relative buffer/image paths when copying, or deliberately convert and validate self-contained GLBs. Keep source drops intact during curation; exclude unused alternate formats, demos, and archive metadata from import/export through a deliberate packaging pass.
4. Check origins, meter scale, material surfaces, shadows, transparency, and ground contact in the current `gl_compatibility` renderer. Use simple collision only for trunks, major rocks, and gameplay landmarks; grass and decorative bushes should not obstruct actors.
5. Add a resource-load check for each selected wrapper and run the existing Godot tests/startup commands. Gate: all selected assets render with complete materials in editor and packaged Windows smoke tests; no gameplay assets or source edits are overwritten.

#### A2 — Dress Nest Basin and Fernwood without changing gameplay

1. Replace selected procedural scenery in `main.gd` and vegetation visuals in `world_chunk_visual.gd`; use biome selection data in `world_chunk_profiles.gd` rather than scattering pack-specific paths through gameplay logic.
2. Use KayKit canopy/bush/rock silhouettes in Nest Basin and Quaternius common trees, ferns, and restrained grasses in Fernwood. Preserve safe-nest clearance, food visibility, quest-marker sightlines, and existing terrain grounding.
3. Extend the existing MultiMesh approach with a batch per compatible mesh/material combination. Preserve child mesh transforms and all required surfaces when extracting meshes from imported scenes. Keep significant collision objects separate from decorative batches.
4. Keep food visuals distinguishable from decorative plants; imported shrubs must not become edible or alter spawn quotas merely because they look like food. Author landmarks separately where the packs lack a recognizable quest prop.
5. Validate collision and navigation around new obstacles for the largest dinosaur and confirm unload/reload does not duplicate scenery. Gate: T. rex completes the vertical-slice route with readable objectives and stable target frame rate. Do not use visual dressing to change terrain height queries.

#### A3 — Introduce a small, licensed audio set

1. Retrieve and retain the terms referenced by the supplied license PDF, record the publisher/source, and resolve any usage/redistribution uncertainty before accepting clips. Continue visual integration independently if audio clearance is pending.
2. Audition `UI & Menus/Select.wav`, `Hover Over.wav`, `Achievement.wav`, `Jingles & Stingers/Level Up.wav`, `Success.wav`, and `Area Discovered.wav`. Test `Environment/Grassy Field Loop.wav`, `Rain Forest Loop.wav`, and `Wind Loop.wav` for Basin/Meadow, Fernwood, and Ridge respectively. These are candidates, not approved event mappings.
3. Add selected samples behind the existing `SoundFeedback` methods in `sound_feedback.gd`, preserving event callers and procedural fallback for unfilled cues. Match perceived loudness and cap simultaneous playback; ambient emitters belong to chunk lifecycles and must fade/stop on unload.
4. Preserve saved effects-volume behavior; introduce ambience control with backward-compatible defaults and mute tests. Add music controls only when actual music is selected. Verify loops for seams and prevent duplicate ambience at borders.
5. Exclude distress, horror, gunfire, and harsh realistic impacts from the shortlist. Footsteps, eating, dinosaur calls, and gentle combat cues still need suitable recordings or original synthesis; this pack does not establish those gaps as solved.
6. Gate: event playback, mute, pause, and chunk cleanup pass targeted checks; a listening review confirms comfortable levels and no frightening content. Keep visual feedback usable with audio muted.

#### B1 — Validate authoring tools before adopting them

1. Test tools in an isolated prototype using the project's Godot version and Compatibility renderer. No editor plugins are currently enabled in `project.godot`; native GDExtensions may still be discovered, so include extension-loading errors in startup validation.
2. Trial ProtonScatter on one dressed chunk only. Adopt it only if authored output preserves deterministic placement, MultiMesh efficiency, chunk ownership, and reliable reload/export; otherwise keep existing generation.
3. Compare Terrain3D and TerraBrush only against a concrete terrain-authoring need. Verify Windows extension loading, renderer support, collision/height sampling, navigation baking, chunk borders, export, and measured cost before selecting one. A renderer change requires a separate decision and hardware comparison.
4. Any terrain migration must replace the visible mesh, collision, and `main.gd` terrain-height consumers together, including food, actors, recovery, and quest markers. Preserve chunk IDs/state and safe routes. Retain the current terrain until this gate passes; the packs themselves supply scenery, not a complete terrain/navigation replacement.
5. Gate: repeated four-chunk crossings preserve actor/quest state, scenery counts, ground alignment, and the milestone B performance budget. Record the adopted tool/version or the decision to retain current code.

#### C/D — Expand the approved kit across the reserve

| Biome | Asset treatment | Remaining authored work |
| --- | --- | --- |
| River Wetlands | Quaternius ferns, grasses, pebbles; selected KayKit rocks/bushes | Readable riverbanks, shallow-water edges, routes and wetland landmark |
| Sunstone Ridge | KayKit angular rocks; Quaternius rock paths and sparse pines | Traversable switchbacks, skyline arch/overlook, race clearances |
| Redstone Badlands | Recolored KayKit rock families; sparse Quaternius dead/twisted trees | Terraces, rival arena, safe resting point and navigation |
| Ancient Meadow | KayKit broad trees and bushes; restrained Quaternius clover/flowers | Nest/herd landmarks and clear food habitats |

Approve one biome at gameplay camera distance before distributing its kit to additional chunks. Preserve the art bible, LOD/visibility limits, saved chunk state, and population budgets. These packs reduce vegetation/rock production; they do not replace dinosaur rigs/animations, UI art, nests/fossils, authored terrain, quests, or water work. Finish all six biome gates and 16 chunk layouts before declaring D complete.

#### E — Presentation and shipping acceptance

1. If needed, trial Sky3D with fixed daylight and reduced cloud motion, using its local Compatibility-renderer guidance. Retain the current environment if readability or frame cost regresses. Test low/medium/high settings before adding a dynamic cycle.
2. Profile scenery draw calls, foliage overdraw, shadows, texture memory, native add-ons, audio concurrency, and chunk load time on both Windows hardware tiers. Set density and visibility limits from measurements.
3. Audit exported dependencies and credits: selected model textures/buffers and required notices are included; unused packs, previews, demos, editor-only tooling, and archive metadata are excluded without breaking runtime references.
4. Run existing automated tests, headless startup, packaged-build route checks, controller/accessibility checks, and the planned Endless soak. Add targeted checks for asset loads, missing-asset fallback, audio settings, and repeated chunk cleanup as each feature lands. Only then mark the corresponding A–E gates complete.

#### Milestone A — Polished vertical slice

- Execute asset steps A1–A3 above: curate imports, dress Nest Basin/Fernwood, and introduce approved audio.
- Finish the shared UI theme, HUD hierarchy, onboarding, target feedback, and selection screen.
- Replace placeholder root animations for the T. rex with a proper rig and animation tree.
- Art-pass Nest Basin and one adjacent biome.
- Complete and playtest the T. rex Adventure at target quality.

Gate: a new player can finish the T. rex Adventure without developer guidance; HUD remains readable across both biomes; the packaged build maintains 60 FPS on the target Windows test machine.

#### Milestone B — Scalable world foundation

- Execute asset step B1 above before adopting scatter or terrain tooling.
- Implement chunk profiles, streaming, navigation-region borders, actor persistence, and loading feedback.
- Expand from 60×60 meters to a four-chunk 300×300-meter prototype.
- Convert vegetation to MultiMesh batches and establish LOD/visibility settings.

Gate: cross all chunk borders repeatedly without visible holes, navigation loss, duplicate actors, quest loss, or frame-time spikes above the agreed budget.

#### Milestone C — Existing roster polish

- Apply the approved biome kits using the C/D asset table above for the first four biomes.
- Finish production models and animations for Velociraptor and Triceratops.
- Complete their Adventures, finales, tutorials, cosmetics, and Endless unlocks.
- Complete the first four final-quality biomes.

Gate: all three Adventures pass clean-save, defeat-recovery, gamepad, and accessibility playtests.

#### Milestone D — Expanded roster and full reserve

- Complete the C/D asset rollout across all six biomes and 16 authored chunk layouts.
- Add Ankylosaurus, Parasaurolophus, and Carnotaurus using data-driven resources.
- Complete all 16 world chunks and six biomes.
- Add field-guide discovery, expanded quest templates, and biome population simulation.

Gate: all six species can complete Adventure; no species-specific central-loop conditionals are required; the reserve supports a 60-minute Endless session without resource exhaustion.

#### Milestone E — Release candidate

- Complete asset step E above, including optional sky evaluation, export dependency checks, and license/credits verification.
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
