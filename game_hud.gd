class_name GameHUD
extends CanvasLayer

signal resume_requested
signal restart_requested
signal selection_requested

var title_label: Label
var quest_label: Label
var abilities_label: Label
var message_label: Label
var health_bar: ProgressBar
var hunger_bar: ProgressBar
var energy_bar: ProgressBar
var growth_bar: ProgressBar
var pause_panel: ColorRect
var completion_panel: ColorRect
var help_panel: ColorRect
var target_panel: ColorRect
var target_label: Label
var diagnostics_label: Label
var diagnostics_enabled := true
var frame_samples: Array[float] = []
var target_health_bar: ProgressBar
var target_timer := 0.0
var large_text_enabled := true
var high_contrast_enabled := false
var status_backdrop: ColorRect
var quest_backdrop: ColorRect
var message_backdrop: ColorRect
var controls_backdrop: ColorRect

func _ready() -> void:
	_apply_ui_settings({})
	_create_status_panel()
	_create_pause_panel()
	_create_completion_panel()
	_create_help_panel()
	_create_target_panel()
	get_viewport().size_changed.connect(_layout_for_viewport)
	_layout_for_viewport()

func apply_ui_settings(settings: Dictionary) -> void:
	large_text_enabled = bool(settings.get("large_text", true))
	high_contrast_enabled = bool(settings.get("high_contrast", false))
	_apply_ui_settings(settings)
	_apply_accessibility_style()

func _apply_ui_settings(settings: Dictionary) -> void:
	var scale := 1.0
	if not settings.is_empty():
		scale = clampf(float(settings.get("ui_scale", 1.0)), 1.0, 1.75)
	get_tree().root.content_scale_factor = scale

func _apply_accessibility_style() -> void:
	var font_scale := 1.15 if large_text_enabled else 1.0
	var outline := 6 if high_contrast_enabled else 4
	for node in _all_controls(self):
		if node is Label:
			var label := node as Label
			var current_size := int(label.get_theme_font_size("font_size"))
			if current_size > 0:
				label.add_theme_font_size_override("font_size", maxi(14, int(float(current_size) * font_scale)))
			label.add_theme_constant_override("outline_size", outline)
			if high_contrast_enabled:
				label.add_theme_color_override("font_color", Color.WHITE)
		if node is Button and high_contrast_enabled:
			(node as Button).add_theme_color_override("font_color", Color.WHITE)

func _layout_for_viewport() -> void:
	if status_backdrop == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var width := viewport_size.x
	var height := viewport_size.y
	var margin := maxf(16.0, width * 0.018)
	var compact := width < 1120.0
	status_backdrop.size.x = 470.0 if compact else 530.0
	quest_backdrop.size.x = 430.0 if compact else 524.0
	quest_label.size.x = quest_backdrop.size.x - 24.0
	quest_label.add_theme_font_size_override("font_size", 17 if compact else 20)
	status_backdrop.position = Vector2(margin, margin)
	quest_backdrop.position = Vector2(maxf(margin, width - quest_backdrop.size.x - margin), margin)
	target_panel.position = Vector2(maxf(margin, (width - target_panel.size.x) * 0.5), margin + 118.0)
	message_backdrop.position = Vector2(maxf(margin, (width - message_backdrop.size.x) * 0.5), maxf(300.0, height - 110.0))
	controls_backdrop.position = Vector2(margin, maxf(360.0, height - 46.0))
	controls_backdrop.size.x = maxf(320.0, width - margin * 2.0)

func _all_controls(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_all_controls(child))
	return result

func _process(delta: float) -> void:
	if target_timer > 0.0:
		target_timer -= delta
		if target_timer <= 0.0 and target_panel != null:
			target_panel.visible = false

func update_view(session: GameSession, player: PlayerDino, quest_system: QuestSystem, cooldown_text: String) -> void:
	title_label.text = "%s  •  %s  •  %s" % [session.profile.display_name, session.growth.stage_name(), session.mode.capitalize()]
	health_bar.max_value = session.profile.max_health
	health_bar.value = session.health
	hunger_bar.value = session.hunger
	energy_bar.max_value = player.max_energy
	energy_bar.value = player.energy
	growth_bar.value = session.growth.progress_to_next_stage() * 100.0
	var objective_heading := "ENDLESS CHALLENGE" if session.mode == "endless" else "MAIN QUEST"
	var skip_hint := "\nK / RB: Skip without reward" if session.mode == "endless" else ""
	quest_label.text = "%s\n%s%s" % [objective_heading, quest_system.progress_text(), skip_hint]
	abilities_label.text = "%s\n%s" % [session.profile.ability_summary(session.growth.stage_index), cooldown_text]

