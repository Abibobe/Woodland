
We’ll add lightweight procedural wildlife:

- Butterflies appear during morning and afternoon.
- Fireflies appear during evening and night.
- They move in small local loops rather than crossing the whole map.
- Their positions are deterministic for each world seed.
- They have no collision or gameplay behavior.

### 1. Create `forest_life.gd`

Create:

```
res://scripts/game/forest_life.gd
```

Add:

```
class_name ForestLife
extends Node2D


enum LifeType {
	BUTTERFLY,
	FIREFLY
}


@export_category("Wildlife Counts")
@export_range(0, 100) var butterfly_count := 24
@export_range(0, 150) var firefly_count := 36

@export_category("Wildlife Colours")
@export var butterfly_yellow := Color("#f2d479")
@export var butterfly_blue := Color("#83a8c9")
@export var firefly_color := Color("#dff27a")


var life_points: Array[Dictionary] = []
var random := RandomNumberGenerator.new()

var current_phase := "morning"
var animation_time := 0.0


func _ready() -> void:
	z_index = 2
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
```

### 2. Generate the wildlife positions

Add:

```
func generate_life(
	seed_value: int,
	map_width: int,
	map_height: int,
	tile_size: int
) -> void:
	life_points.clear()
	random.seed = seed_value + 148_217

	var world_size := Vector2(
		map_width * tile_size,
		map_height * tile_size
	)

	for index in range(butterfly_count):
		_add_life_point(
			LifeType.BUTTERFLY,
			world_size
		)

	for index in range(firefly_count):
		_add_life_point(
			LifeType.FIREFLY,
			world_size
		)

	queue_redraw()


func _add_life_point(
	life_type: LifeType,
	world_size: Vector2
) -> void:
	var base_position := Vector2(
		random.randf_range(
			32.0,
			world_size.x - 32.0
		),
		random.randf_range(
			64.0,
			world_size.y - 32.0
		)
	)

	life_points.append({
		"type": life_type,
		"base_position": base_position,
		"phase_offset": random.randf_range(0.0, TAU),
		"speed": random.randf_range(0.65, 1.25),
		"variant": random.randi_range(0, 1)
	})
```

### 3. React to the time of day

Add:

```
func set_phase(phase: String) -> void:
	current_phase = phase.to_lower()
	queue_redraw()


func _process(delta: float) -> void:
	animation_time += delta
	queue_redraw()
```

This uses the existing process loop only for tiny decorative drawing operations.

### 4. Draw the appropriate wildlife

Add:

```
func _draw() -> void:
	var show_butterflies := (
		current_phase == "morning"
		or current_phase == "afternoon"
	)

	var show_fireflies := (
		current_phase == "evening"
		or current_phase == "night"
	)

	for life_point in life_points:
		var life_type := int(
			life_point["type"]
		)

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
```

### 5. Draw butterflies

```
func _draw_butterfly(
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

	var draw_position := (
		base_position
		+ Vector2(
			sin(motion_time) * 10.0,
			cos(motion_time * 0.7) * 6.0
		)
	).round()

	var selected_color := butterfly_yellow

	if variant == 1:
		selected_color = butterfly_blue

	var wing_open := (
		sin(motion_time * 7.0) > 0.0
	)

	if wing_open:
		draw_rect(
			Rect2(
				draw_position + Vector2(-3.0, -1.0),
				Vector2(2.0, 2.0)
			),
			selected_color
		)

		draw_rect(
			Rect2(
				draw_position + Vector2(2.0, -1.0),
				Vector2(2.0, 2.0)
			),
			selected_color
		)
	else:
		draw_rect(
			Rect2(
				draw_position + Vector2(-1.0, -2.0),
				Vector2(1.0, 3.0)
			),
			selected_color
		)

		draw_rect(
			Rect2(
				draw_position + Vector2(1.0, -2.0),
				Vector2(1.0, 3.0)
			),
			selected_color
		)

	draw_rect(
		Rect2(
			draw_position,
			Vector2(1.0, 2.0)
		),
		Color("#443729")
	)
```

### 6. Draw fireflies

```
func _draw_firefly(
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

	var motion_time := (
		animation_time * speed
		+ phase_offset
	)

	var draw_position := (
		base_position
		+ Vector2(
			sin(motion_time * 0.8) * 7.0,
			cos(motion_time) * 5.0
		)
	).round()

	var brightness := (
		sin(motion_time * 2.4) * 0.5
		+ 0.5
	)

	var glow_color := firefly_color
	glow_color.a = 0.08 + brightness * 0.18

	var center_color := firefly_color
	center_color.a = 0.4 + brightness * 0.6

	draw_circle(
		draw_position,
		4.0,
		glow_color
	)

	draw_circle(
		draw_position,
		1.0,
		center_color
	)
```

## 7. Add the node

Under `World` in `game.tscn`, add:

```
World
├── GroundRenderer
├── ForestDecorator
├── ForestLife
└── ResourceSpawner
```

Attach:

```
res://scripts/game/forest_life.gd
```

## 8. Generate wildlife with the world

In `world_generator.gd`, add:

```
@onready var forest_life: ForestLife = (
	$ForestLife
)
```

At the end of `generate_world()`, after generating decorations, add:

```
forest_life.generate_life(
	generated_seed,
	map_width,
	map_height,
	tile_size
)
```

## 9. Connect it to the day cycle

In `game_manager.gd`, add:

```
@onready var forest_life: ForestLife = (
	$World/ForestLife
)
```

Inside `_on_time_display_changed()`, add:

```
forest_life.set_phase(phase)
```

The function begins like this:

```
func _on_time_display_changed(
	day: int,
	phase: String
) -> void:
	hud.set_day(day, phase)
	forest_life.set_phase(phase)
	_update_world_tint(phase)
```

## Test

Verify that:

- Butterflies appear in morning and afternoon.
- Butterflies disappear in evening and night.
- Fireflies appear in evening and night.
- Wildlife does not block or interact with the player.
- A fixed world seed produces the same wildlife locations.
- Movement remains subtle rather than distracting.
- Performance remains smooth across the full map.

The next refinement will be controlling wildlife placement so butterflies prefer flower clearings and fireflies prefer darker forest clusters.