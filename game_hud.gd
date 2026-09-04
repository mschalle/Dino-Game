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

func _ready() -> void:
	_create_status_panel()
	_create_pause_panel()
	_create_completion_panel()

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

func set_paused(visible: bool) -> void:
	pause_panel.visible = visible

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
	backdrop.add_child(title_label)
	health_bar = _make_bar(backdrop, "Health", Vector2(18, 50), Color("#ef6b6b"))
	hunger_bar = _make_bar(backdrop, "Hunger", Vector2(18, 85), Color("#f4c95d"))
	energy_bar = _make_bar(backdrop, "Energy", Vector2(18, 120), Color("#63d4ed"))
	growth_bar = _make_bar(backdrop, "Growth", Vector2(18, 155), Color("#8bd66f"))
	abilities_label = Label.new()
	abilities_label.position = Vector2(18, 192)
	abilities_label.size = Vector2(495, 42)
	abilities_label.add_theme_font_size_override("font_size", 14)
	backdrop.add_child(abilities_label)
	quest_label = Label.new()
	quest_label.position = Vector2(760, 18)
	quest_label.size = Vector2(495, 85)
	quest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quest_label.add_theme_font_size_override("font_size", 20)
	add_child(quest_label)
	message_label = Label.new()
	message_label.position = Vector2(110, 620)
	message_label.size = Vector2(1060, 48)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 22)
	message_label.add_theme_color_override("font_color", Color("#fff3a6"))
	add_child(message_label)
	var controls := Label.new()
	controls.text = "WASD / Stick: Move    Shift: Sprint    Left Click: Eat    Right Click: Ability    Q: Scent    Space: Dash    R: Special    Esc: Pause"
	controls.position = Vector2(50, 680)
	controls.size = Vector2(1180, 30)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 15)
	add_child(controls)

func _make_bar(parent: Control, label_text: String, position_value: Vector2, tint: Color) -> ProgressBar:
	var label := Label.new()
	label.text = label_text
	label.position = position_value
	label.size = Vector2(75, 25)
	parent.add_child(label)
	var bar := ProgressBar.new()
	bar.position = position_value + Vector2(78, 1)
	bar.size = Vector2(400, 22)
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = true
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
	completion_panel.add_child(heading)
	var body := Label.new()
	body.name = "Body"
	body.position = Vector2(290, 250)
	body.size = Vector2(700, 130)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 21)
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
