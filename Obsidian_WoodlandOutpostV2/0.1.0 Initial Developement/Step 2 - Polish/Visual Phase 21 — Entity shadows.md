### 1. Add the resource shadow

In `resource_node.gd`, add:

```
const SHADOW_COLOR := Color(0.05, 0.08, 0.06, 0.32)
```

At the very beginning of the existing `_draw()` function, call:

```
_draw_shadow()
```

For example:

```
func _draw() -> void:
	_draw_shadow()

	match resource_type:
		# Keep your existing resource drawing here.
```

Add this function:

```
func _draw_shadow() -> void:
	draw_set_transform(
		Vector2(0.0, 3.0),
		0.0,
		Vector2(1.0, 0.35)
	)

	draw_circle(
		Vector2.ZERO,
		12.0,
		SHADOW_COLOR
	)

	draw_set_transform(
		Vector2.ZERO,
		0.0,
		Vector2.ONE
	)
```

The transform temporarily compresses the circle into a pixel-art oval. Resetting it afterward prevents the resource sprite from being distorted.

### 2. Add the player shadow

Open `player.tscn` and add a `Polygon2D` beneath `Player`. Name it:

```
PlayerShadow
```

Place it before `PlayerVisual` in the scene tree:

```
Player
├── PlayerShadow
├── PlayerVisual
├── CollisionShape2D
└── PlayerInteraction
```

Set its polygon points to:

```
(-8, 10)
(-6, 8)
( 6, 8)
( 8, 10)
( 6, 12)
(-6, 12)
```

Set its color to:

```
#0d151052
```

This is a dark green-black with low opacity.

Configure:

```
Mouse Filter: Ignore
Ordering → Z Index: 0
```

### 3. Add the camp shadow

In `camp.gd`, add the same constant:

```
const SHADOW_COLOR := Color(0.05, 0.08, 0.06, 0.32)
```

At the beginning of `_draw()`:

```
func _draw() -> void:
	if current_stage != CampStage.SITE: _draw_shadow()

	if stages_texture != null:
		_draw_stage_texture()
		return

	# Keep the existing fallback match below.
```

Add:

```
func _draw_shadow() -> void:
	draw_set_transform(
		Vector2(0.0, 5.0),
		0.0,
		Vector2(1.0, 0.3)
	)

	draw_circle(
		Vector2.ZERO,
		22.0,
		SHADOW_COLOR
	)

	draw_set_transform(
		Vector2.ZERO,
		0.0,
		Vector2.ONE
	)
```

The shadows are drawn inside their entity nodes, so they move and Y-sort together with their corresponding sprites.