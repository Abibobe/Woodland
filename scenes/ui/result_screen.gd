class_name ResultScreen
extends Control


signal restart_requested

@export_category("Visuals")
@export var result_icons_texture: Texture2D

@onready var dimmer: ColorRect = $Dimmer
@onready var panel: PanelContainer = $Panel

@onready var title_label: Label = (
	$Panel/MarginContainer/Content/TitleLabel
)

@onready var message_label: Label = (
	$Panel/MarginContainer/Content/MessageLabel
)

@onready var restart_button: Button = (
	$Panel/MarginContainer/Content/RestartButton
)

@onready var ui_sound: AudioStreamPlayer = (
	$"../UISound"
)

@onready var stats_label: Label = (
	$Panel/MarginContainer/Content/StatsLabel
)

@onready var result_icon: TextureRect = (
	$Panel/MarginContainer/Content/ResultIcon
)



var result_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 200

	restart_button.pressed.connect(
		_on_restart_button_pressed
	)

	get_viewport().size_changed.connect(
		_apply_layout
	)

	hide()
	call_deferred("_apply_layout")


func show_result(
	title: String,
	message: String,
	stats: Dictionary = {}
) -> void:
	title_label.text = title
	message_label.text = message
	stats_label.text = _format_stats(stats)
	_set_result_icon(title)

	match title:
		"Victory":
			title_label.add_theme_color_override(
				"font_color",
				Color("#f2d479")
			)

		"Defeat":
			title_label.add_theme_color_override(
				"font_color",
				Color("#e06c68")
			)

		_:
			title_label.add_theme_color_override(
				"font_color",
				Color("#f2e7c9")
			)

	show()
	_apply_layout()
	_play_result_animation()


func _play_result_animation() -> void:
	if result_tween != null:
		result_tween.kill()

	dimmer.modulate.a = 0.0
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.88, 0.88)
	panel.pivot_offset = panel.size / 2.0

	result_tween = create_tween()
	result_tween.set_parallel(true)

	result_tween.tween_property(
		dimmer,
		"modulate:a",
		1.0,
		0.25
	)

	result_tween.tween_property(
		panel,
		"modulate:a",
		1.0,
		0.18
	)

	result_tween.tween_property(
		panel,
		"scale",
		Vector2.ONE,
		0.3
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)


func _apply_layout() -> void:
	var viewport_size := (
		get_viewport().get_visible_rect().size
	)

	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = viewport_size

	dimmer.set_anchors_preset(
		Control.PRESET_TOP_LEFT
	)

	dimmer.position = Vector2.ZERO
	dimmer.size = viewport_size

	panel.set_anchors_preset(
		Control.PRESET_TOP_LEFT
	)

	panel.size = Vector2(420.0, 250.0)

	panel.position = Vector2(
		(viewport_size.x - panel.size.x) / 2.0,
		(viewport_size.y - panel.size.y) / 2.0
	)


func _play_ui_click() -> void:
	if ui_sound.stream == null:
		return

	ui_sound.pitch_scale = randf_range(
		0.98,
		1.02
	)

	ui_sound.play()


func _on_restart_button_pressed() -> void:
	restart_button.disabled = true
	_play_ui_click()

	await get_tree().create_timer(
		0.09,
		true
	).timeout

	restart_requested.emit()


func _format_stats(stats: Dictionary) -> String:
	if stats.is_empty():
		return ""

	return (
		"Day reached: %d\n"
		+ "Wood %d  |  Stone %d  |  Food %d\n"
		+ "Camp stage: %s"
	) % [
		int(stats.get("day", 1)),
		int(stats.get("wood", 0)),
		int(stats.get("stone", 0)),
		int(stats.get("food", 0)),
		String(stats.get("camp_stage", "Site"))
	]


func _set_result_icon(title: String) -> void:
	if result_icons_texture == null:
		result_icon.hide()
		return

	var source_x: float

	match title:
		"Victory":
			source_x = 0.0

		"Defeat":
			source_x = 32.0

		_:
			result_icon.hide()
			return

	var atlas_texture := AtlasTexture.new()
	panel.size = Vector2(420.0, 285.0)
	atlas_texture.atlas = result_icons_texture
	atlas_texture.region = Rect2(
		source_x,
		0.0,
		32.0,
		32.0
	)
	result_icon.texture = atlas_texture
	result_icon.show()
