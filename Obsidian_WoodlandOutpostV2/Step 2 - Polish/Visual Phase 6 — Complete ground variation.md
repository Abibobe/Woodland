### 1. Import it
![[soil_tile_02.png]]
Place it in:

```
res://assets/ground/soil_tile_02.png
```

Use lossless compression with mipmaps disabled.

### 2. Add the export

In `ground_renderer.gd`:

```
@export var soil_texture_alt: Texture2D
```

### 3. Update `_draw()`

Replace the soil and grass texture selections with:

```
if is_soil:
	_draw_tile(
		_get_texture_variant(
			soil_texture,
			soil_texture_alt,
			x,
			y,
			2
		),
		tile_rect,
		SOIL_COLOR
	)
else:
	_draw_tile(
		_get_texture_variant(
			grass_texture,
			grass_texture_alt,
			x,
			y,
			0
		),
		tile_rect,
		GRASS_COLOR
	)
```

### 4. Replace `_get_grass_texture()`

Delete `_get_grass_texture()` and add this reusable version:

```
func _get_texture_variant(
	primary_texture: Texture2D,
	alternate_texture: Texture2D,
	x: int,
	y: int,
	variation_offset: int
) -> Texture2D:
	if alternate_texture == null:
		return primary_texture

	var variation_value := (
		x * 7
		+ y * 13
		+ x * y
		+ variation_offset
	)

	if variation_value % 5 == 0:
		return alternate_texture

	return primary_texture
```

### 5. Assign the texture

On `GroundRenderer`, set:

```
Soil Texture Alt: soil_tile_02.png
```

Run the game. Both terrain types should now have subtle variation without adding extra generation logic. The next step will focus on making soil patch boundaries less square.