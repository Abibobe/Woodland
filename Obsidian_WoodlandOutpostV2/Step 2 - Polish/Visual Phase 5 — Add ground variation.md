
### 1. Import it
![[grass_tile_02.png]]
Place it in:

```
res://assets/ground/grass_tile_02.png
```

Use the same import settings:

```
Compress Mode: Lossless
Mipmaps: Off
```

### 2. Add the alternate texture

In `ground_renderer.gd`, add:

```
@export var grass_texture_alt: Texture2D
```

### 3. Update the grass section in `_draw()`

Change:

```
else:
	_draw_tile(
		grass_texture,
		tile_rect,
		GRASS_COLOR
	)
```

to:

```
else:
	_draw_tile(
		_get_grass_texture(x, y),
		tile_rect,
		GRASS_COLOR
	)
```

### 4. Add the selection function

```
func _get_grass_texture(
	x: int,
	y: int
) -> Texture2D:
	if grass_texture_alt == null:
		return grass_texture

	var variation_value := (
		x * 7
		+ y * 13
		+ x * y
	)

	if variation_value % 5 == 0:
		return grass_texture_alt

	return grass_texture
```

This uses the alternate tile for approximately one in every five grass cells. The result is deterministic—tiles won’t change while playing.

### 5. Assign it

Select `GroundRenderer` and assign:

```
Grass Texture Alt: grass_tile_02.png
```

Run the game. The difference should be subtle: the map remains visually calm, but the grass pattern should feel less repetitive.