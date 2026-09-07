# Research dossier and acceptance gates

## Dossier content

Record species ID, taxon, intended role, date researched, geological time/location and target life stage. For every consequential claim give URL/DOI, publication date, specimen/catalog identifier when applicable, figure/table/page, measurement method and confidence. Mark facts as preserved, reconstructed, inferred or artistic. Record disagreements, corrections and how the selected reconstruction handles them. Do not imply that a mixed-time game roster is a historically coexisting ecosystem.

Use a measurement table with: stage; specimen or inference; total length; hip height; skull length; range/uncertainty; selected target; source. Define straight-line versus skeletal-curve length, neutral standing hip height versus pose-dependent head height, and bone length versus restored soft-tissue dimensions. Record original units and conversions. Do not infer mass directly from a visual bounding box.

Specify anatomical landmarks and ratios, skin/feather evidence by body region, plausible soft tissues, palette choices, joint constraints and locomotion evidence. Unknown color, calls or exact gait must remain marked as choices, not discoveries. Related living animals can guide mechanics but cannot establish exact extinct behavior.

## Research starting points, not frozen truth

Recheck these when reconstructing T. rex; they are not a complete species dossier:

- Smithsonian size overview: https://www.si.edu/newsdesk/releases/smithsonian-s-national-museum-natural-history-welcomes-t-rex (2013). About 40 feet is a broad length reference, not a precise juvenile scaling curve or a universal specimen measurement.
- Zanno and Napoli, 2025, *Nanotyrannus and Tyrannosaurus coexisted at the close of the Cretaceous*: https://doi.org/10.1038/s41586-025-09801-6 ; publisher correction https://doi.org/10.1038/s41586-026-10185-4 . Reassess specimens previously treated as juvenile T. rex rather than blindly reusing their dimensions.
- Woodward et al., 2020, *Growing up Tyrannosaurus rex*: https://pmc.ncbi.nlm.nih.gov/articles/PMC6938697/ . Historical contrasting interpretation; evaluate against subsequent evidence, not as the sole juvenile authority.
- Van Bijlert et al., 2021, *Natural Frequency Method*: https://doi.org/10.1098/rsos.201441 . Preferred walking-speed model with assumptions and sensitivity, not proof of maximum running speed or exact gait animation.

If a source is inaccessible, use accessible primary alternatives or explicitly narrow the claim. Search summaries alone do not support precise specimen measurements. Scientific access does not grant commercial asset rights.

## Model and scale gate

- Orthographic side/front/top captures against a metre grid; compare skull, pelvis, limb and tail landmarks to dossier ratios.
- Measure the exported mesh in a defined neutral pose and actual Godot stage transforms. Record source and imported units and the resulting length/hip height at every growth stage.
- Set numerical tolerances before measuring, based on the dossier's uncertainty and implementation precision. Separate import tolerance from biological uncertainty; do not loosen tolerances after a failure.
- Check foot grounding, orientation, material assignments, valid skin weights and acceptable deformation in extreme poses. Polygon count is a performance constraint, not anatomical evidence.
- Validate visible scale differences across species beside the same metre ruler and environmental landmarks. Avoid generic equal-height normalization.

## Fluid motion gate

- Review at least two complete Walk and Run loops from side, front and gameplay cameras, plus Idle-to-Walk-to-Run-to-stop, both turn directions, reverse movement and action transitions.
- Record clip length, intended speed, stride length, playback rate and planted-foot intervals. Measure world-space foot drift during stance, ground penetration, loop-boundary pose discontinuity and transition popping. Use declared tolerances appropriate to body size, not just nonzero vertex motion.
- Check contact and body weight on level ground and traversable slopes at juvenile and adult sizes. Verify no skin explosion, joint collapse, tail clipping or foot skating at normal play speed. Review a recorded sequence or live motion; sampled static poses alone cannot pass this gate.
- Test actual controller-driven movement and blending. Do not mask poor locomotion by slowing the game, teleporting actors, disabling physics or weakening animation tests.

## Game and delivery gate

Presentation direction: no child-friendly restriction. Author blood/injury as separable optional overlays or effects, never baked irreversibly into the base dinosaur. Gore Off is the default target. When the settings feature is requested, validate switching Off/Restrained live, persistence, old-save defaults, cleanup of existing blood effects, and unchanged combat/rewards. Do not claim this setting exists merely because the skill requires it. Extreme gore and dismemberment are not approved.

Run existing model and Adventure tests plus targeted candidate checks: selection, locomotion, turning, eating, ability, hits, defeat, growth, camera obstruction, slopes, quest route clearance and missing-asset fallback. Ensure no runtime or unresolved animation-track errors. Recheck save compatibility when relevant; do not change schema as part of art replacement.

Review normal-distance and close-up renders under gameplay lighting, including muted PBR surfaces and readable silhouettes. Record frame-time results at the actual renderer/quality/resolution on an uncontended GPU; do not treat CPU tests as performance proof. Require full-route and performance acceptance before broad roster rollout.

If evidence is missing, label the asset candidate/review-pending. Keep the prior accepted model available. A dossier and a passing structural test are intermediate deliverables, not a finished realistic dinosaur.
