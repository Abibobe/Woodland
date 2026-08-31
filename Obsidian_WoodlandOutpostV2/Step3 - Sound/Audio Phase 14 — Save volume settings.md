Let’s persist the audio sliders with Godot’s `ConfigFile`. The settings will be stored safely under `user://`.

### 1. Add these variables

Near the top of `audio_settings_panel.gd`:

```
const SETTINGS_PATH := "user://audio_settings.cfg"
const AUDIO_SECTION := "audio"

var is_loading_settings: bool = false
```

### 2. Update `_ready()`

Replace:

```
_sync_sliders()
```

with:

```
_load_audio_settings()
```

Keep the rest of `_ready()` unchanged.

### 3. Add the loading function

```
func _load_audio_settings() -> void:
	var config := ConfigFile.new()
	var load_result := config.load(SETTINGS_PATH)

	is_loading_settings = true

	if load_result == OK:
		master_slider.value = float(
			config.get_value(
				AUDIO_SECTION,
				"master",
				_get_bus_linear("Master")
			)
		)

		effects_slider.value = float(
			config.get_value(
				AUDIO_SECTION,
				"effects",
				_get_bus_linear("SFX")
			)
		)

		ambience_slider.value = float(
			config.get_value(
				AUDIO_SECTION,
				"ambience",
				_get_bus_linear("Ambience")
			)
		)
	else:
		_sync_sliders()

	is_loading_settings = false
```

Assigning the slider values also applies them through the existing `value_changed` signals.

### 4. Add the saving function

```
func _save_audio_settings() -> void:
	var config := ConfigFile.new()

	config.set_value(
		AUDIO_SECTION,
		"master",
		master_slider.value
	)

	config.set_value(
		AUDIO_SECTION,
		"effects",
		effects_slider.value
	)

	config.set_value(
		AUDIO_SECTION,
		"ambience",
		ambience_slider.value
	)

	var save_result := config.save(SETTINGS_PATH)

	if save_result != OK:
		push_warning(
			"Could not save audio settings: %s"
			% save_result
		)
```

### 5. Update the slider callbacks

```
func _on_master_changed(value: float) -> void:
	_set_bus_linear("Master", value)

	if not is_loading_settings:
		_save_audio_settings()


func _on_effects_changed(value: float) -> void:
	_set_bus_linear("SFX", value)
	_set_bus_linear("UI", value)

	if not is_loading_settings:
		_save_audio_settings()


func _on_ambience_changed(value: float) -> void:
	_set_bus_linear("Ambience", value)

	if not is_loading_settings:
		_save_audio_settings()
```

The settings are now stored in:

```
user://audio_settings.cfg
--> %APPDATA%\Godot\app_userdata\Woodland
```

C:\Users\Simone\AppData\Roaming\Godot\app_userdata\Woodland

They will persist between launches and remain separate from the project files and exported game installation.