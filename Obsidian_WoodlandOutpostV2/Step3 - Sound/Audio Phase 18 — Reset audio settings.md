### 1. Add the button

Above `CloseButton`, add:

```
ResetButton
```

Configure:

```
Text: Reset Defaults
Custom Minimum Size Y: 28
```

Use the same pixel style as `CloseButton`, but use a slightly darker normal background:

```
Normal:  #35473e
Hover:   #4b6254
Pressed: #26362f
```

### 2. Add its reference

In `audio_settings_panel.gd`:

```
@onready var reset_button: Button = (
	$MarginContainer/VBoxContainer/ResetButton
)
```

Inside `_ready()`, connect it:

```
reset_button.pressed.connect(
	_reset_audio_settings
)
```

### 3. Add the reset function

```
func _reset_audio_settings() -> void:
	is_loading_settings = true

	master_slider.value = 1.0
	effects_slider.value = 0.8
	ambience_slider.value = 0.7

	is_loading_settings = false

	_update_value_labels()
	_save_audio_settings()
```

This produces the defaults:

```
Master:    100%
Effects:    80%
Ambience:   70%
```

The sliders’ existing signals immediately apply the values to the buses. `is_loading_settings` prevents three separate file writes, then the settings are saved once after all values are updated.