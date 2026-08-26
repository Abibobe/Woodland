class_name GroundRenderer
extends Node2D


@export_category("Ground Textures")
@export var grass_texture: Texture2D
@export var grass_texture_alt: Texture2D
@export var soil_texture: Texture2D
@export var soil_texture_alt: Texture2D


const GRASS_COLOR := Color("#5f8f4f")
const SOIL_COLOR := Color("#8a6748")

enum EdgeDirection {
	TOP,
	RIGHT,
	BOTTOM,
	LEFT
}

var ground_cells: Array = []
var tile_size: int = 32


func _ready() -> void:
	z_index = -100
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func render_ground(
	new_ground_cells: Array,
	new_tile_size: int
) -> void:
	ground_cells = new_ground_cells
	tile_size = new_tile_size

	queue_redraw()


func _draw() -> void:
	for y in range(ground_cells.size()):
		var row: Array = ground_cells[y]

		for x in range(row.size()):
			var tile_rect := Rect2(
				Vector2(x, y) * tile_size,
				Vector2(tile_size, tile_size)
			)

			var is_soil: bool = row[x]

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


func _draw_tile(
	texture: Texture2D,
	tile_rect: Rect2,
	fallback_color: Color
) -> void:
	if texture == null:
		draw_rect(
			tile_rect,
			fallback_color
		)
		return

	draw_texture_rect(
		texture,
		tile_rect,
		false
	)

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
