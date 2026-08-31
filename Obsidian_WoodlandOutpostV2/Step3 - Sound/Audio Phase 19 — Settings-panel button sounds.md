Nice! One final audio-panel detail: its own buttons should use the UI click sound too.

## Audio Phase 19 — Settings-panel button sounds

In `audio_settings_panel.gd`, add:

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

Inside `_open_panel()`, add:

```
_play_ui_click()
```

Inside `_close_panel()`, after confirming the panel is visible, add:

```
_play_ui_click()
```

Inside `_reset_audio_settings()`, add it at the beginning:

```
func _reset_audio_settings() -> void:
	_play_ui_click()

	is_loading_settings = true

	# Keep the existing reset code below.
```

The Audio, Close, Reset Defaults, camp-menu, and construction buttons now share the same consistent UI feedback. The click also respects the Effects slider because `UISound` is routed through the `UI` bus.