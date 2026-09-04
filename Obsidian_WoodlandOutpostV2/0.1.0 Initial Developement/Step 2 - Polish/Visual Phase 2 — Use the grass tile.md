The first production asset is ready: grass_tile_01.png.

It is a genuine 32×32 pixel tile with hard pixel edges and no gradients.

### Import it into Godot

1. Download grass_tile_01.png.
![[grass_tile_01.png]]
2. Copy it into:

```
res://assets/ground/
```

3. Select it in Godot’s FileSystem panel.
4. In the **Import** panel, verify:

```
Compress Mode: Lossless
Mipmaps → Generate: Off
```

5. Click **Reimport** if you changed anything.

Don’t modify `world_generator.gd` yet. First confirm that Godot reports the image as `32 × 32`; then we’ll update the renderer to use this tile while keeping the procedural map logic unchanged.


### 1. Add the texture property

Open `world_generator.gd`.

Below the generation exports, add:

```
@export_category("Ground Textures")
@export var grass_texture: Texture2D
```

### 2. Enable sharp texture rendering

Update `_ready()`:

```
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	generate_world()
```

### 3. Replace `_draw()`

Replace the existing `_draw()` function with:

```
func _draw() -> void:
	for y in range(map_height):
		for x in range(map_width):
			var tile_position := Vector2(
				x * tile_size,
				y * tile_size
			)

			var tile_rect := Rect2(
				tile_position,
				Vector2(tile_size, tile_size)
			)

			if _is_soil_tile(x, y):
				draw_rect(
					tile_rect,
					SOIL_COLOR
				)
			else:
				_draw_grass_tile(tile_rect)
```

### 4. Add the grass-drawing function

Add:

```
func _draw_grass_tile(tile_rect: Rect2) -> void:
	if grass_texture == null:
		draw_rect(
			tile_rect,
			GRASS_COLOR
		)
		return

	draw_texture_rect(
		grass_texture,
		tile_rect,
		false
	)
```

The fallback colour means the game still works if the texture is accidentally removed.

### 5. Replace `_get_tile_color()`

Delete the old `_get_tile_color()` function and replace it with:

```
func _is_soil_tile(x: int, y: int) -> bool:
	var noise_value := noise.get_noise_2d(x, y)

	return noise_value > soil_threshold
```

You can also remove:

```
const GRASS_ALT_COLOR
```

It is no longer needed.

Keep:

```
const GRASS_COLOR := Color("#5f8f4f")
const SOIL_COLOR := Color("#8a6748")
```

### 6. Assign the tile

Return to `game.tscn` and select `World`.

In the Inspector, find:

```
Ground Textures
└── Grass Texture
```

Drag this file into the field:

```
res://assets/ground/grass_tile_01.png
```

Run the game. Grass cells should now use the new texture, while soil remains the temporary brown colour.

The procedural system still decides **where** grass appears; the exported texture only decides **how** grass looks. This preserves our clean separation between generation and artwork.