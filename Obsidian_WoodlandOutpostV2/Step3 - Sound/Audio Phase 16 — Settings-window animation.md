
Let’s animate the modal so it fades and gently expands into place.
### 1. Add a tween variable

In `audio_settings_panel.gd`:

```
var panel_tween: Tween
```

### 2. Replace `_open_panel()`

```
func _open_panel() -> void:
	previous_pause_state = get_tree().paused
	get_tree().paused = true

	if panel_tween != null:
		panel_tween.kill()

	backdrop.modulate.a = 0.0
	modulate.a = 0.0
	scale = Vector2(0.92, 0.92)
	pivot_offset = size / 2.0

	backdrop.show()
	show()

	panel_tween = create_tween()
	panel_tween.set_parallel(true)

	panel_tween.tween_property(
		backdrop,
		"modulate:a",
		1.0,
		0.14
	)

	panel_tween.tween_property(
		self,
		"modulate:a",
		1.0,
		0.14
	)

	panel_tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		0.18
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)
```

### 3. Replace `_close_panel()`

```
func _close_panel() -> void:
	if not visible:
		return

	if panel_tween != null:
		panel_tween.kill()

	panel_tween = create_tween()
	panel_tween.set_parallel(true)

	panel_tween.tween_property(
		backdrop,
		"modulate:a",
		0.0,
		0.12
	)

	panel_tween.tween_property(
		self,
		"modulate:a",
		0.0,
		0.1
	)

	panel_tween.tween_property(
		self,
		"scale",
		Vector2(0.94, 0.94),
		0.12
	)

	panel_tween.set_parallel(false)

	panel_tween.tween_callback(
		_finish_closing_panel
	)
```

### 4. Add the completion function

```
func _finish_closing_panel() -> void:
	hide()
	backdrop.hide()

	scale = Vector2.ONE
	modulate.a = 1.0
	backdrop.modulate.a = 1.0

	get_tree().paused = previous_pause_state
```

Because the panel uses `Process Mode: Always`, the tween continues while the rest of the game is paused. The window now opens with a short pixel-style pop and closes with a quick fade.