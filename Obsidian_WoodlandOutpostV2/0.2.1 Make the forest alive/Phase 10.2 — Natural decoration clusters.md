We’ll use smooth noise to create broad decoration regions, while tree and soil proximity influence the details inside them.

The result will be:

- Flowers grouped in small clearings.
- Ferns and mushrooms around wooded areas.
- Pebbles and branches near exposed soil.
- Ordinary grass filling the remaining decorated areas.

## 1. Remember resource cells by type

In `resource_spawner.gd`, near `occupied_cells`, add:

```
var resource_cells_by_type: Dictionary = {}
```

Inside `generate_resources()`, immediately after:

```
occupied_cells.clear()
```

add:

```
resource_cells_by_type = {
	ResourceTypes.Type.WOOD: [],
	ResourceTypes.Type.STONE: [],
	ResourceTypes.Type.FOOD: []
}
```

Inside `_spawn_resource()`, immediately after:

```
resource.resource_amount = units_per_resource
```

add:

```
var stored_cells: Array = (
	resource_cells_by_type.get(
		resource_type,
		[]
	)
)

stored_cells.append(cell)

resource_cells_by_type[resource_type] = stored_cells
```

Then add this getter:

```
func get_resource_cells(
	resource_type: int
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	var stored_cells: Array = (
		resource_cells_by_type.get(
			resource_type,
			[]
		)
	)

	for cell in stored_cells:
		result.append(
			Vector2i(cell)
		)

	return result
```

This tracks spawn locations only; it does not change placement.

## 2. Add ferns to the decorator

Update the enum in `forest_decorator.gd`:

```
enum DecorationType {
	GRASS,
	FLOWER,
	PEBBLE,
	BRANCH,
	MUSHROOM,
	FERN
}
```

Add another colour export:

```
@export var fern_color := Color("#356b3c")
```

Near the existing random generator, add:

```
var cluster_noise := FastNoiseLite.new()
```

## 3. Accept the tree locations

Add this final argument to `generate_decorations()`:

```
tree_cells: Array[Vector2i]
```

The complete function header becomes:

```
func generate_decorations(
	seed_value: int,
	ground_cells: Array,
	map_width: int,
	map_height: int,
	tile_size: int,
	map_center: Vector2i,
	camp_clear_radius: int,
	blocked_cells: Dictionary,
	tree_cells: Array[Vector2i]
) -> void:
```

At the beginning of the function, after setting `random.seed`, configure the cluster noise:

```
cluster_noise.seed = seed_value + 75_913
cluster_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
cluster_noise.frequency = 0.045
```

## 4. Replace the density section

Inside the cell loop, find:

```
if random.randf() > decoration_density:
	continue

_add_decoration(
	cell,
	tile_size
)

if random.randf() < 0.12:
	_add_decoration(
		cell,
		tile_size
	)
```

Replace it with:

```
var cluster_value := (
	cluster_noise.get_noise_2d(
		cell.x,
		cell.y
	)
)

var local_density := clampf(
	decoration_density
		+ absf(cluster_value) * 0.16
		- 0.04,
	0.05,
	0.65
)

if random.randf() > local_density:
	continue

var decoration_type := _choose_decoration_type(
	cell,
	ground_cells,
	tree_cells,
	cluster_value
)

_add_decoration(
	cell,
	tile_size,
	decoration_type
)

if random.randf() < 0.12:
	_add_decoration(
		cell,
		tile_size,
		decoration_type
	)
```

Nearby cells receive similar noise values, creating continuous patches rather than isolated random objects.

## 5. Update `_add_decoration()`

Replace it with:

```
func _add_decoration(
	cell: Vector2i,
	tile_size: int,
	decoration_type: DecorationType
) -> void:
	var cell_center := Vector2(
		(cell.x + 0.5) * tile_size,
		(cell.y + 0.5) * tile_size
	)

	var offset := Vector2(
		random.randi_range(-11, 11),
		random.randi_range(-11, 11)
	)

	decorations.append({
		"type": decoration_type,
		"position": (cell_center + offset).round(),
		"variant": random.randi_range(0, 2)
	})
```

## 6. Choose decorations contextually

Add:

