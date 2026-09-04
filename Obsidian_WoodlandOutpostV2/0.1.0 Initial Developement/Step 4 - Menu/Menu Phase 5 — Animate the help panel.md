### 1. Add a tween variable

In `main_menu.gd`:

```
var help_tween: Tween
```

### 2. Replace `_open_help()`

```
func _open_help() -> void:
	_play_ui_click()
	_set_buttons_disabled(true)

	if help_tween != null:
		help_tween.kill()

	help_backdrop.modulate.a = 0.0
	help_panel.modulate.a = 0.0
	help_panel.scale = Vector2(0.92, 0.92)
	help_panel.pivot_offset = help_panel.size / 2.0

	help_backdrop.show()
	help_center.show()

	help_tween = create_tween()
	help_tween.set_parallel(true)

	help_tween.tween_property(
		help_backdrop,
		"modulate:a",
		1.0,
		0.14
	)

	help_tween.tween_property(
		help_panel,
		"modulate:a",
		1.0,
		0.14
	)

	help_tween.tween_property(
		help_panel,
		"scale",
		Vector2.ONE,
		0.18
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)
```

### 3. Replace `_close_help()`

```
func _close_help() -> void:
	if not help_center.visible:
		return

	_play_ui_click()

	if help_tween != null:
		help_tween.kill()

	help_tween = create_tween()
	help_tween.set_parallel(true)

	help_tween.tween_property(
		help_backdrop,
		"modulate:a",
		0.0,
		0.12
	)

	help_tween.tween_property(
		help_panel,
		"modulate:a",
		0.0,
		0.1
	)

	help_tween.tween_property(
		help_panel,
		"scale",
		Vector2(0.94, 0.94),
		0.12
	)

	help_tween.set_parallel(false)

	help_tween.tween_callback(
		_finish_closing_help
	)
```

### 4. Add the completion function

```
func _finish_closing_help() -> void:
	help_center.hide()
	help_backdrop.hide()

	help_panel.scale = Vector2.ONE
	help_panel.modulate.a = 1.0
	help_backdrop.modulate.a = 1.0

	_set_buttons_disabled(false)
```

The help panel will now pop smoothly into place and fade out cleanly, while the main-menu buttons remain disabled until closing finishes.