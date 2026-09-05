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
var target_health_bar: ProgressBar
var target_timer := 0.0

func _ready() -> void:
	_create_status_panel()
	_create_pause_panel()
	_create_completion_panel()
	_create_help_panel()
	_create_target_panel()

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
	quest_label.text = "MAIN QUEST\n%s" % quest_system.progress_text()
	abilities_label.text = "%s\n%s" % [session.profile.ability_summary(session.growth.stage_index), cooldown_text]

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
	body.text = "Explore the bright valley and follow the MAIN QUEST marker.\n\nEat the food your dinosaur likes to restore Hunger and earn Growth Points.\nGrow from Hatchling to Adult to unlock stronger abilities.\n\nSmall dinosaurs flee, larger dinosaurs may bump you, and the safe nest restores you after a defeat.\nThere is no graphic violence.\n\nWASD / Left Stick: Move    Shift: Sprint\nLeft Click / X: Eat    Right Click / B: Primary Ability\nQ / LB: Scent Trail    Space / A: Dash    R / Y: Special Ability\nF2/F3: Effects volume    Esc / Start: Pause    F1: Close this guide"
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
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.04, 0.1, 0.16, 0.84)
	backdrop.position = Vector2(18, 16)
	backdrop.size = Vector2(530, 238)
	add_child(backdrop)
	title_label = Label.new()
	title_label.position = Vector2(18, 12)
	title_label.size = Vector2(490, 28)
	title_label.add_theme_font_size_override("font_size", 20)
	_style_text(title_label)
	backdrop.add_child(title_label)
	health_bar = _make_bar(backdrop, "Health", Vector2(18, 50), Color("#ef6b6b"))
	hunger_bar = _make_bar(backdrop, "Hunger", Vector2(18, 85), Color("#f4c95d"))
	energy_bar = _make_bar(backdrop, "Energy", Vector2(18, 120), Color("#63d4ed"))
	growth_bar = _make_bar(backdrop, "Growth", Vector2(18, 155), Color("#8bd66f"))
	abilities_label = Label.new()
	abilities_label.position = Vector2(18, 192)
	abilities_label.size = Vector2(495, 42)
	abilities_label.add_theme_font_size_override("font_size", 14)
	_style_text(abilities_label, Color("#eaf6ff"), 3)
	backdrop.add_child(abilities_label)
	var quest_backdrop := ColorRect.new()
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
	var message_backdrop := ColorRect.new()
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
	var controls_backdrop := ColorRect.new()
	controls_backdrop.color = Color(0.02, 0.06, 0.1, 0.92)
	controls_backdrop.position = Vector2(30, 674)
	controls_backdrop.size = Vector2(1220, 38)
	add_child(controls_backdrop)
	var controls := Label.new()
	controls.text = "WASD / Stick: Move    Shift: Sprint    Left Click: Eat    Right Click: Ability    Q: Scent    Space: Dash    R: Special    Esc: Pause"
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
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(callback)
	parent.add_child(button)

func _style_text(label: Label, color: Color = Color.WHITE, outline_size: int = 4) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#101820"))
	label.add_theme_constant_override("outline_size", outline_size)
