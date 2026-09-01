class_name MainMenu
extends Control


@export var audio_settings_panel: AudioSettingsPanel


@onready var start_button: Button = (
	$CenterContainer/MenuPanel/MarginContainer/
	VBoxContainer/StartButton
)

@onready var audio_button: Button = (
	$CenterContainer/MenuPanel/MarginContainer/
	VBoxContainer/AudioButton
)

@onready var quit_button: Button = (
	$CenterContainer/MenuPanel/MarginContainer/
	VBoxContainer/QuitButton
)

@onready var background: ColorRect = $Background

@onready var menu_panel: PanelContainer = (
	$CenterContainer/MenuPanel
)

@onready var ui_sound: AudioStreamPlayer = (
	$"../UISound"
)

@onready var how_to_play_button: Button = (
	$CenterContainer/MenuPanel/MarginContainer/
	VBoxContainer/HowToPlayButton
)

@onready var help_backdrop: ColorRect = (
	$"../HelpBackdrop"
)

@onready var help_center: CenterContainer = (
	$"../HelpCenter"
)

@onready var help_panel: PanelContainer = (
	$"../HelpCenter/HelpPanel"
)

@onready var help_close_button: Button = (
	$"../HelpCenter/HelpPanel/MarginContainer/VBoxContainer/CloseButton"
)


var menu_tween: Tween
var help_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	
	how_to_play_button.pressed.connect(
		_open_help
	)

	help_close_button.pressed.connect(
		_close_help
	)

	start_button.pressed.connect(_start_game)
	audio_button.pressed.connect(_open_audio_settings)
	quit_button.pressed.connect(_quit_game)

	if audio_settings_panel != null:
		audio_settings_panel.panel_closed.connect(
			_on_audio_settings_closed
		)

	call_deferred("_play_intro_animation")


func _start_game() -> void:
	_play_ui_click()
	_set_buttons_disabled(true)

	if menu_tween != null:
		menu_tween.kill()

	menu_tween = create_tween()
	menu_tween.set_parallel(true)

	menu_tween.tween_property(
		background,
		"modulate:a",
		0.0,
		0.25
	)

	menu_tween.tween_property(
		menu_panel,
		"modulate:a",
		0.0,
		0.18
	)

	menu_tween.tween_property(
		menu_panel,
		"scale",
		Vector2(1.05, 1.05),
		0.22
	)

	menu_tween.set_parallel(false)

	menu_tween.tween_callback(
		_finish_starting_game
	)


func _open_audio_settings() -> void:
	if audio_settings_panel == null:
		return

	_set_buttons_disabled(true)
	audio_settings_panel.open_panel()


func _quit_game() -> void:
	_set_buttons_disabled(true)
	_play_ui_click()

	await get_tree().create_timer(
		0.09,
		true
	).timeout

	get_tree().quit()


func _on_audio_settings_closed() -> void:
	_set_buttons_disabled(false)
	#audio_button.grab_focus()


func _set_buttons_disabled(value: bool) -> void:
	start_button.disabled = value
	audio_button.disabled = value
	how_to_play_button.disabled = value
	quit_button.disabled = value


func _play_intro_animation() -> void:
	if menu_tween != null:
		menu_tween.kill()

	background.modulate.a = 0.0
	menu_panel.modulate.a = 0.0
	menu_panel.scale = Vector2(0.9, 0.9)
	menu_panel.pivot_offset = menu_panel.size / 2.0

	menu_tween = create_tween()
	menu_tween.set_parallel(true)

	menu_tween.tween_property(
		background,
		"modulate:a",
		1.0,
		0.25
	)

	menu_tween.tween_property(
		menu_panel,
		"modulate:a",
		1.0,
		0.18
	)

	menu_tween.tween_property(
		menu_panel,
		"scale",
		Vector2.ONE,
		0.3
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)


func _finish_starting_game() -> void:
	hide()
	get_tree().paused = false


func _play_ui_click() -> void:
	if ui_sound.stream == null:
		return

	ui_sound.pitch_scale = randf_range(
		0.98,
		1.02
	)

	ui_sound.play()


func _open_help() -> void:
	_play_ui_click()
	_set_buttons_disabled(true)

	if help_tween != null:
		help_tween.kill()

	help_backdrop.modulate.a = 0.0
	help_panel.modulate.a = 0.0
	help_panel.scale = Vector2(0.92, 0.92)
	help_panel.pivot_offset = help_panel.size / 2.0

	help_backdrop.show()
	help_center.show()

	help_tween = create_tween()
	help_tween.set_parallel(true)

	help_tween.tween_property(
		help_backdrop,
		"modulate:a",
		1.0,
		0.14
	)

	help_tween.tween_property(
		help_panel,
		"modulate:a",
		1.0,
		0.14
	)

	help_tween.tween_property(
		help_panel,
		"scale",
		Vector2.ONE,
		0.18
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)


func _close_help() -> void:
	if not help_center.visible:
		return

	_play_ui_click()

	if help_tween != null:
		help_tween.kill()

	help_tween = create_tween()
	help_tween.set_parallel(true)

	help_tween.tween_property(
		help_backdrop,
		"modulate:a",
		0.0,
		0.12
	)

	help_tween.tween_property(
		help_panel,
		"modulate:a",
		0.0,
		0.1
	)

	help_tween.tween_property(
		help_panel,
		"scale",
		Vector2(0.94, 0.94),
		0.12
	)

	help_tween.set_parallel(false)

	help_tween.tween_callback(
		_finish_closing_help
	)


func _finish_closing_help() -> void:
	help_center.hide()
	help_backdrop.hide()

	help_panel.scale = Vector2.ONE
	help_panel.modulate.a = 1.0
	help_backdrop.modulate.a = 1.0

	_set_buttons_disabled(false)


func _unhandled_input(event: InputEvent) -> void:
	if not help_panel.visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_close_help()
		get_viewport().set_input_as_handled()


func open_help_panel() -> void:
	if help_center.visible:
		return

	_open_help()
