class_name DisplayModeButton
extends Button


const CONFIG_PATH := "user://display_settings.cfg"
const CONFIG_SECTION := "display"
const FULLSCREEN_KEY := "fullscreen"


func _ready() -> void:
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
			DisplayServer.WINDOW_MODE_FULLSCREEN
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
