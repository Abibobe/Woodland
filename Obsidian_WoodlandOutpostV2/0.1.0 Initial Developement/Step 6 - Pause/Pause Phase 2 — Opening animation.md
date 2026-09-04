First, verify these node names:

```
PauseMenu
├── Backdrop
└── CenterContainer
    └── Panel
```

Then add these references near the top of `pause_menu.gd`:

```
@onready var backdrop: ColorRect = $Backdrop
@onready var panel: PanelContainer = $CenterContainer/Panel


var pause_tween: Tween
```

Replace `_open_pause_menu()` with:

```
func _open_pause_menu() -> void:
	get_tree().paused = true

	if pause_tween != null:
		pause_tween.kill()

	show()

	backdrop.modulate.a = 0.0
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.92, 0.92)
	panel.pivot_offset = panel.size / 2.0

	pause_tween = create_tween()
	pause_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	pause_tween.set_parallel(true)

	pause_tween.tween_property(
		backdrop,
		"modulate:a",
		1.0,
		0.15
	)

	pause_tween.tween_property(
		panel,
		"modulate:a",
		1.0,
		0.15
	)

	pause_tween.tween_property(
		panel,
		"scale",
		Vector2.ONE,
		0.18
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	resume_button.grab_focus()
```

## Add the closing animation

Replace `_resume_game()` with:

```
func _resume_game() -> void:
	_play_ui_click()
	_set_buttons_disabled(true)

	if pause_tween != null:
		pause_tween.kill()

	pause_tween = create_tween()
	pause_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	pause_tween.set_parallel(true)

	pause_tween.tween_property(
		backdrop,
		"modulate:a",
		0.0,
		0.12
	)

	pause_tween.tween_property(
		panel,
		"modulate:a",
		0.0,
		0.12
	)

	pause_tween.tween_property(
		panel,
		"scale",
		Vector2(0.96, 0.96),
		0.12
	)

	pause_tween.chain().tween_callback(
		_finish_resuming
	)
```

Then add:

```
func _finish_resuming() -> void:
	hide()

	backdrop.modulate.a = 1.0
	panel.modulate.a = 1.0
	panel.scale = Vector2.ONE

	_set_buttons_disabled(false)
	get_tree().paused = false
```

Important: select `PauseMenu` and confirm:

```
Process → Mode: Always
```

Run the game and press `Escape`. The backdrop should fade in while the panel gently pops into place; resuming should reverse the effect before gameplay continues.