Let’s add a compact audio settings panel controlling the buses we just created.

### 1. Add the settings button

Inside the HUD’s `ResourceRow`, add a `Button` named:

```
AudioButton
```

Configure:

```
Text: Audio
Custom Minimum Size: 54 × 26
```

Apply the same pixel-button styles used for the build button.

### 2. Create the settings panel

Under `Interface`, add:

```
AudioSettingsPanel             PanelContainer
└── MarginContainer
    └── VBoxContainer
        ├── TitleLabel
        ├── MasterLabel
        ├── MasterSlider
        ├── EffectsLabel
        ├── EffectsSlider
        ├── AmbienceLabel
        ├── AmbienceSlider
        └── CloseButton
```

Configure:

```
TitleLabel:    Audio Settings
MasterLabel:   Master
EffectsLabel:  Effects
AmbienceLabel: Ambience
CloseButton:   Close
```

For each `HSlider`, use:

```
Min Value: 0
Max Value: 1
Step:      0.05
Value:     1
Custom Minimum Size X: 180
```

Set `AudioSettingsPanel` initially:

```
Visible: Off
Custom Minimum Size: 230 × 190
```

### 3. Attach the script

Create:

```
res://scripts/ui/audio_settings_panel.gd
```

Add:

```
class_name AudioSettingsPanel
extends PanelContainer


@export_category("Opening")
@export var open_button: Button


@onready var master_slider: HSlider = (
	$MarginContainer/VBoxContainer/MasterSlider
)

@onready var effects_slider: HSlider = (
	$MarginContainer/VBoxContainer/EffectsSlider
)

@onready var ambience_slider: HSlider = (
	$MarginContainer/VBoxContainer/AmbienceSlider
)

@onready var close_button: Button = (
	$MarginContainer/VBoxContainer/CloseButton
)


func _ready() -> void:
	if open_button != null:
		open_button.pressed.connect(_toggle_panel)

	close_button.pressed.connect(hide)

	master_slider.value_changed.connect(
		_on_master_changed
	)

	effects_slider.value_changed.connect(
		_on_effects_changed
	)

	ambience_slider.value_changed.connect(
		_on_ambience_changed
	)

	_sync_sliders()
```

### 4. Add the bus helpers

Continue in the same script:

```
func _toggle_panel() -> void:
	visible = not visible


func _sync_sliders() -> void:
	master_slider.value = _get_bus_linear("Master")
	effects_slider.value = _get_bus_linear("SFX")
	ambience_slider.value = _get_bus_linear("Ambience")


func _get_bus_linear(bus_name: StringName) -> float:
	var bus_index := AudioServer.get_bus_index(
		bus_name
	)

	if bus_index < 0:
		return 1.0

	if AudioServer.is_bus_mute(bus_index):
		return 0.0

	return db_to_linear(
		AudioServer.get_bus_volume_db(bus_index)
	)
```

### 5. Add the slider callbacks

```
func _on_master_changed(value: float) -> void:
	_set_bus_linear("Master", value)


func _on_effects_changed(value: float) -> void:
	_set_bus_linear("SFX", value)
	_set_bus_linear("UI", value)


func _on_ambience_changed(value: float) -> void:
	_set_bus_linear("Ambience", value)


func _set_bus_linear(
	bus_name: StringName,
	value: float
) -> void:
	var bus_index := AudioServer.get_bus_index(
		bus_name
	)

	if bus_index < 0:
		return

	var should_mute := value <= 0.001

	AudioServer.set_bus_mute(
		bus_index,
		should_mute
	)

	if not should_mute:
		AudioServer.set_bus_volume_db(
			bus_index,
			linear_to_db(value)
		)
```

### 6. Assign the opening button

Select `AudioSettingsPanel`. In its exported property, drag:

```
HUD/TopBar/MarginContainer/ResourceRow/AudioButton
```

into:

```
Opening → Open Button
```

The panel now controls:

- Master: every sound.
- Effects: gathering, footsteps, construction, and UI.
- Ambience: daytime and nighttime forest loops.

The next improvement will be saving these values so they persist after restarting the game.

FIX::::
*thats cool but seems like that the audio menu is showed on the left top bar. And I wish to have the same pixel style of the rest of the UI*

The panel is functioning, but it is anchored at `(0, 0)` and still uses Godot’s default theme. Let’s center it and apply the same dark, square pixel style.

## 1. Center the panel

Select `AudioSettingsPanel`, then choose:

```
Layout → Anchors Preset → Center
```

Configure:

