Yes. In the current forest, the larger clusters have raised the visual scale of the environment, so the resources can reasonably grow again.

I recommend scaling the existing sprites in Godot rather than generating another pack:

|Resource|Scale|
|---|---|
|Tree|`1.28×`|
|Berry bush|`1.18×`|
|Rock|`1.15×`|

The tree will gain the most presence, while bushes and rocks remain compatible with the 32×32 terrain.

## Add scale settings

In `resource_node.gd`, add:

```
@export_category("Visual Scale")
@export_range(0.5, 2.0, 0.05) var tree_visual_scale := 1.28
@export_range(0.5, 2.0, 0.05) var bush_visual_scale := 1.18
@export_range(0.5, 2.0, 0.05) var rock_visual_scale := 1.15

const TEXTURE_BOTTOM_PADDING := 14.0
```

The bottom-padding value matches the transparent space beneath the V5 sprites.

## Add a common drawing function

```
func _draw_grounded_texture(
	texture: Texture2D,
	visual_scale: float
) -> void:
	var source_size := texture.get_size()

	var destination_size := (
		source_size * visual_scale
	)

	var scaled_bottom_padding := (
		TEXTURE_BOTTOM_PADDING
		* visual_scale
	)

	var draw_position := Vector2(
		-destination_size.x / 2.0,
		-destination_size.y
			+ scaled_bottom_padding
	)

	draw_texture_rect(
		texture,
		Rect2(
			draw_position,
			destination_size
		),
		false
	)
```

This keeps the baked shadow connected to the resource’s ground position while enlarging everything.

## Simplify the three resource functions

In `_draw_tree()`, replace the positioning and `draw_texture()` section with:

```
_draw_grounded_texture(
	selected_texture,
	tree_visual_scale
)
```

Do the same for the bush:

```
_draw_grounded_texture(
	selected_texture,
	bush_visual_scale
)
```

And rock:

```
_draw_grounded_texture(
	selected_texture,
	rock_visual_scale
)
```

Keep their existing null/fallback checks.

## Raise the gathering bars

```
func _get_progress_bar_y() -> float:
	match resource_type:
		ResourceTypes.Type.WOOD:
			return -100.0

		ResourceTypes.Type.FOOD:
			return -60.0

		ResourceTypes.Type.STONE:
			return -50.0

	return -52.0
```

Keep the collision shapes unchanged. The tree crown may cover multiple tiles visually, but only its trunk should obstruct movement.

This should give resources enough authority against the dense vegetation without making the map feel crowded or changing gameplay.