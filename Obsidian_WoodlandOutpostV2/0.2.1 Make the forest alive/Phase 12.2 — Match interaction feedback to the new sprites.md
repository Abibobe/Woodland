Now that the shadows are baked into the V5 files, we should align the gathering bars and selection brackets with each resource’s new proportions.

### 1. Confirm procedural shadows are disabled

Your `_draw()` should be:

```
func _draw() -> void:
	match resource_type:
		ResourceTypes.Type.WOOD:
			_draw_tree()

		ResourceTypes.Type.STONE:
			_draw_rock()

		ResourceTypes.Type.FOOD:
			_draw_berry_bush()
```

Delete or leave unused:

```
func _draw_shadow()
```

and:

```
const SHADOW_COLOR
```

### 2. Update the progress-bar positions

Replace `_get_progress_bar_y()` with:

```
func _get_progress_bar_y() -> float:
	match resource_type:
		ResourceTypes.Type.WOOD:
			return -84.0

		ResourceTypes.Type.FOOD:
			return -52.0

		ResourceTypes.Type.STONE:
			return -44.0

	return -48.0
```

### 3. Configure the interaction highlight

Add:

```
func _configure_interaction_highlight() -> void:
	match resource_type:
		ResourceTypes.Type.WOOD:
			# Tight around the tree trunk.
			interaction_highlight.position = Vector2(
				0.0,
				-1.0
			)
			interaction_highlight.scale = Vector2(
				0.72,
				1.0
			)

		ResourceTypes.Type.FOOD:
			# Wider around the bush footprint.
			interaction_highlight.position = Vector2(
				0.0,
				-1.0
			)
			interaction_highlight.scale = Vector2(
				1.30,
				1.0
			)

		ResourceTypes.Type.STONE:
			interaction_highlight.position = Vector2(
				0.0,
				1.0
			)
			interaction_highlight.scale = Vector2(
				1.12,
				0.90
			)
```

### 4. Call it from `_ready()`

Add it after configuring the progress bar:

```
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	_configure_gathering_progress_bar()
	_configure_interaction_highlight()
	_update_gathering_progress_bar()

	gathering_progress_bar.hide()
	queue_redraw()
```

### 5. Keep the collision footprint unchanged

Continue using:

```
CollisionShape2D
Position: 0, -6
Size: 24 × 24
```

The large tree crown is visual. Expanding its collision to match the complete sprite would make the dense forest difficult to navigate.

### Test

- Tree brackets should sit close to the trunk rather than spanning the shadow.
- Bush brackets should surround most of the bush base.
- Rock brackets should sit just outside the rock.
- Gathering bars should remain above every variant.
- The player should still move behind tree crowns while colliding only with their trunks.
- Shadows should move naturally with the gathering shake because they are part of the sprites.

This completes the visual integration of the larger resource artwork without changing gameplay.