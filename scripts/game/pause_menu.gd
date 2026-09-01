class_name PauseMenu
extends Control


@export_category("Existing Menus")
@export var main_menu: MainMenu
@export var audio_settings_panel: AudioSettingsPanel
@export var help_center: CenterContainer
@export var result_screen: ResultScreen


@onready var resume_button: Button = (
	$CenterContainer/Panel/MarginContainer/
	VBoxContainer/ResumeButton
)

@onready var audio_button: Button = (
	$CenterContainer/Panel/MarginContainer/
	VBoxContainer/AudioButton
)

@onready var help_button: Button = (
	$CenterContainer/Panel/MarginContainer/
	VBoxContainer/HelpButton
)

@onready var title_button: Button = (
	$CenterContainer/Panel/MarginContainer/
	VBoxContainer/TitleButton
)

@onready var ui_sound: AudioStreamPlayer = (
	$"../UISound"
)

@onready var backdrop: ColorRect = $Backdrop
@onready var panel: PanelContainer = $CenterContainer/Panel

@onready var confirm_panel: PanelContainer = (
	$CenterContainer/ConfirmPanel
)

@onready var cancel_button: Button = (
	$CenterContainer/ConfirmPanel/MarginContainer/
	ConfirmContent/ConfirmButtons/CancelButton
)

@onready var confirm_button: Button = (
	$CenterContainer/ConfirmPanel/MarginContainer/
	ConfirmContent/ConfirmButtons/ConfirmButton
)


var pause_tween: Tween

func _ready() -> void:
	resume_button.pressed.connect(_resume_game)
	audio_button.pressed.connect(_open_audio_settings)
	help_button.pressed.connect(_open_help)
	title_button.pressed.connect(_return_to_title)

	audio_settings_panel.visibility_changed.connect(
		_on_secondary_panel_visibility_changed
	)

	help_center.visibility_changed.connect(
		_on_secondary_panel_visibility_changed
	)
	cancel_button.pressed.connect(
		_cancel_return_to_title
	)

	confirm_button.pressed.connect(
		_confirm_return_to_title
	)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()

		if confirm_panel.visible:
			_cancel_return_to_title()
			return

		if visible:
			_resume_game()
			return

	if _is_another_modal_open():
		return

	if visible:
		_resume_game()
		get_viewport().set_input_as_handled()
		return

	if get_tree().paused:
		return

	_open_pause_menu()
	get_viewport().set_input_as_handled()


func _is_another_modal_open() -> bool:
	if main_menu != null and main_menu.visible:
		return true

	if (
		audio_settings_panel != null
		and audio_settings_panel.visible
	):
		return true

	if help_center != null and help_center.visible:
		return true

	if (
		result_screen != null
		and result_screen.visible
	):
		return true

	return false

func _open_pause_menu() -> void:
	get_tree().paused = true

	if pause_tween != null:
		pause_tween.kill()

	show()

	backdrop.modulate.a = 0.0
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.92, 0.92)
	panel.pivot_offset = panel.size / 2.0

	pause_tween = create_tween()
	pause_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	pause_tween.set_parallel(true)

	pause_tween.tween_property(
		backdrop,
		"modulate:a",
		1.0,
		0.15
	)

	pause_tween.tween_property(
		panel,
		"modulate:a",
		1.0,
		0.15
	)

	pause_tween.tween_property(
		panel,
		"scale",
		Vector2.ONE,
		0.18
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	resume_button.grab_focus()

	confirm_panel.hide()
	panel.show()

	confirm_button.disabled = false
	cancel_button.disabled = false

func _resume_game() -> void:
	_play_ui_click()
	_set_buttons_disabled(true)

	if pause_tween != null:
		pause_tween.kill()

	pause_tween = create_tween()
	pause_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	pause_tween.set_parallel(true)

	pause_tween.tween_property(
		backdrop,
		"modulate:a",
		0.0,
		0.12
	)

	pause_tween.tween_property(
		panel,
		"modulate:a",
		0.0,
		0.12
	)

	pause_tween.tween_property(
		panel,
		"scale",
		Vector2(0.96, 0.96),
		0.12
	)

	pause_tween.chain().tween_callback(
		_finish_resuming
	)





func _open_audio_settings() -> void:
	_play_ui_click()

	hide()
	audio_settings_panel.open_panel()


func _open_help() -> void:
	_play_ui_click()

	hide()
	main_menu.open_help_panel()

func _return_to_title() -> void:
	_play_ui_click()

	panel.hide()
	confirm_panel.show()

	cancel_button.grab_focus()

func _play_ui_click() -> void:
	if ui_sound.stream == null:
		return

	ui_sound.pitch_scale = randf_range(
		0.98,
		1.02
	)

	ui_sound.play()


func _set_buttons_disabled(value: bool) -> void:
	resume_button.disabled = value
	audio_button.disabled = value
	help_button.disabled = value
	title_button.disabled = value


func _on_secondary_panel_visibility_changed() -> void:
	call_deferred("_restore_after_secondary_panel")


func _restore_after_secondary_panel() -> void:
	if audio_settings_panel.visible:
		return

	if help_center.visible:
		return

	if not get_tree().paused:
		return

	show()
	resume_button.grab_focus()


func _finish_resuming() -> void:
	hide()

	backdrop.modulate.a = 1.0
	panel.modulate.a = 1.0
	panel.scale = Vector2.ONE

	_set_buttons_disabled(false)
	get_tree().paused = false


func _cancel_return_to_title() -> void:
	_play_ui_click()

	confirm_panel.hide()
	panel.show()

	confirm_button.grab_focus()


func _confirm_return_to_title() -> void:
	_play_ui_click()

	confirm_button.disabled = true
	cancel_button.disabled = true

	await get_tree().create_timer(
		0.09,
		true,
		false,
		true
	).timeout

	get_tree().paused = false
	get_tree().reload_current_scene()
