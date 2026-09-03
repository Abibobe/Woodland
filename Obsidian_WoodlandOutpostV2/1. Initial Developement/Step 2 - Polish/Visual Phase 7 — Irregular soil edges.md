Now we’ll soften soil boundaries procedurally. We don’t need sixteen transition images: `GroundRenderer` can overlay narrow, irregular pieces of the grass texture along soil edges.

### 1. Change the soil branch in `_draw()`

Find:

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
```

Replace it with:

```
if is_soil:
	var selected_soil := _get_texture_variant(
		soil_texture,
		soil_texture_alt,
		x,
		y,
		2
	)

	_draw_soil_with_edges(
		x,
		y,
		tile_rect,
		selected_soil
	)
```

Leave the grass branch unchanged.

### 2. Add edge-direction constants

Near the other constants, add:

```
enum EdgeDirection {
	TOP,
	RIGHT,
	BOTTOM,
	LEFT
}
```

### 3. Add the soil-edge functions

Add these functions beneath `_draw_tile()`:

```
func _draw_soil_with_edges(
	cell_x: int,
	cell_y: int,
	tile_rect: Rect2,
	selected_soil: Texture2D
) -> void:
	_draw_tile(
		selected_soil,
		tile_rect,
		SOIL_COLOR
	)

	var selected_grass := _get_texture_variant(
		grass_texture,
		grass_texture_alt,
		cell_x,
		cell_y,
		0
	)

	if _is_grass_cell(cell_x, cell_y - 1):
		_draw_grass_edge(
			selected_grass,
			tile_rect,
			cell_x,
			cell_y,
			EdgeDirection.TOP
		)

	if _is_grass_cell(cell_x + 1, cell_y):
		_draw_grass_edge(
			selected_grass,
			tile_rect,
			cell_x,
			cell_y,
			EdgeDirection.RIGHT
		)

	if _is_grass_cell(cell_x, cell_y + 1):
		_draw_grass_edge(
			selected_grass,
			tile_rect,
			cell_x,
			cell_y,
			EdgeDirection.BOTTOM
		)

	if _is_grass_cell(cell_x - 1, cell_y):
		_draw_grass_edge(
			selected_grass,
			tile_rect,
			cell_x,
			cell_y,
			EdgeDirection.LEFT
		)


func _is_grass_cell(x: int, y: int) -> bool:
	if y < 0 or y >= ground_cells.size():
		return false

	var row: Array = ground_cells[y]

	if x < 0 or x >= row.size():
		return false

	return not bool(row[x])
```

### 4. Draw the irregular edge fragments

Add:

```
func _draw_grass_edge(
	selected_grass: Texture2D,
	tile_rect: Rect2,
	cell_x: int,
	cell_y: int,
	direction: EdgeDirection
) -> void:
	var segment_size := 4
	var segment_count := 8
	var source_size := 32.0
	var scale := tile_rect.size.x / source_size

	for segment in range(segment_count):
		var variation_seed := (
			cell_x * 17
			+ cell_y * 31
			+ segment * 11
			+ int(direction) * 23
		)

		var depth := 2 + variation_seed % 4
		var source_rect := Rect2()

		match direction:
			EdgeDirection.TOP:
				source_rect = Rect2(
					segment * segment_size,
					0,
					segment_size,
					depth
				)

			EdgeDirection.RIGHT:
				source_rect = Rect2(
					32 - depth,
					segment * segment_size,
					depth,
					segment_size
				)

			EdgeDirection.BOTTOM:
				source_rect = Rect2(
					segment * segment_size,
					32 - depth,
					segment_size,
					depth
				)

			EdgeDirection.LEFT:
				source_rect = Rect2(
					0,
					segment * segment_size,
					depth,
					segment_size
				)

		var destination_rect := Rect2(
			tile_rect.position + source_rect.position * scale,
			source_rect.size * scale
		)

		_draw_texture_fragment(
			selected_grass,
			destination_rect,
			source_rect
		)
```

Finally, add:

```
func _draw_texture_fragment(
	texture: Texture2D,
	destination_rect: Rect2,
	source_rect: Rect2
) -> void:
	if texture == null:
		draw_rect(
			destination_rect,
			GRASS_COLOR
		)
		return

	draw_texture_rect_region(
		texture,
		destination_rect,
		source_rect
	)
```

Run the game. Grass will now intrude between two and five pixels into soil cells along exposed edges, producing irregular pixel-art boundaries.

The underlying map data remains a simple grass/soil grid. This effect belongs entirely to `GroundRenderer`, so it changes appearance without affecting generation, resource placement, or movement.