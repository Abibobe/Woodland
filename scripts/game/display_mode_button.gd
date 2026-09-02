class_name DisplayModeButton
extends Button


const CONFIG_PATH := "user://display_settings.cfg"
const CONFIG_SECTION := "display"
const FULLSCREEN_KEY := "fullscreen"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	toggle_mode = true

	toggled.connect(
		_on_fullscreen_toggled
	)

	_load_setting()


func _load_setting() -> void:
	var config := ConfigFile.new()
	var fullscreen_enabled := false

	if config.load(CONFIG_PATH) == OK:
		fullscreen_enabled = bool(
			config.get_value(
				CONFIG_SECTION,
				FULLSCREEN_KEY,
				false
			)
		)

	set_pressed_no_signal(
		fullscreen_enabled
	)

	_apply_display_mode(
		fullscreen_enabled
	)

	_update_button_text(
		fullscreen_enabled
	)


func _on_fullscreen_toggled(
	enabled: bool
) -> void:
	_apply_display_mode(enabled)
	_update_button_text(enabled)
	_save_setting(enabled)


func _apply_display_mode(
	fullscreen_enabled: bool
) -> void:
	if fullscreen_enabled:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		)
	else:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED
		)


func _update_button_text(
	fullscreen_enabled: bool
) -> void:
	if fullscreen_enabled:
		text = "Fullscreen: On"
	else:
		text = "Fullscreen: Off"


func _save_setting(
	fullscreen_enabled: bool
) -> void:
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)

	config.set_value(
		CONFIG_SECTION,
		FULLSCREEN_KEY,
		fullscreen_enabled
	)

	config.save(CONFIG_PATH)


func reset_to_default() -> void:
	var default_fullscreen := false

	set_pressed_no_signal(
		default_fullscreen
	)

	_apply_display_mode(
		default_fullscreen
	)

	_update_button_text(
		default_fullscreen
	)

	_save_setting(
		default_fullscreen
	)

func _unhandled_key_input(
	event: InputEvent
) -> void:
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey

	if not key_event.pressed:
		return

	if key_event.echo:
		return

	if not key_event.alt_pressed:
		return

	if key_event.keycode != KEY_ENTER:
		return

	button_pressed = not button_pressed

	get_viewport().set_input_as_handled()
