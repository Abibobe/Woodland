Now we’ll redirect gathered resources into the backpack without allowing a full backpack to destroy resources.

### 1. Change `ResourceNode.interact()`

In `resource_node.gd`, replace `interact()` with:

```
func interact() -> Dictionary:
	if is_gather_animation_playing or is_depleted:
		return {}

	return {
		"action": "resource_requested",
		"resource": self,
		"resource_type": resource_type,
		"amount": 1
	}
```

This now requests collection without modifying the resource.

Add this separate completion function:

```
func collect(requested_amount: int = 1) -> int:
	if is_gather_animation_playing or is_depleted:
		return 0

	var gathered_amount := gather(
		requested_amount
	)

	if gathered_amount > 0:
		_play_gather_sound()

	return gathered_amount
```

The order is now:

```
Request → Capacity check → Collect → Backpack
```

### 2. Add safe target removal

In `player_interaction.gd`, add:

```
func remove_target(
	target: InteractionTarget
) -> void:
	nearby_targets.erase(target)

	if highlighted_target == target:
		_set_highlighted_target(null)

	_refresh_interaction_prompt()
```

### 3. Update `GameManager`

In `_on_interaction_completed()`, replace the complete `"resource_collected"` branch with:

```
"resource_requested":
	var resource := (
		result.get("resource") as ResourceNode
	)

	if resource == null:
		return

	var resource_type := int(
		result.get("resource_type", -1)
	)

	var requested_amount := int(
		result.get("amount", 1)
	)

	if not backpack.can_add(
		resource_type,
		requested_amount
	):
		_show_backpack_full()
		return

	var gathered_amount := resource.collect(
		requested_amount
	)

	if gathered_amount <= 0:
		return

	var resource_added := backpack.add_resource(
		resource_type,
		gathered_amount
	)

	if not resource_added:
		push_warning(
			"Backpack capacity changed during collection."
		)
		return

	var resource_name := (
		ResourceTypes.get_display_name(
			resource_type
		)
	)

	var player_screen_position := (
		get_viewport().get_canvas_transform()
		* player.global_position
	)

	hud.show_resource_gain(
		"+%d %s" % [
			gathered_amount,
			resource_name
		],
		player_screen_position
	)

	if resource.is_depleted:
		player_interaction.remove_target(
			resource
		)
	else:
		player_interaction.refresh_prompt()
```

The `"camp_opened"` branch and fallback branch remain unchanged.

### 4. Add the full-backpack response

Add this function to `game_manager.gd`:

```
func _show_backpack_full() -> void:
	_play_ui_denied()

	var player_screen_position := (
		get_viewport().get_canvas_transform()
		* player.global_position
	)

	hud.show_resource_gain(
		"Backpack full — return to camp",
		player_screen_position
	)
```

### 5. Make the floating message wide enough

In `hud.gd`, find this line inside `show_resource_gain()`:

```
resource_gain_popup.size = Vector2(120.0, 24.0)
```

Replace it with:

```
resource_gain_popup.size = Vector2(280.0, 24.0)
```

Then change:

```
screen_position.x - 60.0
```

to:

```
screen_position.x - 140.0
```

This keeps both short gain messages and the longer backpack warning centered.

## Test combinations

The top-bar Wood, Stone, and Food counters now represent camp storage, so they should remain at zero while gathering.

The backpack should behave like this:

|Gathered items|Weight|
|---|---|
|1 Food|1/12|
|1 Wood|2/12|
|1 Stone|3/12|
|3 Wood + 2 Stone|12/12|
|Another item|Denied|

Verify:d

- Successful gathering increases backpack weight.
- Camp storage counters do not increase.
- A resource shakes and loses one unit only after capacity succeeds.
- A full backpack plays the denied sound.
- A denied resource retains its amount.
- The warning is fully readable.
- Construction remains unavailable because carried resources have not been deposited yet.

That last point is expected. Camp depositing is our next phase.