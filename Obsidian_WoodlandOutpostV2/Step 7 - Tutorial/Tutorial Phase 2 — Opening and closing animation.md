Add these references to `tutorial_prompt.gd`:

```
@onready var backdrop: ColorRect = $Backdrop

@onready var panel: PanelContainer = (
	$TutorialCenter/Panel
)


var tutorial_tween: Tween
```

Replace `open_prompt()` with:

```
func open_prompt() -> void:
	if visible:
		return

	previous_pause_state = get_tree().paused
	get_tree().paused = true

	if tutorial_tween != null:
		tutorial_tween.kill()

	show()

	got_it_button.disabled = false

	backdrop.modulate.a = 0.0
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.92, 0.92)
	panel.pivot_offset = panel.size / 2.0

	tutorial_tween = create_tween()
	tutorial_tween.set_pause_mode(
		Tween.TWEEN_PAUSE_PROCESS
	)
	tutorial_tween.set_parallel(true)

	tutorial_tween.tween_property(
		backdrop,
		"modulate:a",
		1.0,
		0.15
	)

	tutorial_tween.tween_property(
		panel,
		"modulate:a",
		1.0,
		0.15
	)

	tutorial_tween.tween_property(
		panel,
		"scale",
		Vector2.ONE,
		0.18
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	got_it_button.grab_focus()
```

Replace `_dismiss_prompt()` with:

```
func _dismiss_prompt() -> void:
	_save_dismissed_state()

	got_it_button.disabled = true

	if tutorial_tween != null:
		tutorial_tween.kill()

	tutorial_tween = create_tween()
	tutorial_tween.set_pause_mode(
		Tween.TWEEN_PAUSE_PROCESS
	)
	tutorial_tween.set_parallel(true)

	tutorial_tween.tween_property(
		backdrop,
		"modulate:a",
		0.0,
		0.12
	)

	tutorial_tween.tween_property(
		panel,
		"modulate:a",
		0.0,
		0.12
	)

	tutorial_tween.tween_property(
		panel,
		"scale",
		Vector2(0.96, 0.96),
		0.12
	)

	tutorial_tween.chain().tween_callback(
		_finish_dismiss
	)
```

Then add:

```
func _finish_dismiss() -> void:
	hide()

	backdrop.modulate.a = 1.0
	panel.modulate.a = 1.0
	panel.scale = Vector2.ONE

	got_it_button.disabled = false
	get_tree().paused = previous_pause_state
```

Confirm once more:

```
TutorialPrompt → Process → Mode: Always
```

Now the first-launch tutorial will appear cleanly, pause the world, and gently disappear after **Got it**. When opened from the pause menu, closing it will return to Pause instead of resuming gameplay.