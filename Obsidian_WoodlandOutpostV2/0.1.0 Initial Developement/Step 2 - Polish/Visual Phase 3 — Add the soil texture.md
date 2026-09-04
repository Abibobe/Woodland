### 1. Import it

![[soil_tile_01.png]]
Download the file and place it in:

```
res://assets/ground/soil_tile_01.png
```

Verify:

```
Size: 32 × 32
Compress Mode: Lossless
Mipmaps: Off
```

### 2. Add the exported texture

In `world_generator.gd`, beneath `grass_texture`, add:

```
@export var soil_texture: Texture2D
```

### 3. Add a soil drawing function

```
func _draw_soil_tile(tile_rect: Rect2) -> void:
	if soil_texture == null:
		draw_rect(
			tile_rect,
			SOIL_COLOR
		)
		return

	draw_texture_rect(
		soil_texture,
		tile_rect,
		false
	)
```

### 4. Update `_draw()`

Change:

```
if _is_soil_tile(x, y):
	draw_rect(
		tile_rect,
		SOIL_COLOR
	)
else:
	_draw_grass_tile(tile_rect)
```

to:

```
if _is_soil_tile(x, y):
	_draw_soil_tile(tile_rect)
else:
	_draw_grass_tile(tile_rect)
```

### 5. Assign the texture

Select `World` in `game.tscn`, then drag:

```
res://assets/ground/soil_tile_01.png
```

into:

```
Ground Textures → Soil Texture
```

Run the game. Both ground types should now have crisp pixel texture. The edges between them will still be square and blocky—that is expected. Our next ground step will address those transitions separately.