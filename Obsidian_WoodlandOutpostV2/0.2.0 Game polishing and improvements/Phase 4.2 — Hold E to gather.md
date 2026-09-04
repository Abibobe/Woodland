Now `PlayerInteraction` will advance the selected resource while `E` remains held. Releasing the key or moving pauses progress without resetting it.

### 1. Add gathering state

In `player_interaction.gd`, beneath `highlighted_target`, add:

```
var active_gathering_resource: ResourceNode
var gathering_request_sent := false
```

### 2. Replace `_unhandled_input()`

Replace the existing function with:

```
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if event is InputEventKey and event.echo:
			return

		var target := _get_closest_target()

		if target is ResourceNode:
			_start_gathering(target as ResourceNode)
			get_viewport().set_input_as_handled()
			return

		# Camps and other targets still use a single press.
		interact()
		return

	if event.is_action_released("interact"):
		_stop_gathering()
```

### 3. Add `_process()`

Add this beneath `_ready()`:

```
func _process(delta: float) -> void:
	if not is_processing_unhandled_input():
		_stop_gathering()
		return

	if not Input.is_action_pressed("interact"):
		_stop_gathering()
		return

	if active_gathering_resource == null:
		return

	if not is_instance_valid(active_gathering_resource):
		_stop_gathering()
		return

	if not has_target(active_gathering_resource):
		_stop_gathering()
		return

	var player := get_parent() as Player

	if player == null:
		_stop_gathering()
		return

	# Moving pauses gathering but preserves progress.
	if player.velocity.length_squared() > 0.0:
		return

	if gathering_request_sent:
		return

	var gathering_finished := (
		active_gathering_resource.advance_gathering(delta)
	)

	if gathering_finished:
		_request_gathering_completion()
```

### 4. Add the gathering helper functions

Add these beneath `_process()`:

```
func _start_gathering(resource: ResourceNode) -> void:
	if resource == null:
		return

	if resource.is_depleted:
		return

	active_gathering_resource = resource
	gathering_request_sent = false


func _stop_gathering() -> void:
	active_gathering_resource = null
	gathering_request_sent = false


func _request_gathering_completion() -> void:
	if active_gathering_resource == null:
		return

	gathering_request_sent = true

	var result := active_gathering_resource.interact()

	if not result.is_empty():
		interaction_completed.emit(result)
```

The completion request is sent only once per key hold. This prevents the “backpack full” warning from appearing every frame.

### 5. Update `game_manager.gd`

Inside the `"resource_requested"` section, find:

```
var gathered_amount := resource.collect(
	requested_amount
)
```

Replace it with:

```
var gathered_amount := resource.complete_gathering(
	requested_amount
)
```

This ensures the resource can only be awarded once its gathering progress reaches 100%.

## Test it

Use these checks:

1. Stand still near a resource and hold `E`.
2. Food should complete after approximately 2 seconds.
3. Wood should complete after approximately 3 seconds.
4. Stone should complete after approximately 4 seconds.
5. Release `E` early, then hold it again—the remaining time should be shorter.
6. Move while holding `E`—progress should pause.
7. Stop moving while still holding `E`—progress should resume.
8. A camp should still open with one normal press of `E`.
9. After collecting one unit, release and hold `E` again to collect the next unit.

There is no visible bar yet, but the timing and saved progress should now work. The next step is adding the progress bar above each selected resource.