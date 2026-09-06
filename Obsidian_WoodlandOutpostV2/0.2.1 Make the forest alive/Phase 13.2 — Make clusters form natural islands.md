## Phase 13.2 — Make clusters form natural islands

Right now the noise decides where clusters may appear, but `minimum_cluster_spacing` remains identical everywhere. That can produce an evenly spaced pattern.

We’ll allow clusters to overlap slightly in dense woodland cores while leaving more space around their edges.

### 1. Add island controls

In `forest_cluster_layer.gd`, add:

```
@export_category("Woodland Islands")
@export_range(0.5, 4.0, 0.1) var core_spacing := 1.5
@export_range(1.0, 6.0, 0.1) var edge_spacing := 3.2
@export_range(0.1, 3.0, 0.1) var island_contrast := 1.4
```

You can remove the old:

```
minimum_cluster_spacing
```

export.

### 2. Update `_is_valid_cluster_cell()`

Find this section:

```
if not _has_cluster_spacing(cell):
	return false

var noise_value := cluster_noise.get_noise_2d(
	cell.x,
	cell.y
)

if noise_value < cluster_noise_threshold:
	return false
```

Replace it with:

```
var noise_value := cluster_noise.get_noise_2d(
	cell.x,
	cell.y
)

if noise_value < cluster_noise_threshold:
	return false

var island_strength := inverse_lerp(
	cluster_noise_threshold,
	1.0,
	noise_value
)

island_strength = pow(
	clampf(island_strength, 0.0, 1.0),
	island_contrast
)

if not _has_cluster_spacing(
	cell,
	island_strength
):
	return false
```

### 3. Replace `_has_cluster_spacing()`

```
func _has_cluster_spacing(
	candidate: Vector2i,
	island_strength: float
) -> bool:
	var required_spacing := lerpf(
		edge_spacing,
		core_spacing,
		island_strength
	)

	for cluster: Dictionary in clusters:
		var existing_cell := (
			cluster["cell"] as Vector2i
		)

		var distance := Vector2(
			candidate
		).distance_to(
			Vector2(existing_cell)
		)

		if distance < required_spacing:
			return false

	return true
```

## What changes

In high-noise woodland cores:

```
Spacing: approximately 1.5 tiles
Result: overlapping, visually dense vegetation islands
```

Near island edges:

```
Spacing: approximately 3.2 tiles
Result: gradual transition into open grass
```

This should resemble the first concept image more closely: dense groups with irregular edges and readable empty areas between them.

## Recommended settings

```
Cluster Noise Threshold: -0.10
Core Spacing:             1.5
Edge Spacing:             3.2
Island Contrast:          1.4

Small Clusters:           78
Large Clusters:           34
Sapling Clusters:         14
Log Clusters:             12
```

Because the clusters are static and reuse the same textures, allowing some visual overlap should not recreate the procedural-animation performance problem. Resource quantities, collisions and travel remain unchanged.