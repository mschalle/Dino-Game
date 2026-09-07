---
name: roar-rise-dinosaur-modeler
description: Research dinosaur anatomy and growth, then author, rig, animate, export and integrate evidence-based realistic Blender models for Roar & Rise. Use for dinosaur reconstruction, real-world scale, fluid skeletal animation, GLB integration or pipeline diagnosis; not environment props.
---

# Roar & Rise: evidence to playable dinosaur

Produce naturalistic, anatomically convincing dinosaurs with fluid skeletal motion and evidence-based dimensions. A skill structures research and iteration; it does not turn papers into finished art automatically. Do not substitute primitive assemblies, smooth shading alone, increased polygon counts or clip-name checks for the requested realism.

## Scope and project truth

- Read applicable repository instructions, `MODEL_PIPELINE.md`, target profiles, loader, growth/camera/collision consumers and relevant tests. Inspect dirty assets and generators; preserve unrelated work.
- Identify replacement player, replacement NPC or library asset. Model work does not authorize new playable species, quests, saves, purchases or gameplay rebalance.
- Read [research and acceptance](references/research-and-acceptance.md) for research, reconstruction, scale or animation work. Read [integration contract](references/roar-rise-contract.md) before exporting or integrating.
- Follow the user's current visual direction: naturalistic realism, not the obsolete toy-like/kid-friendly restriction. Keep gore separate from anatomical realism: default Off, with optional restrained blood/injury presentation when settings implementation is in scope. Off retains believable motion, sound cues, hit readability and reward clarity. Extreme gore and dismemberment remain outside approved scope; do not add them under a quality upgrade.
- For integration-only requests, inspect supplied assets without claiming scientific accuracy or silently redesigning them. For research-only requests, produce the dossier without modifying the game.

## Research to dimensions

Create a versioned species dossier in `docs/dinosaurs/<species-id>.md` with dated sources, specimen identity, evidence confidence, measurement definitions and chosen reconstruction. Browse current primary literature and museum specimen records; check corrections and taxonomic reassessments. Track conflicting interpretations rather than selecting whichever gives convenient proportions.

Separate directly preserved anatomy, published reconstruction, biomechanical inference and artistic choice. Do not copy copyrighted meshes, scans or textures merely because they are publicly viewable. Record asset licenses independently from research citations.

Choose a documented specimen or defensible range, not a universal species size. Record total length, hip height, skull length and stage-specific proportions in metres. Juveniles need age-appropriate anatomy, not just uniformly shrunken adults. Label poorly known juvenile or hatchling dimensions as estimates; game growth stages are not fossil age determinations.

## Author and animate

Use the dossier as a modeling specification: skeleton landmarks, silhouette and mass distribution first; connected deformable anatomy, retopology and materials next. Preserve `.blend` or reproducible source alongside exported assets. Use current project budgets as ceilings, not evidence of visual quality. Smooth normals and baked detail must not hide a crude silhouette.

Build weighted deformation around jaw, neck, hips, knees, ankles, shoulders and tail. Validate clean weights and rest pose. Shared rigs may be reused only when proportions and joint behavior remain appropriate. Generate in isolated Blender scenes or modify only generator-owned objects; never clear unrelated work.

Author native Idle, Walk, Run, Attack, Eat, Hit, Defeat and species ability clips, plus turn/stagger motions when required by the task. Tune stance/swing timing, foot contact, weight transfer, tail counterbalance, transitions and recoil. A renamed Attack is a compatibility fallback, not an accepted bespoke PowerBite. Root wobble is not skeletal animation.

Match stride displacement and cycle duration to actual gameplay speed; separate researched locomotion estimates from game tuning. Use in-place or root motion according to the existing controller, never both. Test acceleration, braking, reverse movement and turns using current mouse controls. Respect Reduced Motion for secondary effects without removing essential locomotion.

## Integrate without losing scale

Use one Blender metre = one Godot unit, export Y-up, and document orientation and measurement pose. Export staged GLBs first. Preserve accepted assets and fallbacks until candidate validation succeeds.

Prevent generic-height normalization from erasing researched species differences. When a scale migration is authorized, use explicit species/stage dimensions and coordinate model, collision, floor snap, navigation clearance, camera and attack reach. Do not silently shrink a historically sized adult to fit a route or enlarge combat range to match a longer mesh. Report necessary gameplay tradeoffs for approval.

Retain imported native clips; repair track paths and animation blending, not warnings. Keep existing identifiers, save behavior and missing-asset fallback. Do not replace a superior accepted asset merely because a new file is newer.

## Acceptance and handoff

Advance through dossier -> measured silhouette -> deformation/locomotion -> surfaced candidate -> in-game validation. For an implementation request, continue across gates when evidence supports it; pause only for a meaningful missing choice, authority or unresolvable quality blocker.

Run structural/scale checks, rendered motion checks and actual Adventure movement/combat/fallback checks as specified in the reference. Inspect clips in motion, not just screenshots. Preserve the prior realistic benchmark's tests when adding lower-quality alternatives; never weaken assertions to certify a different quality level.

Update `PROJECT_PLAN.md` with sources, changed assets, measurements, validation evidence and remaining manual checks. Report research confidence separately from art readiness. If visual or motion review fails, keep the candidate unaccepted and state why; export success is not completion.
