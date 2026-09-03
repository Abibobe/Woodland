We have a couple of issue to adress:

1. I wish to have that if the player keep pushed the E key, the game start gathering another resource (if possible)
2. when we keep pushed the E the label on the bottom fade almost to become invisible


## 1. Continue gathering while `E` remains held

In `player_interaction.gd`, replace `_process()` with:

```
func _process(delta: float) -> void:
	if not is_processing_unhandled_input():
		_stop_gathering()
		return

	if not Input.is_action_pressed("interact"):
		_stop_gathering()
		return

	# Automatically begin the next available resource while E
	# remains held.
	if not is_instance_valid(active_gathering_resource):
		var next_target := _get_closest_target()

		if next_target is ResourceNode:
			_start_gathering(
				next_target as ResourceNode
			)

		return

	if not has_target(active_gathering_resource):
		_stop_gathering()
		return

	var player := get_parent() as Player

	if player == null:
		_stop_gathering()
		return

	if player.velocity.length_squared() > 0.0:
		active_gathering_resource.set_gathering_active(
			false
		)
		return

	active_gathering_resource.set_gathering_active(true)

	interaction_prompt_changed.emit(
		active_gathering_resource.get_interaction_text()
	)

	if gathering_request_sent:
		return

	if active_gathering_resource.advance_gathering(delta):
		_request_gathering_completion()
```

Then replace `_request_gathering_completion()` with:

```
func _request_gathering_completion() -> void:
	if not is_instance_valid(active_gathering_resource):
		return

	gathering_request_sent = true

	var resource := active_gathering_resource
	var result := resource.interact()

	if not result.is_empty():
		interaction_completed.emit(result)

	# The resource may have been depleted and queued for deletion
	# by GameManager during the signal.
	if not is_instance_valid(resource):
		active_gathering_resource = null
		return

	if resource.is_depleted:
		resource.set_gathering_active(false)
		active_gathering_resource = null
		return

	# A successful collection resets progress to zero. Unlocking
	# here lets the next unit begin while E remains held.
	if not resource.is_gathering_complete():
		gathering_request_sent = false
		resource.set_gathering_active(true)
```

The result is:

- Holding `E` collects every available unit from the current node.
- When that node is depleted, gathering can move to the next closest resource inside the interaction area.
- A full backpack leaves progress at 100% and keeps the request locked, preventing repeated warning sounds.

## 2. Stop the prompt from fading repeatedly

In `hud.gd`, replace `show_interaction_prompt()` with:

```
func show_interaction_prompt(text: String) -> void:
	var clean_text := text

	if clean_text.begins_with("Press E to "):
		clean_text = clean_text.trim_prefix(
			"Press E to "
		)

	interaction_prompt_label.text = (
		clean_text.capitalize()
	)

	# When already visible, only update the text.
	# Do not restart the fade animation.
	if interaction_prompt.visible:
		return

	if interaction_prompt_tween != null:
		interaction_prompt_tween.kill()

	interaction_prompt.modulate.a = 0.0
	interaction_prompt.show()

	interaction_prompt_tween = create_tween()

	interaction_prompt_tween.tween_property(
		interaction_prompt,
		"modulate:a",
		1.0,
		0.12
	)
```

Previously, every percentage update reset the prompt opacity to `0.0`. Now the first call fades it in, while subsequent calls only change its text.

Test by holding `E` on a resource containing three units: the bar should complete three times continuously, and the bottom prompt should remain fully visible.