```
func _choose_decoration_type(
	cell: Vector2i,
	ground_cells: Array,
	tree_cells: Array[Vector2i],
	cluster_value: float
) -> DecorationType:
	var roll := random.randi_range(0, 99)

	if _is_near_tree(cell, tree_cells):
		if roll < 50:
			return DecorationType.FERN

		if roll < 75:
			return DecorationType.MUSHROOM

		if roll < 90:
			return DecorationType.GRASS

		return DecorationType.BRANCH

	if _is_next_to_soil(cell, ground_cells):
		if roll < 45:
			return DecorationType.PEBBLE

		if roll < 70:
			return DecorationType.BRANCH

		return DecorationType.GRASS

	if cluster_value > 0.3:
		if roll < 70:
			return DecorationType.FLOWER

		return DecorationType.GRASS

	if cluster_value < -0.3:
		if roll < 65:
			return DecorationType.FERN

		return DecorationType.GRASS

	if roll < 72:
		return DecorationType.GRASS

	if roll < 84:
		return DecorationType.FLOWER

	if roll < 92:
		return DecorationType.PEBBLE

	if roll < 97:
		return DecorationType.BRANCH

	return DecorationType.MUSHROOM
```

Add the context checks:

```
func _is_near_tree(
	cell: Vector2i,
	tree_cells: Array[Vector2i]
) -> bool:
	for tree_cell in tree_cells:
		var distance := Vector2(cell).distance_to(
			Vector2(tree_cell)
		)

		if distance >= 2.0 and distance <= 4.0:
			return true

	return false


func _is_next_to_soil(
	cell: Vector2i,
	ground_cells: Array
) -> bool:
	var neighbours := [
		Vector2i.UP,
		Vector2i.RIGHT,
		Vector2i.DOWN,
		Vector2i.LEFT
	]

	for direction in neighbours:
		var neighbour := cell + direction

		if neighbour.y < 0:
			continue

		if neighbour.y >= ground_cells.size():
			continue

		var row: Array = ground_cells[neighbour.y]

		if neighbour.x < 0 or neighbour.x >= row.size():
			continue

		if bool(row[neighbour.x]):
			return true

	return false
```

## 7. Draw the ferns

Add this case inside `_draw()`:

```
DecorationType.FERN:
	_draw_fern(
		draw_position,
		variant
	)
```

Then add:

```
func _draw_fern(
	draw_position: Vector2,
	variant: int
) -> void:
	var height := 6.0

	if variant == 2:
		height = 8.0

	draw_line(
		draw_position,
		draw_position + Vector2(0.0, -height),
		fern_color,
		1.0
	)

	for leaf_index in range(1, 4):
		var leaf_y := float(leaf_index * 2)

		draw_line(
			draw_position + Vector2(0.0, -leaf_y),
			draw_position + Vector2(-3.0, -leaf_y - 2.0),
			fern_color,
			1.0
		)

		draw_line(
			draw_position + Vector2(0.0, -leaf_y),
			draw_position + Vector2(3.0, -leaf_y - 2.0),
			fern_color,
			1.0
		)
```

## 8. Pass the tree cells from `WorldGenerator`

Update the decorator call:

```
forest_decorator.generate_decorations(
	generated_seed,
	ground_cells,
	map_width,
	map_height,
	tile_size,
	map_center,
	resource_spawner.clear_radius,
	resource_spawner.get_occupied_cells(),
	resource_spawner.get_resource_cells(
		ResourceTypes.Type.WOOD
	)
)
```

## Test

Try several seeds and verify:

- Flowers form recognizable patches.
- Ferns and mushrooms appear around—but not directly beneath—trees.
- Pebbles and branches follow grass/soil boundaries.
- The camp and resource clearances remain intact.
- Collectible resources remain visually dominant.
- The same fixed seed produces the same clusters.

If any region looks too busy, lower `decoration_density` from `0.32` to `0.26`; the cluster shapes will remain, but they will contain fewer objects.



FIX::: Cannot infer the type of "neighbour" variable because the value doesn't have a set type.

The issue comes from this array:

```
var neighbours := [
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT
]
```

Godot infers it as a generic array, so `direction` has no guaranteed type. Consequently, it cannot infer the result of:

```
cell + direction
```

Replace the complete `_is_next_to_soil()` function with:

```
func _is_next_to_soil(
	cell: Vector2i,
	ground_cells: Array
) -> bool:
	var neighbours: Array[Vector2i] = [
		Vector2i.UP,
		Vector2i.RIGHT,
		Vector2i.DOWN,
		Vector2i.LEFT
	]

	for direction: Vector2i in neighbours:
		var neighbour: Vector2i = (
			cell + direction
		)

		if neighbour.y < 0:
			continue

		if neighbour.y >= ground_cells.size():
			continue

		var row: Array = ground_cells[
			neighbour.y
		]

		if (
			neighbour.x < 0
			or neighbour.x >= row.size()
		):
			continue

		if bool(row[neighbour.x]):
			return true

	return false
```

The important corrections are:

```
var neighbours: Array[Vector2i]
```

and:

```
var neighbour: Vector2i
```

Now Godot knows both `direction` and `neighbour` are `Vector2i`, so the type-inference error should disappear.