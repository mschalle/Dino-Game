# Tyrannosaurus rex — reconstruction dossier v1

Research date: 2026-09-06. Role: replacement playable T. rex, no roster/save expansion. Status: original candidate construction; not final paleoart acceptance.

## Evidence and interpretation

| Source | Evidence used | Limit / modeling decision |
| --- | --- | --- |
| Field Museum, 2016, [How well do you know SUE?](https://www.fieldmuseum.org/blog/how-well-do-you-know-sue), size paragraph; specimen FMNH PR 2081 | Mounted adult length 40.5 ft, hip height 13 ft | Convert with 0.3048 m/ft: 12.3444 m and 3.9624 m. A mount/reconstruction, not exact living dimensions or a universal species size. Do not repeat its dated largest/oldest claims. |
| Cullen et al., 2023, Science 379, [facial reconstruction](https://doi.org/10.1126/science.abo7877), pp. 1348–1351, Fig. 1, [accessible author paper](https://palaeont.jlu.edu.cn/science.abo7877.pdf) | Dental and comparative evidence supports covering marginal teeth with soft tissue when the mouth is closed | Choose lipped jaws; lips themselves are reconstructed, not directly preserved in SUE. Use original geometry, not traced/downloaded art. |
| Bell et al., 2017, Biology Letters 13, [integument study](https://pubmed.ncbi.nlm.nih.gov/28592520/), abstract and Fig. 1 | Fossil scaly integument in tyrannosaurids including T. rex | Fine irregular scaly surface is supported for preserved regions. Coverage over the entire animal and juveniles is inference. Do not portray large decorative dorsal plates as established anatomy. Full PMC page was inaccessible in this session; no precise regional scale-size target is asserted from it. |
| Zanno & Napoli, 2025, [Nanotyrannus reassessment](https://doi.org/10.1038/s41586-025-09801-6), [2026 publisher correction](https://doi.org/10.1038/s41586-026-10185-4) | Current research challenges formerly assumed juvenile T. rex identities | Full primary article access failed; flag the reassessment, do not extract exact juvenile measurements from search snippets. Do not use Jane/Nanotyrannus as an unquestioned T. rex growth anchor. |
| Van Bijlert et al., 2021, [Natural Frequency Method](https://doi.org/10.1098/rsos.201441) | Biomechanical walking-speed estimates are model-dependent | Research pointer for later locomotion refinement; full text access failed this session. Current animation stride timings are game-art tuning, not a claim about fossil gait or maximum speed. |

SUE's source places it about 67 million years ago in what is now South Dakota. The game reserve is not a claim that the whole roster shared that location/time.

## Candidate dimensions and growth

Lengths below are selected straight neutral-pose snout-to-tail extents. Hip height is the authored hip-joint landmark above the sole plane, not the highest head vertex. Skull length is the designed occipital-to-snout span, not a new fossil measurement. No body-mass claim is inferred from mesh volume.

| Game stage | Length target (m) | Hip target (m) | Skull target (m) | Basis |
| --- | ---: | ---: | ---: | --- |
| Hatchling (legacy game label) | 4.8 | 1.60 | 0.60 | Early juvenile artistic estimate, **not a literal newly hatched animal** |
| Juvenile | 6.4 | 2.20 | 0.82 | Inferred reconstruction; no age assigned |
| Young Adult | 9.1 | 3.10 | 1.15 | Inferred transition, not a measured specimen |
| Adult | 12.3444 | 3.9624 | 1.50 | SUE-based length/hip target; skull target is an anatomical reconstruction choice |

There is no defensible confidence interval for the selected juvenile values from the inspected sources; do not invent one. These are explicit production estimates pending stronger juvenile evidence. Adult living soft tissue and posture add uncertainty beyond the museum mount. Technical acceptance: length within 2%, hip within 0.03 m, imported scale identity, and ground contact within 0.03 m in the neutral pose. These tolerances test implementation, not biological certainty.

Juveniles have a shallower/narrower skull and leaner trunk relative to length; adults have deeper jaws and a more robust trunk. Preserve a horizontal counterbalancing tail, digitigrade hindlimbs, three load-bearing toes and two inward-facing hand digits. Allometric changes must affect the authored shape, not just node scale.

## Surface and motion specification

Muted olive-brown dorsal coloration and a lighter underside are artistic choices. Eye color and sounds are unknown. Build clean base textures without blood; optional gore remains a separate future presentation feature. Skin folds follow neck/joint compression; no exposed anatomical skull cavities or toy spikes.

Native clips: Idle, Walk, Run, Attack, PowerBite, Eat, Hit, Stagger, Defeat, Roar, TurnLeft and TurnRight. PowerBite needs its own timing and recoil, not an alias. Use analytic leg solving with smooth swing endpoints, restrained breathing and progressive tail counterbalance. Record stage-specific stride speed and loop duration in exported metadata. Keep simulated walking speed distinct from biological claims.

Motion gates: at least two loops, loop endpoint joint-transform difference <=0.001; neutral foot-ground error <=0.03 m; stance-foot drift relative to expected travel <=0.04 m; no mesh collapse/explosion; play and inspect locomotion/action transitions. Dynamic slope contact, reverse motion, collision fit, camera and combat routes need actual Godot validation. A static beauty render cannot pass fluid-animation acceptance.

## Ownership and release

Candidate authoring reuses this project's original generator helpers and PBR baking pipeline, with revised geometry/rig/motion. All geometry/textures are original; no downloaded fossil scans or licensed third-party art is embedded. Export under `assets/models/dinosaurs/researched/`, preserve existing GLBs and sources. Do not promote a candidate until its measured/rendered gates pass.