func update_diagnostics(metrics: Dictionary) -> void:
	if diagnostics_label == null:
		return
	diagnostics_label.visible = diagnostics_enabled
	if not diagnostics_enabled:
		return
	var npc_count := int(metrics.get("npc_count", 0))
	var average_frame_ms := _average_frame_ms()
	var performance_warning := "  SLOW" if average_frame_ms > 20.0 else ""
	var biome_text := format_active_biomes(metrics.get("active_biomes", []))
	diagnostics_label.text = "DEV  %s (%d)\nChunks %d  Scenes %d  Landmarks %d  NPCs %d/25  Budget %.0f%%  %.1fms%s\nEnv %s  Weather %s  Daylight %s" % [biome_text, int(metrics.get("active_biome_count", 0)), int(metrics.get("active_chunks", 0)), int(metrics.get("loaded_chunk_scenes", 0)), int(metrics.get("loaded_landmarks", 0)), npc_count, float(metrics.get("population_utilization", 0.0)) * 100.0, average_frame_ms, performance_warning, str(metrics.get("environment_quality", "medium")).to_upper(), "ON" if bool(metrics.get("weather_enabled", true)) else "OFF", "ON" if bool(metrics.get("day_cycle_enabled", true)) else "OFF"]
	diagnostics_label.modulate = Color("#ffcf70") if npc_count >= 20 or average_frame_ms > 20.0 else Color("#b8e6ef")

func format_active_biomes(raw_biomes: Variant) -> String:
	if not raw_biomes is Array:
		return "—"
	var active_biomes: Array = raw_biomes
	if active_biomes.is_empty():
		return "—"
	var visible_biomes: Array[String] = []
	for biome in active_biomes.slice(0, mini(active_biomes.size(), 2)):
		if biome is String and not biome.is_empty():
			visible_biomes.append(biome)
	if visible_biomes.is_empty():
		return "—"
	var biome_text := ", ".join(visible_biomes)
	if active_biomes.size() > 2:
		biome_text += " +%d" % (active_biomes.size() - 2)
	return biome_text

func record_frame_time(delta: float) -> void:
	frame_samples.append(maxf(0.0, delta * 1000.0))
	if frame_samples.size() > 30:
		frame_samples.pop_front()

func _average_frame_ms() -> float:
	if frame_samples.is_empty():
		return 0.0
	var total := 0.0
	for sample in frame_samples:
		total += sample
	return total / float(frame_samples.size())

func set_diagnostics_enabled(enabled: bool) -> void:
	diagnostics_enabled = enabled
	if diagnostics_label != null:
		diagnostics_label.visible = enabled

func show_message(text: String) -> void:
	message_label.text = text

func show_target(target_name: String, tier: int, health: float, maximum: float) -> void:
	target_label.text = "%s  •  Tier %d" % [target_name, tier]
	target_health_bar.max_value = maximum
	target_health_bar.value = health
	target_panel.visible = true
	target_timer = 3.0

func update_target_health(health: float, maximum: float) -> void:
	if target_panel == null or not target_panel.visible:
		return
	target_health_bar.max_value = maximum
	target_health_bar.value = health

func _create_target_panel() -> void:
	target_panel = ColorRect.new()
	target_panel.color = Color(0.04, 0.1, 0.16, 0.9)
	target_panel.position = Vector2(465, 24)
	target_panel.size = Vector2(350, 72)
	target_panel.visible = false
	add_child(target_panel)
	target_label = Label.new()
	target_label.position = Vector2(10, 5)
	target_label.size = Vector2(330, 26)
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_text(target_label, Color.WHITE, 4)
	target_panel.add_child(target_label)
	target_health_bar = ProgressBar.new()
	target_health_bar.position = Vector2(20, 38)
	target_health_bar.size = Vector2(310, 22)
	target_health_bar.show_percentage = true
	target_panel.add_child(target_health_bar)

func set_paused(visible: bool) -> void:
	pause_panel.visible = visible

