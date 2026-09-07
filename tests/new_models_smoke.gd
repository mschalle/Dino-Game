extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for species in ["t_rex", "velociraptor", "triceratops", "ankylosaurus"]:
		var actor := PlayerDino.new()
		actor.configure(DinosaurProfiles.by_id(species))
		root.add_child(actor)
		actor.set_physics_process(false)
		verify(actor.imported_model != null, species + " imports")
		verify(actor.imported_native_animations, species + " uses skeletal clips")
		if actor.imported_model != null:
			var expected_path := "res://assets/models/dinosaurs/%s.glb" % species
			if species == "t_rex":
				expected_path = "res://assets/models/dinosaurs/t_rex_hero.glb"
			elif species == "velociraptor" and ResourceLoader.exists("res://assets/models/dinosaurs/local_downloads/pbr_velociraptor_animated.glb"):
				expected_path = "res://assets/models/dinosaurs/local_downloads/pbr_velociraptor_animated.glb"
			verify(actor.imported_model.scene_file_path == expected_path, species + " uses the selected replacement")
			var bounds := actor._visual_bounds(actor.imported_model)
			verify(absf(bounds.position.y) < 0.1, species + " grounded")
			if not expected_path.ends_with("/pbr_velociraptor_animated.glb"):
				verify(bounds.size.y > 1.5 and bounds.size.y < 2.2, species + " normalized")
			# The downloaded rig's bind AABB differs from its visible skinned pose;
			# downloaded_raptor_smoke checks rendered scale and grounding instead.
		for clip in actor._required_animation_names():
			verify(actor.imported_animation_player.has_animation(clip), species + " " + clip)
			actor.play_reaction(clip)
			await process_frame
		actor.free()
	print("New dinosaur models: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func verify(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
