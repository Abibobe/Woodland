The four terrain tiles are clean 32×32 textures with subtle speckling, but they intentionally contain very little detail. That explains why the larger map feels empty.

The safest architecture is:

```
GroundRenderer        z = -100
ForestDecorator       z = -50
Entities/resources    y-sorted normally
```

The decorator will draw small non-colliding details between the terrain and gameplay objects. It will use its own seeded random generator and avoid the camp and resource cells.


### 1. Create the decorator script

Create:

```
res://scripts/game/forest_decorator.gd
```

Add:

```
class_name ForestDecorator
extends Node2D


enum DecorationType {
	GRASS,
	FLOWER,
	PEBBLE,
	BRANCH,
	MUSHROOM
}


@export_category("Decoration Density")
@export_range(0.0, 1.0, 0.01) var decoration_density := 0.32
@export_range(0, 3) var resource_clearance := 1
@export_range(0, 3) var camp_clearance := 1

@export_category("Decoration Colours")
@export var grass_dark := Color("#3f713e")
@export var grass_light := Color("#76a954")
@export var flower_yellow := Color("#e8cf68")
@export var flower_blue := Color("#7998c8")
@export var flower_white := Color("#e4dfc5")
@export var branch_color := Color("#62422b")
@export var pebble_color := Color("#777c74")
@export var mushroom_cap := Color("#a34d43")


var decorations: Array[Dictionary] = []
var random := RandomNumberGenerator.new()


func _ready() -> void:
	z_index = -50
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func generate_decorations(
	seed_value: int,
	ground_cells: Array,
	map_width: int,
	map_height: int,
	tile_size: int,
	map_center: Vector2i,
	camp_clear_radius: int,
	blocked_cells: Dictionary
) -> void:
	decorations.clear()
	random.seed = seed_value + 32_117

	for y in range(2, map_height - 1):
		for x in range(1, map_width - 1):
			var cell := Vector2i(x, y)

			# Soil remains clear in this first version.
			if bool(ground_cells[y][x]):
				continue

			var distance_from_camp := Vector2(
				cell
			).distance_to(
				Vector2(map_center)
			)

			if (
				distance_from_camp
				<= camp_clear_radius + camp_clearance
			):
				continue

			if _is_near_blocked_cell(
				cell,
				blocked_cells
			):
				continue

			if random.randf() > decoration_density:
				continue

			_add_decoration(
				cell,
				tile_size
			)

			# A few cells receive a second small detail.
			if random.randf() < 0.12:
				_add_decoration(
					cell,
					tile_size
				)

	queue_redraw()
```

### 2. Add the placement helpers

Continue in the same script:

```
func _add_decoration(
	cell: Vector2i,
	tile_size: int
) -> void:
	var cell_center := Vector2(
		(cell.x + 0.5) * tile_size,
		(cell.y + 0.5) * tile_size
	)

	var offset := Vector2(
		random.randi_range(-11, 11),
		random.randi_range(-11, 11)
	)

	var roll := random.randi_range(0, 99)
	var decoration_type := DecorationType.GRASS

	if roll < 62:
		decoration_type = DecorationType.GRASS
	elif roll < 77:
		decoration_type = DecorationType.FLOWER
	elif roll < 87:
		decoration_type = DecorationType.PEBBLE
	elif roll < 95:
		decoration_type = DecorationType.BRANCH
	else:
		decoration_type = DecorationType.MUSHROOM

	decorations.append({
		"type": decoration_type,
		"position": (cell_center + offset).round(),
		"variant": random.randi_range(0, 2)
	})


func _is_near_blocked_cell(
	cell: Vector2i,
	blocked_cells: Dictionary
) -> bool:
	for offset_y in range(
		-resource_clearance,
		resource_clearance + 1
	):
		for offset_x in range(
			-resource_clearance,
			resource_clearance + 1
		):
			var nearby_cell := (
				cell
				+ Vector2i(offset_x, offset_y)
			)

			if blocked_cells.has(nearby_cell):
				return true

	return false
```

### 3. Draw the decorations

Add:

```
func _draw() -> void:
	for decoration in decorations:
		var decoration_type := int(
			decoration["type"]
		)

		var draw_position := (
			decoration["position"] as Vector2
		)

		var variant := int(
			decoration["variant"]
		)

		match decoration_type:
			DecorationType.GRASS:
				_draw_grass(
					draw_position,
					variant
				)

			DecorationType.FLOWER:
				_draw_flower(
					draw_position,
					variant
				)

			DecorationType.PEBBLE:
				_draw_pebble(
					draw_position,
					variant
				)

			DecorationType.BRANCH:
				_draw_branch(
					draw_position,
					variant
				)

			DecorationType.MUSHROOM:
				_draw_mushroom(
					draw_position,
					variant
				)
```

