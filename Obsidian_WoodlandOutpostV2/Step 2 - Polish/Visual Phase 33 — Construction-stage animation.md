
Let’s give each camp upgrade a satisfying build transition instead of switching artwork instantly.

### 1. Add a tween variable

In `camp.gd`, add:

```
var construction_tween: Tween
```

### 2. Update `advance_construction()`

Add `_play_construction_animation()` immediately after changing the stage:

```
func advance_construction() -> bool:
	if current_stage == CampStage.CABIN:
		return false

	current_stage += 1
	_play_construction_animation()

	stage_changed.emit(current_stage)

	return true
```

### 3. Add the animation function

```
func _play_construction_animation() -> void:
	if construction_tween != null:
		construction_tween.kill()

	scale = Vector2(0.82, 0.82)
	modulate.a = 0.45

	construction_tween = create_tween()
	construction_tween.set_parallel(true)

	construction_tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		0.28
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	construction_tween.tween_property(
		self,
		"modulate:a",
		1.0,
		0.18
	)
```

The new camp stage will now fade and “pop” into place. Since construction happens while the camp menu has disabled player movement, the brief scaling won’t interfere with gameplay or collision.