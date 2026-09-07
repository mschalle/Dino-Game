# Deterministic habitat layouts

Original placement data for the four starting habitats. These resources preserve the exact procedural positions, orientations, density prefixes and exclusions; no third-party geometry is included.

Regenerate with Godot console: `--headless --path . --script res://tools/bake_habitat_layouts.gd`.
After changing `jungle_habitat.gd` or `valley_terrain.gd`, regenerate terrain with `tools/bake_terrain.gd` and these layouts, then run roadmap validation. Runtime rejects missing/stale resources and generates layouts procedurally. Compiled exports without source files rely on version metadata and the pre-export validation gate, as terrain bakes do.
