
Yes—and I agree that clearings or coloured markers would weaken the natural, dense-forest effect.

The better approach is **visual hierarchy**:

- Decorative clusters remain dense.
- Background vegetation becomes slightly darker and less saturated.
- Harvestable resources retain brighter colours, stronger contrast and clearer silhouettes.

They can then overlap visually while resources still “pop”.

## Step 1 — Tint only decorative clusters

In `forest_cluster_layer.gd`, add:

```
@export_category("Visual Hierarchy")
@export var cluster_tint := Color(
	0.72,
	0.78,
	0.68,
	1.0
)
```

Then, inside `_draw()`, replace:

```
draw_texture(
	texture,
	draw_position - texture_size / 2.0
)
```

with:

```
draw_texture(
	texture,
	draw_position - texture_size / 2.0,
	cluster_tint
)
```

This multiplies the cluster colours by a muted green-grey tint. It particularly reduces the visual strength of flowers and mushrooms, which currently compete with berry bushes.

Start with:

```
Cluster Tint
R: 0.72
G: 0.78
B: 0.68
A: 1.00
```

If that is too dark, try:

```
R: 0.82
G: 0.86
B: 0.78
A: 1.00
```

## Step 2 — Keep individual ground details even quieter

If you still use the original `ForestDecorator`, add:

```
@export var decoration_tint := Color(
	0.68,
	0.76,
	0.66,
	1.0
)
```

In its `_draw_atlas_sprite()`, update:

```
draw_texture_rect_region(
	decoration_atlas,
	destination_rect,
	source_rect
)
```

to:

```
draw_texture_rect_region(
	decoration_atlas,
	destination_rect,
	source_rect,
	decoration_tint
)
```

This places the visual hierarchy at:

```
Harvestable resources: 100% colour and contrast
Large clusters:         ~75% colour intensity
Small ground details:   ~70% colour intensity
```

## Step 3 — Keep resources above decorative vegetation

Your cluster layer currently uses:

```
z_index = -45
```

Keep resources at their normal `z_index = 0`.

Do not give decorative clusters positive Z values. This ensures resource sprites render over clusters when they overlap.

## Remove the previous marker idea

If you already added:

```
_draw_resource_marker()
```

remove it. Also remove the marker colour constants. They are unnecessary with this approach.

The result should stay visually dense, but your eyes will naturally read the full-colour trees, red berry bushes and grey rocks before the muted vegetation surrounding them. This is the same foreground/background contrast technique used by many dense top-down games.