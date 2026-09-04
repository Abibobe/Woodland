### 1. Configure the game window

Open:

**Project → Project Settings → Display → Window**

Set:

- Viewport Width: `1280`
- Viewport Height: `720`
- Window Width Override: `1280`
- Window Height Override: `720`

### 2. Create the generator script

Select the `World` node in `game.tscn`, then choose **Attach Script**.

Save it as:

```
res://scripts/world/world_generator.gd
```

Replace its contents with:

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

const GRASS_COLOR := Color("#5f8f4f")
const GRASS_ALT_COLOR := Color("#679957")
const SOIL_COLOR := Color("#8a6748")

var noise := FastNoiseLite.new()
var generated_seed: int


func _ready() -> void:
	generate_world()


func generate_world() -> void:
	generated_seed = world_seed

	if generated_seed == 0:
		generated_seed = randi()

	noise.seed = generated_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.08

	queue_redraw()

	print("Generated world with seed: ", generated_seed)


func _draw() -> void:
	for y in range(map_height):
		for x in range(map_width):
			var tile_position := Vector2(
				x * tile_size,
				y * tile_size
			)

			var tile_color := _get_tile_color(x, y)

			draw_rect(
				Rect2(tile_position, Vector2(tile_size, tile_size)),
				tile_color
			)


func _get_tile_color(x: int, y: int) -> Color:
	var noise_value := noise.get_noise_2d(x, y)

	if noise_value > soil_threshold:
		return SOIL_COLOR

	if (x + y) % 2 == 0:
		return GRASS_COLOR

	return GRASS_ALT_COLOR
```

Run the game. You should now see a green map containing organically shaped brown soil areas.

## 3. Understand the code ownership

This file has one responsibility:

> Decide what kind of ground appears in every map cell and display the prototype ground.

Its functions have separate jobs:

- `_ready()` starts generation.
- `generate_world()` prepares the random noise.
- `_draw()` displays every cell.
- `_get_tile_color()` decides whether a cell is grass or soil.

We are using coloured rectangles temporarily. This isolates map-generation problems from artwork and TileSet configuration problems.

## 4. Test reproducible maps

Run the game several times with `world_seed` set to `0`. Each run should produce a different map.

Then select `World` and set **World Seed** in the Inspector to a number such as:

```
12345
```

Run the game several times. You should always receive the same map.

This will be extremely helpful later: if a particular generated map causes a bug, we can preserve its seed and reproduce the problem exactly.