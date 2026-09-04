Next, we can add gathering feedback: trees, rocks, and bushes will briefly shake when interacted with, then smoothly disappear when depleted instead of vanishing instantly.

### 1. Add animation state

In `resource_node.gd`, add:

```
var interaction_tween: Tween
var is_gather_animation_playing: bool = false
var is_depleted: bool = false
```

### 2. Update `interact()`

Replace it with:

```
func interact() -> Dictionary:
	if is_gather_animation_playing or is_depleted:
		return {}

	var gathered_amount := gather(1)

	if gathered_amount <= 0:
		return {}

	return {
		"action": "resource_collected",
		"resource_type": resource_type,
		"amount": gathered_amount,
		"target_depleted": is_depleted
	}
```

### 3. Replace `gather()`

```
func gather(requested_amount: int = 1) -> int:
	if requested_amount <= 0 or is_depleted:
		return 0

	var gathered_amount := mini(
		requested_amount,
		resource_amount
	)

	resource_amount -= gathered_amount

	if resource_amount <= 0:
		is_depleted = true
		set_highlighted(false)
		_play_depletion_animation()
	else:
		_play_gather_animation()

	return gathered_amount
```

### 4. Add the shake animation

```
func _play_gather_animation() -> void:
	is_gather_animation_playing = true

	if interaction_tween != null:
		interaction_tween.kill()

	var original_position := position

	interaction_tween = create_tween()

	interaction_tween.tween_property(
		self,
		"position",
		original_position + Vector2(-2.0, 0.0),
		0.04
	)

	interaction_tween.tween_property(
		self,
		"position",
		original_position + Vector2(2.0, 0.0),
		0.06
	)

	interaction_tween.tween_property(
		self,
		"position",
		original_position,
		0.04
	)

	interaction_tween.tween_callback(
		func() -> void:
			is_gather_animation_playing = false
	)
```

### 5. Add the depletion animation

```
func _play_depletion_animation() -> void:
	is_gather_animation_playing = true

	if interaction_tween != null:
		interaction_tween.kill()

	interaction_tween = create_tween()
	interaction_tween.set_parallel(true)

	interaction_tween.tween_property(
		self,
		"scale",
		Vector2(0.75, 0.75),
		0.2
	)

	interaction_tween.tween_property(
		self,
		"modulate:a",
		0.0,
		0.2
	)

	interaction_tween.set_parallel(false)

	interaction_tween.tween_callback(
		queue_free
	)
```

### 6. Stop targeting depleted resources

In `player_interaction.gd`, find:

```
if target.is_queued_for_deletion():
	nearby_targets.erase(target)
```

Replace it with:

```
var target_depleted := bool(
	result.get("target_depleted", false)
)

if (
	target_depleted
	or target.is_queued_for_deletion()
):
	nearby_targets.erase(target)
```

Now each successful gathering action briefly shakes the resource. On the final gather, it shrinks and fades while being removed immediately from interaction targeting, so the prompt and golden brackets do not linger.