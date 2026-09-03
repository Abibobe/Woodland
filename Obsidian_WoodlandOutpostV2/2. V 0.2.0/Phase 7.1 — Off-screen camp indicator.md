
We’ll add a simple golden directional arrow that appears only when the camp is outside the visible play area.

### 1. Add the indicator node

Under `Interface`, add a `Control` node:

```
Interface
├── HUD
├── ...
└── CampIndicator
```

Configure it:

```
Custom Minimum Size: 28 × 28
Mouse → Filter: Ignore
Ordering → Z Index: 40
```

Attach a new script:

```
res://scripts/ui/camp_indicator.gd
```

### 2. Add the indicator script

```
class_name CampIndicator
extends Control


@export_category("World References")
@export var player:d: Node2D
@export var camp: Node2D

@export_category("Screen Placement")
@export var side_margin := 42.0
@export var top_margin := 70.0
@export var bottom_margin := 42.0


const ARROW_COLOR := Color("#f2d479")
const ARROW_OUTLINE_COLOR := Color("#583f24")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(28.0, 28.0)
	pivot_offset = size / 2.0
	hide()

	queue_redraw()


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		hide()
		return

	if not is_instance_valid(camp):
		hide()
		return

	var viewport_size := (
		get_viewport().get_visible_rect().size
	)

	var camp_screen_position := (
		get_viewport().get_canvas_transform()
		* camp.global_position
	)

	var visible_area := Rect2(
		Vector2(
			side_margin,
			top_margin
		),
		Vector2(
			viewport_size.x - side_margin * 2.0,
			viewport_size.y
				- top_margin
				- bottom_margin
		)
	)

	if visible_area.has_point(camp_screen_position):
		hide()
		return

	show()

	var screen_center := viewport_size / 2.0
	var direction := (
		camp_screen_position
		- screen_center
	).normalized()

	var available_half_size := Vector2(
		visible_area.size.x / 2.0,
		visible_area.size.y / 2.0
	)

	var horizontal_scale := INF
	var vertical_scale := INF

	if absf(direction.x) > 0.001:
		horizontal_scale = (
			available_half_size.x
			/ absf(direction.x)
		)

	if absf(direction.y) > 0.001:
		vertical_scale = (
			available_half_size.y
			/ absf(direction.y)
		)

	var edge_distance := minf(
		horizontal_scale,
		vertical_scale
	)

	var indicator_center := (
		visible_area.get_center()
		+ direction * edge_distance
	)

	position = indicator_center - size / 2.0
	rotation = direction.angle()


func _draw() -> void:
	var arrow_points := PackedVector2Array([
		Vector2(13.0, 0.0),
		Vector2(-9.0, -9.0),
		Vector2(-5.0, 0.0),
		Vector2(-9.0, 9.0)
	])

	draw_colored_polygon(
		arrow_points,
		ARROW_COLOR
	)

	var outline_points := PackedVector2Array([
		Vector2(13.0, 0.0),
		Vector2(-9.0, -9.0),
		Vector2(-5.0, 0.0),
		Vector2(-9.0, 9.0),
		Vector2(13.0, 0.0)
	])

	draw_polyline(
		outline_points,
		ARROW_OUTLINE_COLOR,
		2.0,
		false
	)
```

### 3. Assign its references

Select `CampIndicator` in `game.tscn`.

Drag these nodes into its Inspector fields:

```
World References
├── Player: Entities/Player
└── Camp:   Entities/Camp
```

### 4. Test it

Walk far enough that the camp leaves the screen:

- The golden arrow should appear near the screen edge.
- It should rotate toward the camp.
- It should remain below the HUD.
- Walking back toward camp should eventually hide it.
- It should not intercept mouse clicks.

This gives the larger map its essential navigation support without adding a minimap.