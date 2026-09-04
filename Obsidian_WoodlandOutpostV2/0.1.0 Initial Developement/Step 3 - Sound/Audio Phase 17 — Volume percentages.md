Let’s add percentage readouts so the slider values are clear and reproducible

### 1. Create three header rows

Replace each standalone label with an `HBoxContainer`:

```
VBoxContainer
├── MasterHeader
│   ├── MasterLabel
│   ├── MasterSpacer
│   └── MasterValueLabel
├── MasterSlider
├── EffectsHeader
│   ├── EffectsLabel
│   ├── EffectsSpacer
│   └── EffectsValueLabel
├── EffectsSlider
├── AmbienceHeader
│   ├── AmbienceLabel
│   ├── AmbienceSpacer
│   └── AmbienceValueLabel
├── AmbienceSlider
└── CloseButton
```

Each spacer should be a `Control` with:

```
Horizontal Size Flags → Expand: On
```

Set the value labels initially to:

```
100%
```

Style them with:

```
Font Color: #f2d479
Font Size:  11
```

### 2. Add the label references

In `audio_settings_panel.gd`:

```
@onready var master_value_label: Label = (
	$MarginContainer/VBoxContainer/
	MasterHeader/MasterValueLabel
)

@onready var effects_value_label: Label = (
	$MarginContainer/VBoxContainer/
	EffectsHeader/EffectsValueLabel
)

@onready var ambience_value_label: Label = (
	$MarginContainer/VBoxContainer/
	AmbienceHeader/AmbienceValueLabel
)
```

### 3. Add the update function

```
func _update_value_labels() -> void:
	master_value_label.text = "%d%%" % roundi(
		master_slider.value * 100.0
	)

	effects_value_label.text = "%d%%" % roundi(
		effects_slider.value * 100.0
	)

	ambience_value_label.text = "%d%%" % roundi(
		ambience_slider.value * 100.0
	)
```

### 4. Update each slider callback

Add `_update_value_labels()` after applying the volume:

```
func _on_master_changed(value: float) -> void:
	_set_bus_linear("Master", value)
	_update_value_labels()

	if not is_loading_settings:
		_save_audio_settings()
```

Do the same for effects and ambience:

```
func _on_effects_changed(value: float) -> void:
	_set_bus_linear("SFX", value)
	_set_bus_linear("UI", value)
	_update_value_labels()

	if not is_loading_settings:
		_save_audio_settings()


func _on_ambience_changed(value: float) -> void:
	_set_bus_linear("Ambience", value)
	_update_value_labels()

	if not is_loading_settings:
		_save_audio_settings()
```

Finally, call this at the end of `_load_audio_settings()`:

```
_update_value_labels()
```

The panel now provides exact percentages while preserving the sliders, audio buses, saved settings, modal pause, and animations.