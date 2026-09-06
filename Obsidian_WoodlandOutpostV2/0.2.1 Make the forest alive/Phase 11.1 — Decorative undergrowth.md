

We’ll add small saplings and plain shrubs as non-interactive scenery. They will visually fill the forest without changing resource quantities, collisions, gathering, or navigation.

### 1. Extend `DecorationType`

In `forest_decorator.gd`, replace the enum with:

```
enum DecorationType {
	GRASS,
	FLOWER,
	PEBBLE,
	BRANCH,
	MUSHROOM,
	FERN,
	SAPLING,
	SHRUB
}
```

### 2. Add undergrowth settings

Under the decoration-density exports, add:

```
@export_category("Decorative Undergrowth")
@export_range(0.0, 0.5, 0.01) var undergrowth_density := 0.11
@export_range(0.0, 1.0, 0.05) var shrub_probability := 0.58
```

Under the colour exports, add:

```
@export var sapling_trunk_color := Color("#65462d")
@export var sapling_dark_color := Color("#285437")
@export var sapling_light_color := Color("#487a43")

@export var shrub_dark_color := Color("#315f39")
@export var shrub_light_color := Color("#568447")
```

### 3. Generate the undergrowth

Inside `generate_decorations()`, immediately before:

```
queue_redraw()
```

add:

```
_generate_undergrowth(
	ground_cells,
	map_width,
	map_height,
	tile_size,
	map_center,
	camp_clear_radius,
	blocked_cells
)
```

### 4. Add `_generate_undergrowth()`

Add this beneath `generate_decorations()`:

```
func _generate_undergrowth(
	ground_cells: Array,
	map_width: int,
	map_height: int,
	tile_size: int,
	map_center: Vector2i,
	camp_clear_radius: int,
	blocked_cells: Dictionary
) -> void:
	for y in range(2, map_height - 1):
		for x in range(1, map_width - 1):
			var cell := Vector2i(x, y)

			# Keep soil paths and clearings unobstructed.
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

			var cluster_value := (
				cluster_noise.get_noise_2d(
					cell.x,
					cell.y
				)
			)

			var local_density := clampf(
				undergrowth_density
					+ maxf(-cluster_value, 0.0) * 0.12,
				0.0,
				0.28
			)

			if random.randf() > local_density:
				continue

			var decoration_type: DecorationType

			if random.randf() < shrub_probability:
				decoration_type = DecorationType.SHRUB
			else:
				decoration_type = DecorationType.SAPLING

			_add_decoration(
				cell,
				tile_size,
				decoration_type
			)
```

Negative noise regions will become slightly denser, creating woodland pockets rather than a uniform grid.

### 5. Update `_draw()`

Inside the existing `match decoration_type:`, add:

```
DecorationType.SAPLING:
	_draw_sapling(
		draw_position,
		variant
	)

DecorationType.SHRUB:
	_draw_shrub(
		draw_position,
		variant
	)
```

Make sure these are aligned with the existing `DecorationType.GRASS`, `FLOWER`, and other cases.

### 6. Draw decorative saplings

Add:

```
func _draw_sapling(
	draw_position: Vector2,
	variant: int
) -> void:
	var height := 11.0

	if variant == 2:
		height = 14.0

	var wind_offset := _get_wind_offset(
		draw_position,
		0.45
	)

	var crown_position := (
		draw_position
		+ Vector2(0.0, -height)
		+ wind_offset
	)

	# Small ground shadow.
	draw_set_transform(
		Vector2(0.0, 1.0),
		0.0,
		Vector2(1.0, 0.4)
	)

	draw_circle(
		draw_position,
		4.0,
		Color(0.05, 0.08, 0.06, 0.22)
	)

	draw_set_transform(
		Vector2.ZERO,
		0.0,
		Vector2.ONE
	)

	# Thin trunk.
	draw_line(
		draw_position,
		crown_position + Vector2(0.0, 3.0),
		sapling_trunk_color,
		2.0
	)

	# Small leafy crown.
	draw_circle(
		crown_position + Vector2(-2.0, 1.0),
		4.0,
		sapling_dark_color
	)

	draw_circle(
		crown_position + Vector2(2.0, 1.0),
		4.0,
		sapling_dark_color
	)

	draw_circle(
		crown_position + Vector2(0.0, -2.0),
		4.0,
		sapling_light_color
	)
```

These are intentionally much smaller than harvestable trees.

### 7. Draw plain shrubs

Add:

```
func _draw_shrub(
	draw_position: Vector2,
	variant: int
) -> void:
	var width := 5.0

	if variant == 2:
		width = 6.0

	var wind_offset := _get_wind_offset(
		draw_position,
		0.28
	)

	var shrub_position := (
		draw_position + wind_offset
	)

	draw_circle(
		shrub_position + Vector2(-width, 0.0),
		4.0,
		shrub_dark_color
	)

	draw_circle(
		shrub_position + Vector2(width, 0.0),
		4.0,
		shrub_dark_color
	)

	draw_circle(
		shrub_position + Vector2(0.0, -3.0),
		5.0,
		shrub_light_color
	)

	draw_circle(
		shrub_position + Vector2(-2.0, -4.0),
		2.0,
		shrub_light_color.lightened(0.08)
	)
```

These shrubs have no berries, helping distinguish them from gatherable food bushes.

## Suggested Inspector values

```
Decoration Density:   0.38
Undergrowth Density:  0.11
Shrub Probability:    0.58
Resource Clearance:   1
Camp Clearance:       1
```

I recommend increasing the existing decoration density from `0.32` to only `0.38` initially. Saplings and shrubs occupy considerably more visual space than grass.

## Test checklist

- Saplings are clearly smaller than resource trees.
- Plain shrubs cannot be mistaken for berry bushes.
- The player can walk through all new scenery.
- Soil patches and the camp clearing remain readable.
- Gathering prompts appear only on actual resources.
- Resources remain approachable.
- Undergrowth appears in clusters instead of a regular pattern.
- A fixed world seed recreates the same forest.

This should deliver the first major reduction in empty space without touching the balance you like.