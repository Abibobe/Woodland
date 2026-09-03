
Now we’ll guarantee starter resources near camp while making stone require longer expeditions.

### 1. Add distance settings

In `resource_spawner.gd`, beneath `clear_radius`, add:

```
@export_category("Resource Distribution")
@export_range(0, 50) var nearby_tree_count := 12
@export_range(0, 30) var nearby_bush_count := 6
@export_range(5, 30) var nearby_maximum_distance := 10
@export_range(5, 40) var stone_minimum_distance := 12
```

Distances are measured in tiles.

### 2. Replace `generate_resources()`

```
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

	var guaranteed_trees := mini(
		nearby_tree_count,
		tree_count
	)

	var guaranteed_bushes := mini(
		nearby_bush_count,
		bush_count
	)

	# Starter wood near camp.
	_spawn_resource_type(
		ResourceTypes.Type.WOOD,
		guaranteed_trees,
		map_width,
		map_height,
		tile_size,
		map_center,
		float(clear_radius),
		float(nearby_maximum_distance)
	)

	# Starter food near camp.
	_spawn_resource_type(
		ResourceTypes.Type.FOOD,
		guaranteed_bushes,
		map_width,
		map_height,
		tile_size,
		map_center,
		float(clear_radius),
		float(nearby_maximum_distance)
	)

	# Remaining trees can appear throughout the forest.
	_spawn_resource_type(
		ResourceTypes.Type.WOOD,
		tree_count - guaranteed_trees,
		map_width,
		map_height,
		tile_size,
		map_center,
		float(clear_radius),
		-1.0
	)

	# Remaining bushes can appear throughout the forest.
	_spawn_resource_type(
		ResourceTypes.Type.FOOD,
		bush_count - guaranteed_bushes,
		map_width,
		map_height,
		tile_size,
		map_center,
		float(clear_radius),
		-1.0
	)

	# Stone begins farther from camp.
	_spawn_resource_type(
		ResourceTypes.Type.STONE,
		rock_count,
		map_width,
		map_height,
		tile_size,
		map_center,
		float(stone_minimum_distance),
		-1.0
	)
```

A maximum distance of `-1.0` means there is no upper distance limit.

### 3. Replace `_spawn_resource_type()`

```
func _spawn_resource_type(
	resource_type: int,
	amount: int,
	map_width: int,
	map_height: int,
	tile_size: int,
	map_center: Vector2i,
	minimum_distance: float,
	maximum_distance: float
) -> void:
	for resource_index in range(amount):
		var cell := _find_available_cell(
			map_width,
			map_height,
			map_center,
			minimum_distance,
			maximum_distance
		)

		if cell == Vector2i(-1, -1):
			push_warning(
				"Could not find space for resource %s."
				% resource_index
			)
			return

		_spawn_resource(
			resource_type,
			cell,
			tile_size
		)
```

### 4. Replace `_find_available_cell()`

```
func _find_available_cell(
	map_width: int,
	map_height: int,
	map_center: Vector2i,
	minimum_distance: float,
	maximum_distance: float
) -> Vector2i:
	var maximum_attempts := 500

	for attempt in range(maximum_attempts):
		var candidate := Vector2i(
			random.randi_range(1, map_width - 2),
			random.randi_range(2, map_height - 2)
		)

		if occupied_cells.has(candidate):
			continue

		var distance_from_camp := Vector2(
			candidate
		).distance_to(
			Vector2(map_center)
		)

		if distance_from_camp < minimum_distance:
			continue

		if (
			maximum_distance >= 0.0
			and distance_from_camp > maximum_distance
		):
			continue

		occupied_cells[candidate] = true
		return candidate

	return Vector2i(-1, -1)
```

### 5. Test several worlds

Keep `World Seed` at `0` and restart several times. Verify:

- The immediate camp area remains clear.
- At least 12 trees are reasonably close to camp.
- At least 6 bushes are reasonably close.
- Rocks do not appear within 12 tiles of camp.
- Trees and bushes still appear in distant parts of the map.
- Resources never occupy the same cell.

The map is now significantly less dense than before, while starter wood and food remain guaranteed. Next we’ll calculate minimum total resource quantities from the cabin costs and food requirements so every generated world remains winnable.