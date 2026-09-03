The Settings panel now contains audio and display options, so **Reset Defaults** should reset both.

### 1. Add a reset method to `display_mode_button.gd`

Add:

```
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
```

### 2. Add a reset method to `vsync_button.gd`

Add:

```
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
```

### 3. Reference both buttons from Settings

In `audio_settings_panel.gd`, add:

```
@onready var fullscreen_button: DisplayModeButton = (
	$MarginContainer/VBoxContainer/FullscreenButton
)

@onready var vsync_button: VSyncButton = (
	$MarginContainer/VBoxContainer/VSyncButton
)
```

### 4. Update the Reset function

Replace `_reset_audio_settings()` with:

```
func _reset_audio_settings() -> void:
	_play_ui_click()

	is_loading_settings = true

	master_slider.value = 1.0
	effects_slider.value = 0.8
	ambience_slider.value = 0.7

	is_loading_settings = false

	_update_value_labels()
	_save_audio_settings()

	fullscreen_button.reset_to_default()
	vsync_button.reset_to_default()
```

The defaults will now be:

```
Master:     100%
Effects:     80%
Ambience:    70%
Fullscreen: Off
VSync:       On
```

Clicking **Reset Defaults** may immediately switch the game from fullscreen to windowed mode. That is expected because the display default is applied immediately as well as saved.