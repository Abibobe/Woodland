Now we can replace the three test objects with procedurally placed resources.

### 1. Prepare the spawner node

In `game.tscn`:

1. Delete `TestTree`, `TestRock`, and `TestBush`.
2. Rename `ResourceObjects` to:

```
ResourceSpawner
```

The tree should look like:

```
Game
├── World
│   └── ResourceSpawner
├── Actors
│   └── Player
└── Interface
```

### 2. Create the spawner script

Attach a script to `ResourceSpawner` and save it as:

```
res://scripts/world/resource_spawner.gd
```

Add:

```
class_name ResourceSpawner
extends Node2D


@export_category("Resource Scene")
@export var resource_scene: PackedScene

@export_category("Resource Counts")
@export_range(0, 200) var tree_count: int = 55
@export_range(0, 100) var rock_count: int = 14
@export_range(0, 100) var bush_count: int = 18

@export_category("Starting Area")
@export_range(1, 10) var clear_radius: int = 4

var random := RandomNumberGenerator.new()
var occupied_cells: Dictionary = {}


func generate_resources(
	seed_value: int,
	map_width: int,
	map_height: int,
	tile_size: int
) -> void:
	_clear_existing_resources()

	random.seed = seed_value + 9187
	occupied_cells.clear()

	var map_center := Vector2i(
		map_width / 2,
		map_height / 2
	)

	_spawn_resource_type(
		ResourceNode.ResourceType.WOOD,
		tree_count,
		map_width,
		map_height,
		tile_size,
		map_center
	)

	_spawn_resource_type(
		ResourceNode.ResourceType.STONE,
		rock_count,
		map_width,
		map_height,
		tile_size,
		map_center
	)

	_spawn_resource_type(
		ResourceNode.ResourceType.FOOD,
		bush_count,
		map_width,
		map_height,
		tile_size,
		map_center
	)


func _spawn_resource_type(
	resource_type: int,
	amount: int,
	map_width: int,
	map_height: int,
	tile_size: int,
	map_center: Vector2i
) -> void:
	for resource_index in range(amount):
		var cell := _find_available_cell(
			map_width,
			map_height,
			map_center
		)

		if cell == Vector2i(-1, -1):
			push_warning(
				"Could not find space for resource %s."
				% resource_index
			)
			return

		_spawn_resource(resource_type, cell, tile_size)


func _find_available_cell(
	map_width: int,
	map_height: int,
	map_center: Vector2i
) -> Vector2i:
	var maximum_attempts := 100

	for attempt in range(maximum_attempts):
		var candidate := Vector2i(
			random.randi_range(1, map_width - 2),
			random.randi_range(1, map_height - 2)
		)

		if occupied_cells.has(candidate):
			continue

		if Vector2(candidate).distance_to(Vector2(map_center)) < clear_radius:
			continue

		occupied_cells[candidate] = true
		return candidate

	return Vector2i(-1, -1)


func _spawn_resource(
	resource_type: int,
	cell: Vector2i,
	tile_size: int
) -> void:
	if resource_scene == null:
		push_error("ResourceSpawner has no Resource Scene.")
		return

	var resource := resource_scene.instantiate() as ResourceNode

	if resource == null:
		push_error("The assigned scene is not a ResourceNode.")
		return

	resource.resource_type = resource_type

	add_child(resource)

	resource.position = Vector2(
		(cell.x + 0.5) * tile_size,
		(cell.y + 0.5) * tile_size
	)


func _clear_existing_resources() -> void:
	for child in get_children():
		child.queue_free()
```

### 3. Assign the resource scene

Select `ResourceSpawner`.

In the Inspector, find **Resource Scene** and drag this file into it:

```
res://scenes/resources/resource_node.tscn
```

Without this step, the spawner won’t know which scene to create.

## 4. Connect it to world generation

Open:

```
res://scripts/world/world_generator.gd
```

Below the existing variables, add:

```
@onready var resource_spawner: ResourceSpawner = $ResourceSpawner
```

Then update `generate_world()`:

```
func generate_world() -> void:
	generated_seed = world_seed

	if generated_seed == 0:
		generated_seed = randi_range(1, 2_000_000_000)

	noise.seed = generated_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.08

	queue_redraw()

	resource_spawner.generate_resources(
		generated_seed,
		map_width,
		map_height,
		tile_size
	)

	print("Generated world with seed: ", generated_seed)
```

Run the game. You should now have:

- Randomly distributed trees, rocks, and bushes
- No overlapping resources
- An open area around the player
- Identical resource placement when using the same fixed seed
- Different placement when `World Seed` is `0`

The responsibility split is now clean:

- `WorldGenerator` creates the ground and starts world generation.
- `ResourceSpawner` chooses resource positions.
- `ResourceNode` defines an individual resource.
- `Player` handles movement.

We haven’t added gathering yet, so every new piece remains easy to test independently.