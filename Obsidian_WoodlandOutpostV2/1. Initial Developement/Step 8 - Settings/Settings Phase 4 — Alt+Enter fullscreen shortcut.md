Let’s add the familiar `Alt + Enter` shortcut so fullscreen can be toggled anywhere: title screen, gameplay, or pause menu.

### 1. Update `display_mode_button.gd`

Add this at the beginning of `_ready()`:

```
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	toggle_mode = true

	toggled.connect(
		_on_fullscreen_toggled
	)

	_load_setting()
```

Then add:

```
func _unhandled_key_input(
	event: InputEvent
) -> void:
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey

	if not key_event.pressed:
		return

	if key_event.echo:
		return

	if not key_event.alt_pressed:
		return

	if key_event.keycode != KEY_ENTER:
		return

	button_pressed = not button_pressed

	get_viewport().set_input_as_handled()
```

Changing `button_pressed` automatically triggers the existing `toggled` signal, so it will:

- Change window mode.
- Update the button text.
- Save the preference.

### 2. Add a small hint

Under `VSyncButton`, add a `Label` named:

```
DisplayHint
```

Configure it:

```
Text: ALT + ENTER — Toggle fullscreen
Horizontal Alignment: Center
Font Size: 9
Font Color: #829181
Mouse Filter: Ignore
```

Now fullscreen can be controlled both through the pixel-style Settings button and the standard keyboard shortcut, with both methods remaining synchronized.