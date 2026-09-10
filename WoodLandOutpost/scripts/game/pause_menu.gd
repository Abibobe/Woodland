class_name PauseMenu
extends Control


@export_category("Existing Menus")
@export var main_menu: MainMenu
@export var audio_settings_panel: AudioSettingsPanel
@export var help_center: CenterContainer
@export var result_screen: ResultScreen
@export var tutorial_prompt: TutorialPrompt

@export var backpack_view: Control
@export var camp_menu: Control

@onready var resume_button: Button = (
	$CenterContainer/Panel/MarginContainer/Content/ResumeButton
)

@onready var audio_button: Button = (
	$CenterContainer/Panel/MarginContainer/Content/AudioButton
)

@onready var help_button: Button = (
	$CenterContainer/Panel/MarginContainer/Content/HelpButton
)

@onready var title_button: Button = (
	$CenterContainer/Panel/MarginContainer/Content/TitleButton
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
	$CenterContainer/ConfirmPanel/MarginContainer/ConfirmContent/ConfirmButtons/CancelButton
)

@onready var confirm_button: Button = (
	$CenterContainer/ConfirmPanel/MarginContainer/ConfirmContent/ConfirmButtons/ConfirmButton
)

@onready var show_tutorial_button: Button = (
	$CenterContainer/Panel/MarginContainer/Content/ShowTutorialButton
)

var pause_tween: Tween
var waiting_for_secondary_panel: bool = false

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
	show_tutorial_button.pressed.connect(
		_open_tutorial
	)

	tutorial_prompt.visibility_changed.connect(
		_on_secondary_panel_visibility_changed
	)

func _is_another_modal_open() -> bool:
	if main_menu.visible:
		return true

	if audio_settings_panel.visible:
		return true

	if help_center.visible:
		return true

	if result_screen.visible:
		return true

	if tutorial_prompt != null and tutorial_prompt.visible:
		return true

	return false


func _open_pause_menu() -> void:
	get_tree().paused = true
	waiting_for_secondary_panel = false

	confirm_panel.hide()
	panel.show()

	confirm_button.disabled = false
	cancel_button.disabled = false

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

	waiting_for_secondary_panel = true

	confirm_panel.hide()
	panel.show()
	hide()

	audio_settings_panel.open_panel()


func _open_help() -> void:
	_play_ui_click()

	waiting_for_secondary_panel = true

	confirm_panel.hide()
	panel.show()
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
	show_tutorial_button.disabled = value



func _on_secondary_panel_visibility_changed() -> void:
	call_deferred("_restore_after_secondary_panel")


func _restore_after_secondary_panel() -> void:
	if not waiting_for_secondary_panel:
		return

	if audio_settings_panel.visible:
		return

	if help_center.visible:
		return

	if tutorial_prompt != null:
		if tutorial_prompt.visible:
			return

	waiting_for_secondary_panel = false

	if not get_tree().paused:
		return

	confirm_panel.hide()
	panel.show()
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

	title_button.grab_focus()


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

func _open_tutorial() -> void:
	if tutorial_prompt == null:
		return

	_play_ui_click()

	waiting_for_secondary_panel = true

	confirm_panel.hide()
	panel.show()
	hide()

	tutorial_prompt.open_prompt()


func _handle_pause_input() -> void:
	if tutorial_prompt != null:
		if tutorial_prompt.is_visible_in_tree():
			return

	if audio_settings_panel.is_visible_in_tree():
		return

	if help_center.is_visible_in_tree():
		return

	if result_screen.is_visible_in_tree():
		return

	if main_menu.is_visible_in_tree():
		return

	if confirm_panel.visible and visible:
		_cancel_return_to_title()
		return

	if visible:
		_resume_game()
		return

	if get_tree().paused:
		return

	_open_pause_menu()

func _unhandled_input(
	event: InputEvent
) -> void:
	if event.is_echo():
		return

	if not event.is_action_pressed(
		"ui_cancel"
	):
		return

	# Let GameManager handle Escape while the backpack
	# or camp interface is open.
	if (
		is_instance_valid(backpack_view)
		and backpack_view.visible
	):
		return

	if (
		is_instance_valid(camp_menu)
		and camp_menu.visible
	):
		return

	_handle_pause_input()

	get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not Input.is_action_just_pressed("ui_cancel"):
		return

	_handle_pause_input()
