Butterflies will prefer flowers, while fireflies will prefer ferns and mushrooms. If those decorations are unavailable, placement falls back to ordinary random positions.

### 1. Expose habitat positions from `forest_decorator.gd`

Add these functions beneath `_add_decoration()`:

```
func get_flower_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []

	for decoration: Dictionary in decorations:
		var decoration_type := int(
			decoration["type"]
		)

		if decoration_type != DecorationType.FLOWER:
			continue

		positions.append(
			decoration["position"] as Vector2
		)

	return positions


func get_sheltered_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []

	for decoration: Dictionary in decorations:
		var decoration_type := int(
			decoration["type"]
		)

		if (
			decoration_type != DecorationType.FERN
			and decoration_type != DecorationType.MUSHROOM
		):
			continue

		positions.append(
			decoration["position"] as Vector2
		)

	return positions
```

The explicit types also avoid the inference problem you encountered earlier.

### 2. Add habitat settings to `forest_life.gd`

Beneath the wildlife-count exports, add:

```
@export_category("Habitat Placement")
@export_range(0.0, 1.0, 0.05) var habitat_preference := 0.85
@export_range(0.0, 96.0, 1.0) var habitat_spread := 42.0
```

An `85%` preference keeps wildlife associated with habitats without making its positioning completely rigid.

### 3. Replace `generate_life()`

```
func generate_life(
	seed_value: int,
	map_width: int,
	map_height: int,
	tile_size: int,
	butterfly_habitats: Array[Vector2],
	firefly_habitats: Array[Vector2]
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
			world_size,
			butterfly_habitats
		)

	for index in range(firefly_count):
		_add_life_point(
			LifeType.FIREFLY,
			world_size,
			firefly_habitats
		)

	queue_redraw()
```

The seed and wildlife counts remain unchanged.

### 4. Replace `_add_life_point()`

```
func _add_life_point(
	life_type: LifeType,
	world_size: Vector2,
	preferred_habitats: Array[Vector2]
) -> void:
	var base_position: Vector2

	var use_habitat := (
		not preferred_habitats.is_empty()
		and random.randf() < habitat_preference
	)

	if use_habitat:
		var habitat_index := random.randi_range(
			0,
			preferred_habitats.size() - 1
		)

		var habitat_position: Vector2 = (
			preferred_habitats[habitat_index]
		)

		var offset_angle := random.randf_range(
			0.0,
			TAU
		)

		var offset_distance := random.randf_range(
			6.0,
			habitat_spread
		)

		base_position = (
			habitat_position
			+ Vector2.RIGHT.rotated(offset_angle)
				* offset_distance
		)
	else:
		base_position = Vector2(
			random.randf_range(
				32.0,
				world_size.x - 32.0
			),
			random.randf_range(
				64.0,
				world_size.y - 32.0
			)
		)

	base_position.x = clampf(
		base_position.x,
		32.0,
		world_size.x - 32.0
	)

	base_position.y = clampf(
		base_position.y,
		64.0,
		world_size.y - 32.0
	)

	life_points.append({
		"type": life_type,
		"base_position": base_position,
		"phase_offset": random.randf_range(0.0, TAU),
		"speed": random.randf_range(0.65, 1.25),
		"variant": random.randi_range(0, 1)
	})
```

Clamping prevents habitat offsets from placing wildlife outside the map.

### 5. Update `world_generator.gd`

Replace the current call:

```
forest_life.generate_life(
	generated_seed,
	map_width,
	map_height,
	tile_size
)
```

with:

```
forest_life.generate_life(
	generated_seed,
	map_width,
	map_height,
	tile_size,
	forest_decorator.get_flower_positions(),
	forest_decorator.get_sheltered_positions()
)
```

## Expected result

- Butterflies gather around flower patches during morning and afternoon.
- Fireflies gather around fern and mushroom areas during evening and night.
- A small percentage still appears elsewhere, keeping the forest natural.
- Wildlife counts and gameplay balance remain unchanged.
- Missing habitat types automatically use random placement.
- A fixed nonzero `World Seed` produces the same layout every time.

For the deterministic test, set `World Seed` to something such as `12345`. A value of `0` intentionally creates a new random seed each launch.