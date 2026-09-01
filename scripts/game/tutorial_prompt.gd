class_name TutorialPrompt
extends Control


const CONFIG_PATH := "user://tutorial_settings.cfg"
const CONFIG_SECTION := "tutorial"
const DISMISSED_KEY := "controls_dismissed"


@export var main_menu: MainMenu


@onready var got_it_button: Button = (
	$TutorialCenter/Panel/MarginContainer/Content/GotItButton
)

@onready var backdrop: ColorRect = $Backdrop

@onready var panel: PanelContainer = (
	$TutorialCenter/Panel
)


var tutorial_tween: Tween

var previous_pause_state: bool = false


func _ready() -> void:
	hide()

	got_it_button.pressed.connect(
		_dismiss_prompt
	)

	main_menu.visibility_changed.connect(
		_on_main_menu_visibility_changed
	)

	call_deferred(
		"_check_for_first_game"
	)


func open_prompt() -> void:
	if visible:
		return

	previous_pause_state = get_tree().paused
	get_tree().paused = true

	if tutorial_tween != null:
		tutorial_tween.kill()

	show()

	got_it_button.disabled = false

	backdrop.modulate.a = 0.0
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.92, 0.92)
	panel.pivot_offset = panel.size / 2.0

	tutorial_tween = create_tween()
	tutorial_tween.set_pause_mode(
		Tween.TWEEN_PAUSE_PROCESS
	)
	tutorial_tween.set_parallel(true)

	tutorial_tween.tween_property(
		backdrop,
		"modulate:a",
		1.0,
		0.15
	)

	tutorial_tween.tween_property(
		panel,
		"modulate:a",
		1.0,
		0.15
	)

	tutorial_tween.tween_property(
		panel,
		"scale",
		Vector2.ONE,
		0.18
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	got_it_button.grab_focus()


func _dismiss_prompt() -> void:
	_save_dismissed_state()

	got_it_button.disabled = true

	if tutorial_tween != null:
		tutorial_tween.kill()

	tutorial_tween = create_tween()
	tutorial_tween.set_pause_mode(
		Tween.TWEEN_PAUSE_PROCESS
	)
	tutorial_tween.set_parallel(true)

	tutorial_tween.tween_property(
		backdrop,
		"modulate:a",
		0.0,
		0.12
	)

	tutorial_tween.tween_property(
		panel,
		"modulate:a",
		0.0,
		0.12
	)

	tutorial_tween.tween_property(
		panel,
		"scale",
		Vector2(0.96, 0.96),
		0.12
	)

	tutorial_tween.chain().tween_callback(
		_finish_dismiss
	)




func _on_main_menu_visibility_changed() -> void:
	if main_menu.visible:
		return

	call_deferred(
		"_check_for_first_game"
	)


func _check_for_first_game() -> void:
	if main_menu.visible:
		return

	if _was_previously_dismissed():
		return

	open_prompt()


func _was_previously_dismissed() -> bool:
	var config := ConfigFile.new()

	if config.load(CONFIG_PATH) != OK:
		return false

	return bool(
		config.get_value(
			CONFIG_SECTION,
			DISMISSED_KEY,
			false
		)
	)


func _save_dismissed_state() -> void:
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)

	config.set_value(
		CONFIG_SECTION,
		DISMISSED_KEY,
		true
	)

	config.save(CONFIG_PATH)

func _finish_dismiss() -> void:
	hide()

	backdrop.modulate.a = 1.0
	panel.modulate.a = 1.0
	panel.scale = Vector2.ONE

	got_it_button.disabled = false
	get_tree().paused = previous_pause_state
