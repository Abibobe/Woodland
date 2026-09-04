
We’ll animate grass, flowers, and ferns only. Pebbles, branches, and mushrooms remain still, creating a subtle breeze without affecting gameplay.

### 1. Add movement settings

In `forest_decorator.gd`, beneath the colour exports, add:

```
@export_category("Wind Animation")
@export_range(0.0, 3.0, 0.05) var wind_strength := 1.25
@export_range(0.1, 3.0, 0.05) var wind_speed := 0.8
```

Near the other variables, add:

```
var animation_time := 0.0
```

### 2. Animate the decorator

Add:

```
func _process(delta: float) -> void:
	animation_time += delta
	queue_redraw()
```

Because all decorations are drawn together, this adds no extra nodes or collision objects.

### 3. Calculate deterministic movement

Add this helper above `_draw()`:

```
func _get_wind_offset(
	draw_position: Vector2,
	movement_scale: float = 1.0
) -> Vector2:
	var position_phase := (
		draw_position.x * 0.018
		+ draw_position.y * 0.011
	)

	var movement := sin(
		animation_time * wind_speed
		+ position_phase
	)

	return Vector2(
		movement * wind_strength * movement_scale,
		0.0
	)
```

The position creates a different animation phase for every decoration, preventing everything from swaying simultaneously.

### 4. Update `_draw_grass()`

At the beginning of the function, add:

```
var wind_offset := _get_wind_offset(
	draw_position,
	1.0
)
```

Then replace the three grass endpoints with:

```
draw_line(
	draw_position,
	draw_position
		+ Vector2(-2.0, -5.0)
		+ wind_offset,
	selected_color,
	1.0
)

draw_line(
	draw_position,
	draw_position
		+ Vector2(0.0, -6.0)
		+ wind_offset,
	selected_color,
	1.0
)

draw_line(
	draw_position,
	draw_position
		+ Vector2(3.0, -4.0)
		+ wind_offset,
	selected_color,
	1.0
)
```

### 5. Replace `_draw_flower()`

```
func _draw_flower(
	draw_position: Vector2,
	variant: int
) -> void:
	var wind_offset := _get_wind_offset(
		draw_position,
		0.75
	)

	var selected_color := flower_yellow

	if variant == 1:
		selected_color = flower_blue
	elif variant == 2:
		selected_color = flower_white

	draw_line(
		draw_position + Vector2(0.0, 1.0),
		draw_position
			+ Vector2(0.0, -3.0)
			+ wind_offset,
		grass_dark,
		1.0
	)

	draw_rect(
		Rect2(
			draw_position
				+ Vector2(-1.0, -5.0)
				+ wind_offset,
			Vector2(3.0, 3.0)
		),
		selected_color
	)
```

The flower head now moves while the stem remains rooted.

### 6. Replace `_draw_fern()`

```
func _draw_fern(
	draw_position: Vector2,
	variant: int
) -> void:
	var height := 6.0

	if variant == 2:
		height = 8.0

	var wind_offset := _get_wind_offset(
		draw_position,
		0.65
	)

	var fern_tip := (
		draw_position
		+ Vector2(0.0, -height)
		+ wind_offset
	)

	draw_line(
		draw_position,
		fern_tip,
		fern_color,
		1.0
	)

	for leaf_index in range(1, 4):
		var leaf_y := float(leaf_index * 2)
		var movement_ratio := leaf_y / height
		var leaf_offset := wind_offset * movement_ratio

		var leaf_origin := (
			draw_position
			+ Vector2(0.0, -leaf_y)
			+ leaf_offset
		)

		draw_line(
			leaf_origin,
			leaf_origin + Vector2(-3.0, -2.0),
			fern_color,
			1.0
		)

		draw_line(
			leaf_origin,
			leaf_origin + Vector2(3.0, -2.0),
			fern_color,
			1.0
		)
```

### Test

Watch a flower patch and a fern area without moving:

- Vegetation should sway gently from side to side.
- Nearby plants should move at slightly different times.
- Decoration positions should remain unchanged between identical seeds.
- Resources, gathering, collisions, and wildlife habitats should be unaffected.
- Pebbles, branches, and mushrooms should remain stationary.

If the movement looks too energetic, reduce `Wind Strength` to approximately `0.75`.