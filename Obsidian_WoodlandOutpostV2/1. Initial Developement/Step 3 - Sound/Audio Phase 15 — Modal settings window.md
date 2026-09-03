Let’s make the audio settings behave like a proper modal window: darken the game behind it, pause gameplay, and support closing with `Esc`.

### 1. Add the backdrop

Under `Interface`, add a `ColorRect` before `AudioSettingsPanel`:

```
Interface
├── AudioSettingsBackdrop
└── AudioSettingsPanel
```

Configure `AudioSettingsBackdrop`:

```
Layout → Anchors Preset: Full Rect
Color: #08100c80
Mouse Filter: Stop
Visible: Off
Process Mode: Always
```

Keep `AudioSettingsPanel` after the backdrop so it renders above it.

Set the panel itself to:

```
Process Mode: Always
```

Its buttons and sliders inherit this mode and remain usable while the game is paused.

### 2. Add the backdrop reference

In `audio_settings_panel.gd`:

```
@onready var backdrop: ColorRect = (
	$"../AudioSettingsBackdrop"
)

var previous_pause_state: bool = false
```

### 3. Update the Close button connection

In `_ready()`, replace:

```
close_button.pressed.connect(hide)
```

with:

```
close_button.pressed.connect(_close_panel)
```

### 4. Replace `_toggle_panel()`

```
func _toggle_panel() -> void:
	if visible:
		_close_panel()
	else:
		_open_panel()
```

Add:

```
func _open_panel() -> void:
	previous_pause_state = get_tree().paused

	get_tree().paused = true

	backdrop.show()
	show()


func _close_panel() -> void:
	hide()
	backdrop.hide()

	get_tree().paused = previous_pause_state
```

Remember the previous pause state. If the game was already paused for another reason, closing audio settings will not incorrectly resume it.

### 5. Add Escape-key support

```
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_close_panel()
		get_viewport().set_input_as_handled()
```

Now the audio menu:

- Opens centred above a dark overlay.
- Prevents clicks from reaching the game world.
- Pauses movement and the day cycle.
- Remains interactive while paused.
- Closes using its button or `Esc`.
- Restores the game’s previous pause state correctly.