func toggle_help() -> void:
	if help_panel != null:
		help_panel.visible = not help_panel.visible

func _create_help_panel() -> void:
	help_panel = ColorRect.new()
	help_panel.color = Color(0.03, 0.1, 0.16, 0.97)
	help_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	help_panel.visible = false
	add_child(help_panel)
	var heading := Label.new()
	heading.text = "HOW TO PLAY"
	heading.position = Vector2(390, 105)
	heading.size = Vector2(500, 60)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 36)
	_style_text(heading, Color("#fff3a6"), 5)
	help_panel.add_child(heading)
	var body := Label.new()
	body.text = "Explore the naturalistic valley and follow the MAIN QUEST marker.\n\nEat the food your dinosaur likes to restore Hunger and earn Growth Points.\nGrow from Hatchling to Adult to unlock stronger abilities.\n\nSmall dinosaurs flee, larger predators warn and may attack, and the safe nest restores you after a defeat.\nCombat uses readable impact feedback without extreme gore.\n\nWASD / Left Stick: Move    Shift: Sprint\nLeft Click / X: Eat    Right Click / B: Primary Ability\nQ / LB: Scent Trail    Space / A: Dash    R / Y: Special Ability\nF2/F3: Effects volume    F4: Environment quality    F5: Weather    F6: Reduced motion    F7: Daylight cycle    Esc / Start: Pause    F1: Close this guide"
	body.position = Vector2(340, 190)
	body.size = Vector2(600, 390)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 20)
	_style_text(body, Color("#ffffff"), 4)
	help_panel.add_child(body)

func show_completion(title: String, details: String) -> void:
	completion_panel.visible = true
	var heading := completion_panel.get_node("Heading") as Label
	var body := completion_panel.get_node("Body") as Label
	heading.text = title
	body.text = details

func _create_status_panel() -> void:
	status_backdrop = ColorRect.new()
	status_backdrop.color = Color(0.04, 0.1, 0.16, 0.84)
	status_backdrop.position = Vector2(18, 16)
	status_backdrop.size = Vector2(530, 238)
	add_child(status_backdrop)
	title_label = Label.new()
	title_label.position = Vector2(18, 12)
	title_label.size = Vector2(490, 28)
	title_label.add_theme_font_size_override("font_size", 20)
	_style_text(title_label)
	status_backdrop.add_child(title_label)
	health_bar = _make_bar(status_backdrop, "Health", Vector2(18, 50), Color("#ef6b6b"))
	hunger_bar = _make_bar(status_backdrop, "Hunger", Vector2(18, 85), Color("#f4c95d"))
	energy_bar = _make_bar(status_backdrop, "Energy", Vector2(18, 120), Color("#63d4ed"))
	growth_bar = _make_bar(status_backdrop, "Growth", Vector2(18, 155), Color("#8bd66f"))
	abilities_label = Label.new()
	abilities_label.position = Vector2(18, 192)
	abilities_label.size = Vector2(495, 42)
	abilities_label.add_theme_font_size_override("font_size", 14)
	_style_text(abilities_label, Color("#eaf6ff"), 3)
	status_backdrop.add_child(abilities_label)
	quest_backdrop = ColorRect.new()
	quest_backdrop.color = Color(0.04, 0.1, 0.16, 0.88)
	quest_backdrop.position = Vector2(738, 12)
	quest_backdrop.size = Vector2(524, 100)
	add_child(quest_backdrop)
	quest_label = Label.new()
	quest_label.position = Vector2(12, 8)
	quest_label.size = Vector2(500, 84)
	quest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quest_label.add_theme_font_size_override("font_size", 20)
	_style_text(quest_label, Color("#ffffff"), 4)
	quest_backdrop.add_child(quest_label)
	message_backdrop = ColorRect.new()
	message_backdrop.color = Color(0.04, 0.1, 0.16, 0.86)
	message_backdrop.position = Vector2(95, 610)
	message_backdrop.size = Vector2(1090, 62)
	add_child(message_backdrop)
	message_label = Label.new()
	message_label.position = Vector2(10, 8)
	message_label.size = Vector2(1070, 46)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 22)
	_style_text(message_label, Color("#fff3a6"), 5)
	message_backdrop.add_child(message_label)
	diagnostics_label = Label.new()
	diagnostics_label.position = Vector2(930, 12)
	diagnostics_label.size = Vector2(330, 46)
	diagnostics_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	diagnostics_label.add_theme_font_size_override("font_size", 14)
	diagnostics_label.text = "DEV  Metrics initializing"
	add_child(diagnostics_label)
	controls_backdrop = ColorRect.new()
	controls_backdrop.color = Color(0.02, 0.06, 0.1, 0.92)
	controls_backdrop.position = Vector2(30, 674)
	controls_backdrop.size = Vector2(1220, 38)
	add_child(controls_backdrop)
	var controls := Label.new()
	controls.text = "WASD / Stick: Move    Shift: Sprint    Left Click: Eat    Right Click: Ability    Q: Scent    Space: Dash    R: Special    F4: Quality    F5: Weather    F6: Motion    F7: Daylight    Esc: Pause"
	controls.position = Vector2(10, 5)
	controls.size = Vector2(1200, 28)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 15)
	_style_text(controls, Color("#ffffff"), 3)
	controls_backdrop.add_child(controls)

