### 1. Add cluster settings

Under `Decorative Undergrowth`, add:

```
@export_range(0.0, 0.5, 0.01) var undergrowth_density := 0.18
@export_range(0.0, 1.0, 0.05) var shrub_probability := 0.62
@export_range(0.0, 1.0, 0.05) var cluster_probability := 0.55
@export_range(1, 5) var maximum_cluster_size := 4
```

Remove the previous declarations of `undergrowth_density` and `shrub_probability` to avoid duplicates.

### 2. Replace the final placement in `_generate_undergrowth()`

Replace:

```
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

with:

```
_add_undergrowth_cluster(
	cell,
	tile_size
)
```

### 3. Add the cluster function

```
func _add_undergrowth_cluster(
	cell: Vector2i,
	tile_size: int
) -> void:
	var cluster_size := 1

	if random.randf() < cluster_probability:
		cluster_size = random.randi_range(
			2,
			maximum_cluster_size
		)

	for cluster_index in range(cluster_size):
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

This creates small thickets rather than isolated shrubs.

## Reduce the empty halos around resources

Currently, `_is_near_blocked_cell()` uses `resource_clearance`, meaning an entire ring around every tree, bush, and rock remains undecorated. That produces many visible empty squares.

Add this separate check:

```
func _is_blocked_for_undergrowth(
	cell: Vector2i,
	blocked_cells: Dictionary
) -> bool:
	return blocked_cells.has(cell)
```

Then, inside `_generate_undergrowth()`, replace:

```
if _is_near_blocked_cell(
	cell,
	blocked_cells
):
	continue
```

with:

```
if _is_blocked_for_undergrowth(
	cell,
	blocked_cells
):
	continue
```

The undergrowth can now grow beside resource nodes but never directly underneath them. The smaller grass, flower, and mushroom decorations can continue using the larger clearance.

## Make shrubs visually wider

In `_draw_shrub()`, increase:

```
var width := 5.0
```

to:

```
var width := 7.0
```

Then change:

```
width = 6.0
```

to:

```
width = 9.0
```

Change the two side-circle radii from:

```
4.0
```

to:

```
5.0
```

And change the central radius from:

```
5.0
```

to:

```
6.0
```

## Recommended values

```
Decoration Density:       0.42
Undergrowth Density:      0.18
Shrub Probability:        0.62
Cluster Probability:      0.55
Maximum Cluster Size:     4
Resource Clearance:       1
```

This should produce:

- Dense pockets of shrubs and saplings.
- Vegetation growing naturally around mature trees.
- Far less uninterrupted grass.
- Open soil and camp areas for visual breathing room.
- No change to resource availability or player movement.

	If it still feels empty after this, the remaining cause will be the completely undecorated soil patches. The next layer would be leaf litter, roots, moss and small stones specifically for those areas.
The slowdown comes from `ForestDecorator.queue_redraw()` running every frame.

Before the undergrowth update, Godot redrew a few hundred tiny shapes. Now clusters can create several shrubs per cell, and every shrub uses multiple circles. Because the entire decorator is one `Node2D`, animating one fern causes Godot to rebuild **every decoration on the entire map 60 times per second**.

The resource balance and generation are fine—we just need to reduce the visual update frequency.

## Immediate fix — Animate at 12 FPS

Pixel-art vegetation doesn’t need 60 animation updates per second.

### Update `forest_decorator.gd`

Add:

```
@export_category("Performance")
@export_range(4.0, 30.0, 1.0) var animation_fps := 12.0
```

Near `animation_time`, add:

```
var redraw_elapsed := 0.0
```

Replace `_process()` with:

```
func _process(delta: float) -> void:
	animation_time += delta
	redraw_elapsed += delta

	var redraw_interval := 1.0 / animation_fps

	if redraw_elapsed < redraw_interval:
		return

	redraw_elapsed = fmod(
		redraw_elapsed,
		redraw_interval
	)

	queue_redraw()
```

This reduces full forest redraws from approximately 60 per second to 12.

## Do the same for `forest_life.gd`

Add:

```
@export_category("Performance")
@export_range(4.0, 30.0, 1.0) var animation_fps := 15.0
```

Near `animation_time`, add:

```
var redraw_elapsed := 0.0
```

Replace its `_process()` with:

```
func _process(delta: float) -> void:
	animation_time += delta
	redraw_elapsed += delta

	var redraw_interval := 1.0 / animation_fps

	if redraw_elapsed < redraw_interval:
		return

	redraw_elapsed = fmod(
		redraw_elapsed,
		redraw_interval
	)

	queue_redraw()
```

Butterflies, fireflies, and leaves will update at 15 FPS, which suits the pixel-art presentation.

## Reduce the most expensive cluster setting

Also change:

```
Maximum Cluster Size: 4
```

to:

```
Maximum Cluster Size: 3
```

Keep:

```
Undergrowth Density: 0.18
Cluster Probability: 0.55
```

This preserves the dense appearance while preventing especially heavy cells.

## Why this should help

| System             | Before          | After          |
| ------------------ | --------------- | -------------- |
| Forest decorations | ~60 redraws/sec | 12 redraws/sec |
| Forest wildlife    | ~60 redraws/sec | 15 redraws/sec |
| Cluster maximum    | 4 elements      | 3 elements     |
| Resource balance   | Unchanged       | Unchanged      |
| Collisions         | Unchanged       | Unchanged      |

The movement may look slightly more stepped, but that generally looks natural in pixel art. If performance is still poor, set `ForestDecorator → Animation FPS` to `8`. The stronger long-term optimization would be separating static scenery from animated vegetation, but this throttling change should provide a substantial improvement immediately.