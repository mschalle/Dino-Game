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
- Lightweight procedural sounds for food, abilities, growth, quests, and warnings.
- Automated gameplay-state checks and headless startup validation.

## Current Milestone: Playtest and Balance

Goal: make a first Adventure run understandable, forgiving, and enjoyable for children and families.

- Play one full Adventure run with each species.
- Check that the first food source is easy to find and safely reachable.
- Measure time spent at each growth stage using the saved run summary.
- Tune food locations, hunger drain, predator awareness, damage, and quest rewards based on the runs.
- Verify all HUD text is readable over every valley area.
- Verify gamepad-only play through selection, movement, eating, abilities, pause, and completion.

## Next Milestone: Content and Polish

Goal: make the single valley feel richer without expanding into a second map.

- Add simple animated plant clusters, clouds, and ambient particles.
- Add more friendly landmark props around quest destinations.
- Add a visual cosmetic selector for unlocked colors and badges.
- Add an in-game help panel with the basic loop, food rules, controls, and each dinosaur's abilities.
- Add accessibility options for master volume, music/effects volume, screen shake, and color contrast.
- Replace procedural placeholder tones with licensed or original child-friendly audio when assets are available.

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
