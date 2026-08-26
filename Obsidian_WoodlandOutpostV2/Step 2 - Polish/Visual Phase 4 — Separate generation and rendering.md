Before creating transition tiles, we should separate ground rendering from map generation. Otherwise `world_generator.gd` will gradually become another oversized script.

### 1. Add a renderer node

Add a `Node2D` as the first child of `World`:

```
World
├── GroundRenderer
├── ResourceSpawner
└── Camp
```

### 2. Create `ground_renderer.gd`

Attach:

```
res://scripts/world/ground_renderer.gd
```

Add:

```
class_name GroundRenderer
extends Node2D


@export_category("Ground Textures")
@export var grass_texture: Texture2D
@export var soil_texture: Texture2D


const GRASS_COLOR := Color("#5f8f4f")
const SOIL_COLOR := Color("#8a6748")


var ground_cells: Array = []
var tile_size: int = 32


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func render_ground(
	new_ground_cells: Array,
	new_tile_size: int
) -> void:
	ground_cells = new_ground_cells
	tile_size = new_tile_size

	queue_redraw()


func _draw() -> void:
	for y in range(ground_cells.size()):
		var row: Array = ground_cells[y]

		for x in range(row.size()):
			var tile_rect := Rect2(
				Vector2(x, y) * tile_size,
				Vector2(tile_size, tile_size)
			)

			var is_soil: bool = row[x]

			if is_soil:
				_draw_tile(
					soil_texture,
					tile_rect,
					SOIL_COLOR
				)
			else:
				_draw_tile(
					grass_texture,
					tile_rect,
					GRASS_COLOR
				)


func _draw_tile(
	texture: Texture2D,
	tile_rect: Rect2,
	fallback_color: Color
) -> void:
	if texture == null:
		draw_rect(
			tile_rect,
			fallback_color
		)
		return

	draw_texture_rect(
		texture,
		tile_rect,
		false
	)
```

Assign the grass and soil textures to `GroundRenderer`, not `World`.

## 3. Replace `world_generator.gd`

Replace its complete contents with:

```
class_name WorldGenerator
extends Node2D


@export_category("Map Size")
@export var map_width: int = 40
@export var map_height: int = 23
@export var tile_size: int = 32

@export_category("Generation")
@export var world_seed: int = 0
@export_range(-1.0, 1.0, 0.05) var soil_threshold: float = 0.25


@onready var ground_renderer: GroundRenderer = $GroundRenderer
@onready var resource_spawner: ResourceSpawner = $ResourceSpawner


var noise := FastNoiseLite.new()
var generated_seed: int
var ground_cells: Array = []


func _ready() -> void:
	generate_world()


func generate_world() -> void:
	generated_seed = world_seed

	if generated_seed == 0:
		generated_seed = randi_range(
			1,
			2_000_000_000
		)

	noise.seed = generated_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.08

	_generate_ground_data()

	ground_renderer.render_ground(
		ground_cells,
		tile_size
	)

	resource_spawner.generate_resources(
		generated_seed,
		map_width,
		map_height,
		tile_size
	)

	print("Generated world with seed: ", generated_seed)


func _generate_ground_data() -> void:
	ground_cells.clear()

	for y in range(map_height):
		var row: Array[bool] = []

		for x in range(map_width):
			row.append(
				_is_soil_tile(x, y)
			)

		ground_cells.append(row)


func _is_soil_tile(x: int, y: int) -> bool:
	var noise_value := noise.get_noise_2d(x, y)

	return noise_value > soil_threshold
```

### 4. Move the assigned textures

Select `World`. Its old Grass and Soil texture fields will disappear because they no longer belong to `WorldGenerator`.

Select `GroundRenderer` and assign:

```
Grass Texture: grass_tile_01.png
Soil Texture:  soil_tile_01.png
```

Run the game. It should look exactly the same as before.

The architecture is now cleaner:

- `WorldGenerator` creates map data.
- `GroundRenderer` converts that data into visuals.
- `ResourceSpawner` places objects.

Transition logic can now be added entirely to `GroundRenderer` without making procedural generation harder to understand.