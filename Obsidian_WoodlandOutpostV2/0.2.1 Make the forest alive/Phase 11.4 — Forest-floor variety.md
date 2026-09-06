

Now we’ll activate the stump, log, moss and leaf-litter sprites. These remain static, non-interactive and non-colliding.

### 1. Extend `DecorationType`

Add the new values at the end of the enum:

```
enum DecorationType {
	GRASS,
	FLOWER,
	PEBBLE,
	BRANCH,
	MUSHROOM,
	FERN,
	SAPLING,
	SHRUB,
	STUMP,
	FALLEN_LOG,
	MOSS,
	LEAF_LITTER
}
```

Appending them preserves the numeric values of your existing decoration types.

### 2. Add forest-floor settings

Under the decoration-density exports, add:

```
@export_category("Forest Floor")
@export_range(0.0, 0.4, 0.01) var forest_floor_density := 0.10
@export_range(0.0, 1.0, 0.05) var woodland_floor_bias := 0.65
```

### 3. Generate the forest floor

Inside `generate_decorations()`, after `_generate_undergrowth(...)` and before `queue_redraw()`, add:

```
_generate_forest_floor(
	ground_cells,
	map_width,
	map_height,
	tile_size,
	map_center,
	camp_clear_radius,
	blocked_cells,
	tree_cells
)
```

### 4. Add `_generate_forest_floor()`

```
func _generate_forest_floor(
	ground_cells: Array,
	map_width: int,
	map_height: int,
	tile_size: int,
	map_center: Vector2i,
	camp_clear_radius: int,
	blocked_cells: Dictionary,
	tree_cells: Array[Vector2i]
) -> void:
	for y in range(2, map_height - 1):
		for x in range(1, map_width - 1):
			var cell := Vector2i(x, y)

			# Keep soil areas visually distinct.
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

			# Do not place scenery directly beneath resources.
			if blocked_cells.has(cell):
				continue

			var near_tree := _is_near_tree(
				cell,
				tree_cells
			)

			var cluster_value := (
				cluster_noise.get_noise_2d(
					cell.x,
					cell.y
				)
			)

			var local_density := forest_floor_density

			if near_tree:
				local_density += 0.08

			if cluster_value < -0.2:
				local_density += 0.04

			local_density = clampf(
				local_density,
				0.0,
				0.25
			)

			if random.randf() > local_density:
				continue

			var decoration_type := (
				_choose_forest_floor_type(
					near_tree,
					cluster_value
				)
			)

			_add_decoration(
				cell,
				tile_size,
				decoration_type
			)
```

### 5. Add the contextual selection function

```
func _choose_forest_floor_type(
	near_tree: bool,
	cluster_value: float
) -> DecorationType:
	var roll := random.randi_range(0, 99)

	if near_tree:
		if roll < 38:
			return DecorationType.LEAF_LITTER

		if roll < 66:
			return DecorationType.MOSS

		if roll < 78:
			return DecorationType.FALLEN_LOG

		if roll < 86:
			return DecorationType.STUMP

		if roll < 94:
			return DecorationType.MUSHROOM

		return DecorationType.FERN

	if cluster_value < -0.25:
		if roll < 55:
			return DecorationType.MOSS

		if roll < 82:
			return DecorationType.LEAF_LITTER

		return DecorationType.FERN

	if roll < 50:
		return DecorationType.LEAF_LITTER

	if roll < 75:
		return DecorationType.MOSS

	if roll < 89:
		return DecorationType.GRASS

	return DecorationType.FLOWER
```

Stumps and fallen logs therefore remain uncommon and primarily appear around mature trees.

### 6. Update `_get_atlas_cell()`

Add these cases:

```
DecorationType.STUMP:
	return ATLAS_STUMP

DecorationType.FALLEN_LOG:
	return ATLAS_LOG

DecorationType.MOSS:
	return ATLAS_MOSS

DecorationType.LEAF_LITTER:
	return ATLAS_LEAVES
```

The complete lower part should resemble:

```
DecorationType.SHRUB:
	if variant % 2 == 0:
		return ATLAS_SHRUB_A

	return ATLAS_SHRUB_B

DecorationType.STUMP:
	return ATLAS_STUMP

DecorationType.FALLEN_LOG:
	return ATLAS_LOG

DecorationType.MOSS:
	return ATLAS_MOSS

DecorationType.LEAF_LITTER:
	return ATLAS_LEAVES

return ATLAS_GRASS
```

## Recommended settings

```
Decoration Density:       0.30
Undergrowth Density:      0.10
Cluster Probability:      0.20
Maximum Cluster Size:     2
Forest Floor Density:     0.10
Woodland Floor Bias:      0.65
```

`Woodland Floor Bias` is reserved for later tuning, so don’t worry if it is not used yet.

## Expected result

- Leaf litter accumulates beneath trees.
- Moss appears more frequently in dense woodland areas.
- Fallen logs and stumps are present but uncommon.
- Open regions retain grass and occasional flowers.
- Nothing new can be gathered.
- Player movement and resource balance remain unchanged.
- All scenery uses the single static atlas.

Because these are one-sprite static decorations, this should increase variety without recreating the earlier procedural-drawing performance problem.