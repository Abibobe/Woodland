First, we’ll add occasional leaves drifting through the forest. They remain purely visual and use the existing lightweight `ForestLife` drawing system.

### 1. Add the new life type

In `forest_life.gd`, update the enum:

```
enum LifeType {
	BUTTERFLY,
	FIREFLY,
	LEAF
}
```

### 2. Add leaf settings

Under the wildlife counts, add:

```
@export_range(0, 100) var drifting_leaf_count := 28
```

Under the colour exports, add:

```
@export var leaf_green := Color("#567d3d")
@export var leaf_brown := Color("#9a6841")
@export var leaf_gold := Color("#b99648")
```

### 3. Generate the leaves

In `generate_life()`, after the firefly loop, add:

```
for index in range(drifting_leaf_count):
	_add_life_point(
		LifeType.LEAF,
		world_size,
		[]
	)
```

If Godot cannot infer the empty array’s type, use:

```
var no_habitats: Array[Vector2] = []

for index in range(drifting_leaf_count):
	_add_life_point(
		LifeType.LEAF,
		world_size,
		no_habitats
	)
```

The second version is the safest.

### 4. Draw leaves during suitable phases

Inside `_draw()`, add:

```
var show_leaves := (
	current_phase == "morning"
	or current_phase == "afternoon"
	or current_phase == "evening"
)
```

Then, inside the `for life_point in life_points` loop, after the firefly condition, add:

```
elif (
	life_type == LifeType.LEAF
	and show_leaves
):
	_draw_leaf(life_point)
```

The full decision section becomes:

```
if (
	life_type == LifeType.BUTTERFLY
	and show_butterflies
):
	_draw_butterfly(life_point)

elif (
	life_type == LifeType.FIREFLY
	and show_fireflies
):
	_draw_firefly(life_point)

elif (
	life_type == LifeType.LEAF
	and show_leaves
):
	_draw_leaf(life_point)
```

### 5. Add the leaf drawing function

Add this beneath `_draw_firefly()`:

```
func _draw_leaf(
	life_point: Dictionary
) -> void:
	var base_position := (
		life_point["base_position"] as Vector2
	)

	var phase_offset := float(
		life_point["phase_offset"]
	)

	var speed := float(
		life_point["speed"]
	)

	var variant := int(
		life_point["variant"]
	)

	var motion_time := (
		animation_time * speed
		+ phase_offset
	)

	var drift_cycle := fposmod(
		motion_time,
		TAU
	)

	var horizontal_drift := (
		sin(motion_time * 0.65) * 18.0
		+ drift_cycle * 5.0
	)

	var vertical_drift := (
		drift_cycle * 7.0
		+ sin(motion_time * 1.4) * 3.0
	)

	var draw_position := (
		base_position
		+ Vector2(
			horizontal_drift,
			vertical_drift
		)
	)

	var selected_color := leaf_green

	if variant == 1:
		selected_color = leaf_brown

	if current_phase == "evening":
		selected_color = leaf_gold.darkened(0.15)

	var leaf_direction := Vector2(
		3.0,
		sin(motion_time * 2.0) * 2.0
	)

	draw_line(
		draw_position,
		draw_position + leaf_direction,
		selected_color,
		2.0
	)

	draw_circle(
		draw_position + leaf_direction,
		1.2,
		selected_color.lightened(0.12)
	)
```

### Result

The leaves will:

- Drift slowly sideways and downward.
- Bob independently rather than moving as one group.
- Use green and brown shades during the day.
- Become warmer during the evening.
- Disappear at night, leaving fireflies as the main ambient effect.
- Add no collisions or interactive nodes.
- Remain deterministic with a fixed world seed.

For the campfire embers, send me the latest `camp.gd`. Their visibility should be connected to the actual camp stage so they appear only after the campfire has been built.