Let’s refine the camp shadows so every construction stage has the right footprint—not just “shadow or no shadow.”
### 1. Change the beginning of `_draw()`

In `camp.gd`, replace:

```
if current_stage != CampStage.SITE:
	_draw_shadow()
```

with:

```
_draw_stage_shadow()
```

Your function should begin like this:

```
func _draw() -> void:
	_draw_stage_shadow()

	if stages_texture != null:
		_draw_stage_texture()
		return

	# Keep the existing fallback match here.
```

### 2. Replace `_draw_shadow()`

Remove the previous shadow function and add:

```
func _draw_stage_shadow() -> void:
	match current_stage:
		CampStage.SITE:
			return

		CampStage.CAMPFIRE:
			_draw_shadow(9.0, 3.0)

		CampStage.FOUNDATION:
			_draw_shadow(18.0, 5.0)

		CampStage.CABIN:
			_draw_shadow(22.0, 5.0)
```

Then add the reusable drawing function:

```
func _draw_shadow(
	radius: float,
	y_offset: float
) -> void:
	draw_set_transform(
		Vector2(0.0, y_offset),
		0.0,
		Vector2(1.0, 0.3)
	)

	draw_circle(
		Vector2.ZERO,
		radius,
		SHADOW_COLOR
	)

	draw_set_transform(
		Vector2.ZERO,
		0.0,
		Vector2.ONE
	)
```

Now the visual progression is more natural:

- Construction site: no shadow.
- Campfire: small shadow.
- Foundation: medium shadow.
- Cabin: full building shadow.

This keeps all stages anchored without making an empty or partially built site look like a completed building.