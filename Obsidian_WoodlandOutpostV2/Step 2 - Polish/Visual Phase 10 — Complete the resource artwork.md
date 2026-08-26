### 1. Import it
![[berry_bush_01.png]]
Place it in:

```
res://assets/resources/berry_bush_01.png
```

Use lossless compression with mipmaps disabled.

### 2. Add the texture

In `resource_node.gd`, add:

```
@export var bush_texture: Texture2D
```

Your visual exports should now be:

```
@export_category("Visuals")
@export var tree_texture: Texture2D
@export var rock_texture: Texture2D
@export var bush_texture: Texture2D
```

### 3. Replace `_draw_berry_bush()`

```
func _draw_berry_bush() -> void:
	if bush_texture == null:
		_draw_berry_bush_fallback()
		return

	var texture_size := bush_texture.get_size()

	var draw_position := Vector2(
		-texture_size.x / 2.0,
		-texture_size.y + 6.0
	)

	draw_texture(
		bush_texture,
		draw_position
	)
```

Rename the previous drawing function:

```
func _draw_berry_bush_fallback() -> void:
	draw_circle(
		Vector2.ZERO,
		15,
		Color("#3E7045")
	)

	draw_circle(Vector2(-7, -5), 3, Color("#A83E5B"))
	draw_circle(Vector2(6, -7), 3, Color("#A83E5B"))
	draw_circle(Vector2(3, 5), 3, Color("#A83E5B"))
```

### 4. Assign it

Open `resource_node.tscn` and assign:

```
Visuals → Bush Texture: berry_bush_01.png
```

Run the game. Trees, rocks, and berry bushes should now all use consistent pixel-art sprites while retaining the same gathering and collision logic.