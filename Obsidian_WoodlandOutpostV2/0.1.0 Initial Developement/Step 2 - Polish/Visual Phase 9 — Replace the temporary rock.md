### 1. Import it
	![[rock_01.png]]
Place it in:

```
res://assets/resources/rock_01.png
```

Use lossless compression and disable mipmaps.

### 2. Add the texture property

In `resource_node.gd`, beneath `tree_texture`, add:

```
@export var rock_texture: Texture2D
```

### 3. Replace `_draw_rock()`

```
func _draw_rock() -> void:
	if rock_texture == null:
		_draw_rock_fallback()
		return

	var texture_size := rock_texture.get_size()

	var draw_position := Vector2(
		-texture_size.x / 2.0,
		-texture_size.y + 8.0
	)

	draw_texture(
		rock_texture,
		draw_position
	)
```

Rename the previous rock function:

```
func _draw_rock_fallback() -> void:
	var rock_shape := PackedVector2Array([
		Vector2(-14, 4),
		Vector2(-11, -9),
		Vector2(-3, -15),
		Vector2(10, -11),
		Vector2(15, 2),
		Vector2(8, 8),
		Vector2(-8, 8)
	])

	draw_colored_polygon(
		rock_shape,
		Color("#70777D")
	)
```

### 4. Assign it

Open `resource_node.tscn`, select the root, and assign:

```
Visuals → Rock Texture: rock_01.png
```

Save and run. Stone resources should now use the new sprite while preserving their existing collision and gathering behaviour.