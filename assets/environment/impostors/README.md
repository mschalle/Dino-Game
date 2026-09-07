# Distant tree impostors

Three 512-pixel transparent captures of the existing Quaternius CommonTree variants (CC0; see `License_Standard.txt`). These are derivative renders of the selected licensed assets, not newly sourced art. PNG files are previews; runtime QuadMesh resources embed mipmapped textures.

Regenerate with Godot console (rendering required): `--path . --script res://tools/bake_tree_impostors.gd`.

Cards preserve normalized tree height and use fixed-Y, scale-preserving billboards, alpha scissor and baked unshaded color. Only distant chunks use them; nearby chunks retain source geometry. No shadows, collision, navigation or wildlife are added. Missing/stale cards fall back to normalized geometry and its existing procedural fallback. Runtime freshness uses local modification-time/size stamps; the validation gate checks full source-content hashes. Rebake stamps after a fresh checkout if needed. Compiled exports require pre-export validation.

This single-view technique is appropriate for distant silhouettes, not close inspection. It does not provide multi-angle parallax or dynamically relit bark. Final biome art and transition review remain separate acceptance gates.
