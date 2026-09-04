We’ll display a short golden `+1 WOOD`, `+1 STONE`, or `+1 FOOD` above the resource only after the item successfully enters the backpack.

Because the popup is added to the resource’s parent, it can finish animating even when the depleted resource disappears.

### 1. Add the popup function

Add this to `resource_node.gd`:

```
func _show_collection_popup(
	gathered_amount: int
) -> void:
	if gathered_amount <= 0:
		return

	var popup := Label.new()

	popup.text = "+%d %s" % [
		gathered_amount,
		get_resource_name().to_upper()
	]

	popup.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	popup.custom_minimum_size = Vector2(
		100.0,
		24.0
	)

	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.z_as_relative = false
	popup.z_index = 250

	popup.add_theme_font_size_override(
		"font_size",
		14
	)

	popup.add_theme_color_override(
		"font_color",
		Color("#f2d479")
	)

	popup.add_theme_color_override(
		"font_outline_color",
		Color("#17231d")
	)

	popup.add_theme_constant_override(
		"outline_size",
		3
	)

	get_parent().add_child(popup)

	popup.global_position = (
		global_position
		+ Vector2(-50.0, _get_popup_start_y())
	)

	popup.pivot_offset = Vector2(
		50.0,
		12.0
	)

	popup.scale = Vector2(0.75, 0.75)

	var popup_tween := popup.create_tween()
	popup_tween.set_parallel(true)

	popup_tween.tween_property(
		popup,
		"position:y",
		popup.position.y - 20.0,
		0.55
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	popup_tween.tween_property(
		popup,
		"scale",
		Vector2.ONE,
		0.14
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	popup_tween.tween_property(
		popup,
		"modulate:a",
		0.0,
		0.25
	).set_delay(
		0.3
	)

	popup_tween.set_parallel(false)

	popup_tween.tween_callback(
		popup.queue_free
	)
```

### 2. Give each resource an appropriate height

Add:

```
func _get_popup_start_y() -> float:
	match resource_type:
		ResourceTypes.Type.WOOD:
			return -82.0

		ResourceTypes.Type.STONE:
			return -47.0

		ResourceTypes.Type.FOOD:
			return -53.0

	return -55.0
```

This places the message above both the sprite and its progress bar.

### 3. Trigger it after a successful collection

In `complete_gathering()`, update the successful section:

```
if gathered_amount > 0:
	_show_collection_popup(
		gathered_amount
	)

	gathering_elapsed = 0.0
	gathering_feedback_elapsed = 0.0

	_update_gathering_progress_bar()
	set_gathering_active(false)
```

The complete function should now be:

```
func complete_gathering(
	requested_amount: int = 1
) -> int:
	if not is_gathering_complete():
		return 0

	var gathered_amount := collect(
		requested_amount
	)

	if gathered_amount > 0:
		_show_collection_popup(
			gathered_amount
		)

		gathering_elapsed = 0.0
		gathering_feedback_elapsed = 0.0

		_update_gathering_progress_bar()
		set_gathering_active(false)

	return gathered_amount
```

### Expected behavior

- Regular gathering beats produce movement, sound, and particles.
- Completing one unit produces a distinct golden message.
- Holding `E` immediately starts gathering the next unit.
- A full backpack produces no popup because nothing was collected.
- The final popup remains visible even while a depleted resource fades away.

FIX:: We have 2 popup!
Exactly—the old popup is created by the HUD after `GameManager` adds the resource to the backpack. The new popup in `resource_node.gd` now replaces it.

We should disable only the old call, while keeping the HUD function available.

In `game_manager.gd`, search for:

```
hud.show_resource_gain(
```

Find the call inside the resource-collection logic. It will probably look similar to:

```
hud.show_resource_gain(
	"+%d %s" % [
		gathered_amount,
		ResourceTypes.get_display_name(resource_type)
	],
	_get_player_screen_position()
)
```

Remove that entire call.

Do not remove the `show_resource_gain()` function from `hud.gd`; it may still be useful for other notifications later.

Afterwards, successful gathering will show only the new popup above the resource:

```
+1 FOOD
```

Backpack updates and all other gathering behavior will remain unchanged.