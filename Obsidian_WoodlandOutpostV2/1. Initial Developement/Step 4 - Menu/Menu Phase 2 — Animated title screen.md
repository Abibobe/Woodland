The next logical step is animating the main menu’s entrance and its transition into gameplay.

### 1. Add node references

In `main_menu.gd`, add:

```
@onready var background: ColorRect = $Background

@onready var menu_panel: PanelContainer = (
	$CenterContainer/MenuPanel
)

var menu_tween: Tween
```

### 2. Start the entrance animation

At the end of `_ready()`, add:

```
call_deferred("_play_intro_animation")
```

Do not call `grab_focus()` on any button.

Add:

```
func _play_intro_animation() -> void:
	if menu_tween != null:
		menu_tween.kill()

	background.modulate.a = 0.0
	menu_panel.modulate.a = 0.0
	menu_panel.scale = Vector2(0.9, 0.9)
	menu_panel.pivot_offset = menu_panel.size / 2.0

	menu_tween = create_tween()
	menu_tween.set_parallel(true)

	menu_tween.tween_property(
		background,
		"modulate:a",
		1.0,
		0.25
	)

	menu_tween.tween_property(
		menu_panel,
		"modulate:a",
		1.0,
		0.18
	)

	menu_tween.tween_property(
		menu_panel,
		"scale",
		Vector2.ONE,
		0.3
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)
```

### 3. Replace `_start_game()`

Replace:

```
func _start_game() -> void:
	hide()
	get_tree().paused = false
```

with:

```
func _start_game() -> void:
	_set_buttons_disabled(true)

	if menu_tween != null:
		menu_tween.kill()

	menu_tween = create_tween()
	menu_tween.set_parallel(true)

	menu_tween.tween_property(
		background,
		"modulate:a",
		0.0,
		0.25
	)

	menu_tween.tween_property(
		menu_panel,
		"modulate:a",
		0.0,
		0.18
	)

	menu_tween.tween_property(
		menu_panel,
		"scale",
		Vector2(1.05, 1.05),
		0.22
	)

	menu_tween.set_parallel(false)

	menu_tween.tween_callback(
		_finish_starting_game
	)
```

### 4. Add the completion function

```
func _finish_starting_game() -> void:
	hide()
	get_tree().paused = false
```

Because `MainMenu` uses `Process Mode: Always`, both animations continue while the game is paused.

The result is:

- The dark background fades in.
- The menu panel gently pops into place.
- Pressing Start disables repeat clicks.
- The panel expands slightly and fades away.
- Gameplay begins only after the transition finishes.