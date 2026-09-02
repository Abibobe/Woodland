class_name VSyncButton
extends Button


const CONFIG_PATH := "user://display_settings.cfg"
const CONFIG_SECTION := "display"
const VSYNC_KEY := "vsync"


func _ready() -> void:
	toggle_mode = true

	toggled.connect(
		_on_vsync_toggled
	)

	_load_setting()


func _load_setting() -> void:
	var config := ConfigFile.new()
	var vsync_enabled := true

	if config.load(CONFIG_PATH) == OK:
		vsync_enabled = bool(
			config.get_value(
				CONFIG_SECTION,
				VSYNC_KEY,
				true
			)
		)

	set_pressed_no_signal(vsync_enabled)

	_apply_vsync(vsync_enabled)
	_update_button_text(vsync_enabled)


func _on_vsync_toggled(enabled: bool) -> void:
	_apply_vsync(enabled)
	_update_button_text(enabled)
	_save_setting(enabled)


func _apply_vsync(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED
		)
	else:
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_DISABLED
		)


func _update_button_text(enabled: bool) -> void:
	if enabled:
		text = "VSync: On"
	else:
		text = "VSync: Off"


func _save_setting(enabled: bool) -> void:
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)

	config.set_value(
		CONFIG_SECTION,
		VSYNC_KEY,
		enabled
	)

	var save_result := config.save(CONFIG_PATH)

	if save_result != OK:
		push_warning(
			"Could not save VSync setting: %s"
			% save_result
		)


func reset_to_default() -> void:
	var default_vsync := true

	set_pressed_no_signal(
		default_vsync
	)

	_apply_vsync(
		default_vsync
	)

	_update_button_text(
		default_vsync
	)

	_save_setting(
		default_vsync
	)