```
Anchor Left:   0.5
Anchor Top:    0.5
Anchor Right:  0.5
Anchor Bottom: 0.5

Offset Left:   -125
Offset Top:    -110
Offset Right:   125
Offset Bottom:  110
```

The panel will now remain centred at every resolution.

## 2. Style the main panel

Under:

```
Theme Overrides → Styles → Panel
```

Create a `StyleBoxFlat`:

```
Background Color: #18231ff2
Border Color:     #0d1510

Border Width Left:   3
Border Width Top:    3
Border Width Right:  3
Border Width Bottom: 3

Corner Radius: 0
```

Set its content margins:

```
Left:   12
Top:    10
Right:  12
Bottom: 10
```

For the internal `VBoxContainer`, set:

```
Theme Overrides → Constants → Separation: 6
```

## 3. Style the title and labels

For `TitleLabel`:

```
Horizontal Alignment: Center
Font Size: 16
Font Color: #f2d479
```

For the other labels:

```
Font Size: 12
Font Color: #f2e7c9
```

## 4. Style the slider tracks

Apply the following to all three sliders.

Under:

```
Theme Overrides → Styles → Slider
```

Create a `StyleBoxFlat`:

```
Background Color: #0f1915
Border Color:     #31443b
Border Width:     1 on every side
Corner Radius:    0
Content Margin Top:    3
Content Margin Bottom: 3
```

Under:

```
Theme Overrides → Styles → Grabber Area
```

Create another `StyleBoxFlat`:

```
Background Color: #667e4e
Border Color:     #a9bd6a
Border Width:     1 on every side
Corner Radius:    0
```

Use the same style with a brighter background for `Grabber Area Highlight`:

```
Background Color: #80985c
```

## 5. Replace the circular grabber

For each slider, open:

```
Theme Overrides → Icons → Grabber
```

Create a `GradientTexture2D`:

```
Width:  8
Height: 12
```

Open its gradient and set both ends to:

```
#d8c47b
```

Use the same texture for:

```
Grabber
Grabber Highlight
Grabber Disabled
```

This replaces the smooth circular handle with a rectangular pixel handle.

## 6. Style the Close button

Use the same styles as the build button:

```
Normal Background:  #435c3e
Hover Background:   #58754e
Pressed Background: #30442e
Border Color:       #17251b
Border Width:       2
Corner Radius:      0
Font Color:         #f2e7c9
Minimum Height:     28
```

After these changes, the audio menu should appear as a centred `250 × 220` pixel-style window rather than unfolding from the top-left corner.

Let’s give `AudioButton` the same compact woodland pixel style while keeping it distinct from the construction button.

Select:

```
HUD/TopBar/MarginContainer/ResourceRow/AudioButton
```

## 1. Configure its size and text

```
Text: AUDIO
Custom Minimum Size: 58 × 26
Alignment: Center
Mouse Default Cursor Shape: Pointing Hand
Focus Mode: All
```

Using uppercase text makes the small button feel more like a pixel-game control.

## 2. Normal style

Under:

```
Theme Overrides → Styles → Normal
```

Create a `StyleBoxFlat`:

```
Background Color: #293a33
Border Color:     #101a16

Border Width Left:   2
Border Width Top:    2
Border Width Right:  2
Border Width Bottom: 2

Corner Radius: 0

Content Margin Left:   6
Content Margin Top:    3
Content Margin Right:  6
Content Margin Bottom: 3
```

## 3. Hover style

Create another `StyleBoxFlat` under **Hover**:

```
Background Color: #435c4d
Border Color:     #d8c47b
Border Width:     2 on every side
Corner Radius:    0
```

## 4. Pressed style

Under **Pressed**:

```
Background Color: #1b2923
Border Color:     #f2d479
Border Width:     2 on every side
Corner Radius:    0
```

This creates the impression that the button moves inward when clicked.

## 5. Focus style

Under **Focus**, create a transparent `StyleBoxFlat`:

```
Background Color: Transparent
Border Color:     #f2d479
Border Width:     1 on every side
Corner Radius:    0
```

The keyboard-focus indicator now matches the gold highlights elsewhere in the UI.

## 6. Text colours

Under **Theme Overrides → Colors**:

```
Font Color:         #f2e7c9
Font Hover Color:   #fff1bd
Font Pressed Color: #ffffff
Font Focus Color:   #f2d479
Font Disabled Color:#78847a
```

Set:

```
Theme Overrides → Font Sizes → Font Size: 11
```

The result should be a subtle dark button in its normal state, with a gold pixel border when hovered or keyboard-focused.