Then add the individual pixel-art drawing functions:

```
func _draw_grass(
	draw_position: Vector2,
	variant: int
) -> void:
	var selected_color := (
		grass_light
		if variant == 0
		else grass_dark
	)

	draw_line(
		draw_position,
		draw_position + Vector2(-2.0, -5.0),
		selected_color,
		1.0
	)

	draw_line(
		draw_position,
		draw_position + Vector2(0.0, -6.0),
		selected_color,
		1.0
	)

	draw_line(
		draw_position,
		draw_position + Vector2(3.0, -4.0),
		selected_color,
		1.0
	)


func _draw_flower(
	draw_position: Vector2,
	variant: int
) -> void:
	draw_rect(
		Rect2(
			draw_position + Vector2(0.0, -3.0),
			Vector2(1.0, 4.0)
		),
		grass_dark
	)

	var selected_color := flower_yellow

	if variant == 1:
		selected_color = flower_blue
	elif variant == 2:
		selected_color = flower_white

	draw_rect(
		Rect2(
			draw_position + Vector2(-1.0, -5.0),
			Vector2(3.0, 3.0)
		),
		selected_color
	)


func _draw_pebble(
	draw_position: Vector2,
	variant: int
) -> void:
	var pebble_size := Vector2(3.0, 2.0)

	if variant == 2:
		pebble_size = Vector2(4.0, 3.0)

	draw_rect(
		Rect2(
			draw_position,
			pebble_size
		),
		pebble_color
	)


func _draw_branch(
	draw_position: Vector2,
	variant: int
) -> void:
	var branch_end := (
		draw_position
		+ Vector2(6.0, 2.0)
	)

	if variant == 1:
		branch_end = (
			draw_position
			+ Vector2(5.0, -2.0)
		)

	draw_line(
		draw_position,
		branch_end,
		branch_color,
		2.0
	)


func _draw_mushroom(
	draw_position: Vector2,
	variant: int
) -> void:
	draw_rect(
		Rect2(
			draw_position + Vector2(0.0, -1.0),
			Vector2(2.0, 3.0)
		),
		Color("#d7c29e")
	)

	var cap_width := 4.0

	if variant == 2:
		cap_width = 5.0

	draw_rect(
		Rect2(
			draw_position + Vector2(
				-(cap_width - 2.0) / 2.0,
				-3.0
			),
			Vector2(cap_width, 2.0)
		),
		mushroom_cap
	)
```

## 4. Expose occupied resource cells

At the end of `resource_spawner.gd`, add:

```
func get_occupied_cells() -> Dictionary:
	return occupied_cells.duplicate()
```

This gives the decorator a safe read-only copy. It cannot modify the actual resource-placement state.

## 5. Add the decorator node

Under `World` in `game.tscn`, add:

```
World
├── GroundRenderer
├── ForestDecorator
└── ResourceSpawner
```

Attach:

```
res://scripts/game/forest_decorator.gd
```

No scenes, collision shapes, or textures are needed.

## 6. Connect it to world generation

In `world_generator.gd`, add:

```
@onready var forest_decorator: ForestDecorator = (
	$ForestDecorator
)
```

Then, immediately after `generate_resources()`, add:

```
var map_center := Vector2i(
	map_width / 2,
	map_height / 2
)

forest_decorator.generate_decorations(
	generated_seed,
	ground_cells,
	map_width,
	map_height,
	tile_size,
	map_center,
	resource_spawner.clear_radius,
	resource_spawner.get_occupied_cells()
)
```

The end of `generate_world()` should become:

```
resource_spawner.generate_resources(
	generated_seed,
	map_width,
	map_height,
	tile_size
)

var map_center := Vector2i(
	map_width / 2,
	map_height / 2
)

forest_decorator.generate_decorations(
	generated_seed,
	ground_cells,
	map_width,
	map_height,
	tile_size,
	map_center,
	resource_spawner.clear_radius,
	resource_spawner.get_occupied_cells()
)

print("Generated world with seed: ", generated_seed)
```

## Initial test

Run several generated worlds and verify:

- Decorations appear only on grass.
- The camp clearing remains clean.
- No decorations appear immediately around collectible resources.
- The player walks over them without collision.
- Trees, rocks, and berry bushes remain easy to identify.
- Restarting with a fixed seed produces identical decorations.
- Changing `decoration_density` changes visual fullness without affecting resource counts.

Start with `decoration_density = 0.32`. We can increase it after seeing the result, but filling every cell would make the forest look noisy rather than alive.