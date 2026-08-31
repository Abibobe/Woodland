
### 1. Add the sound reference

In `main_menu.gd`:

```
@onready var ui_sound: AudioStreamPlayer = (
	$"../UISound"
)
```

Add:

```
func _play_ui_click() -> void:
	if ui_sound.stream == null:
		return

	ui_sound.pitch_scale = randf_range(
		0.98,
		1.02
	)

	ui_sound.play()
```

### 2. Update Start

At the beginning of `_start_game()`:

```
func _start_game() -> void:
	_play_ui_click()
	_set_buttons_disabled(true)

	# Keep the existing transition below.
```

### 3. Update Quit

Replace `_quit_game()` with:

```
func _quit_game() -> void:
	_set_buttons_disabled(true)
	_play_ui_click()

	await get_tree().create_timer(
		0.09,
		true
	).timeout

	get_tree().quit()
```

The timer’s second argument is `process_always`, so it completes even though the main menu has paused the game.

Don’t add another click inside `_open_audio_settings()`: `AudioSettingsPanel.open_panel()` already plays the same sound, and adding one here would play it twice.