func _make_bar(parent: Control, label_text: String, position_value: Vector2, tint: Color) -> ProgressBar:
	var label := Label.new()
	label.text = label_text
	label.position = position_value
	label.size = Vector2(75, 25)
	_style_text(label, Color("#ffffff"), 3)
	parent.add_child(label)
	var bar := ProgressBar.new()
	bar.position = position_value + Vector2(78, 1)
	bar.size = Vector2(400, 22)
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = true
	bar.add_theme_color_override("font_color", Color("#101820"))
	bar.add_theme_color_override("font_outline_color", Color("#ffffff"))
	bar.add_theme_constant_override("outline_size", 2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = tint
	fill.corner_radius_top_left = 7
	fill.corner_radius_top_right = 7
	fill.corner_radius_bottom_left = 7
	fill.corner_radius_bottom_right = 7
	bar.add_theme_stylebox_override("fill", fill)
	parent.add_child(bar)
	return bar

func _create_pause_panel() -> void:
	pause_panel = ColorRect.new()
	pause_panel.name = "PausePanel"
	pause_panel.color = Color(0.02, 0.05, 0.08, 0.94)
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel.visible = false
	add_child(pause_panel)
	var heading := Label.new()
	heading.text = "PAUSED"
	heading.position = Vector2(490, 170)
	heading.size = Vector2(300, 60)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 38)
	_style_text(heading, Color("#ffffff"), 5)
	pause_panel.add_child(heading)
	_add_menu_button(pause_panel, "Resume", Vector2(490, 260), func() -> void: resume_requested.emit())
	_add_menu_button(pause_panel, "Restart Run", Vector2(490, 330), func() -> void: restart_requested.emit())
	_add_menu_button(pause_panel, "Dinosaur Selection", Vector2(490, 400), func() -> void: selection_requested.emit())

func _create_completion_panel() -> void:
	completion_panel = ColorRect.new()
	completion_panel.color = Color(0.03, 0.12, 0.13, 0.96)
	completion_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	completion_panel.visible = false
	add_child(completion_panel)
	var heading := Label.new()
	heading.name = "Heading"
	heading.position = Vector2(290, 160)
	heading.size = Vector2(700, 70)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 38)
	_style_text(heading, Color("#ffffff"), 5)
	completion_panel.add_child(heading)
	var body := Label.new()
	body.name = "Body"
	body.position = Vector2(290, 250)
	body.size = Vector2(700, 130)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 21)
	_style_text(body, Color("#ffffff"), 4)
	completion_panel.add_child(body)
	_add_menu_button(completion_panel, "Return to Selection", Vector2(490, 430), func() -> void: selection_requested.emit())

func _add_menu_button(parent: Control, text_value: String, position_value: Vector2, callback: Callable) -> void:
	var button := Button.new()
	button.text = text_value
	button.position = position_value
	button.size = Vector2(300, 52)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 20)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#28485a")
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color("#7aa8ba")
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	var focus := normal.duplicate()
	focus.bg_color = Color("#e8bd72")
	focus.border_color = Color.WHITE
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", focus)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color("#102532"))
	button.add_theme_color_override("font_focus_color", Color("#102532"))
	button.pressed.connect(callback)
	parent.add_child(button)

func _style_text(label: Label, color: Color = Color.WHITE, outline_size: int = 4) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#101820"))
	label.add_theme_constant_override("outline_size", outline_size)
