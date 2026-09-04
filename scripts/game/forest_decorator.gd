class_name ForestDecorator
extends Node2D


enum DecorationType {
	GRASS,
	FLOWER,
	PEBBLE,
	BRANCH,
	MUSHROOM,
	FERN
}


@export_category("Decoration Density")
@export_range(0.0, 1.0, 0.01) var decoration_density := 0.32
@export_range(0, 3) var resource_clearance := 1
@export_range(0, 3) var camp_clearance := 1

@export_category("Decoration Colours")
@export var grass_dark := Color("#3f713e")
@export var grass_light := Color("#76a954")
@export var flower_yellow := Color("#e8cf68")
@export var flower_blue := Color("#7998c8")
@export var flower_white := Color("#e4dfc5")
@export var branch_color := Color("#62422b")
@export var pebble_color := Color("#777c74")
@export var mushroom_cap := Color("#a34d43")
@export var fern_color := Color("#356b3c")

@export_category("Wind Animation")
@export_range(0.0, 3.0, 0.05) var wind_strength := 1.25
@export_range(0.1, 3.0, 0.05) var wind_speed := 0.8


var decorations: Array[Dictionary] = []
var random := RandomNumberGenerator.new()
var cluster_noise := FastNoiseLite.new()
var animation_time := 0.0


func _ready() -> void:
	z_index = -50
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func generate_decorations(
	seed_value: int,
	ground_cells: Array,
	map_width: int,
	map_height: int,
	tile_size: int,
	map_center: Vector2i,
	camp_clear_radius: int,
	blocked_cells: Dictionary,
	tree_cells: Array[Vector2i]
) -> void:
	decorations.clear()
	random.seed = seed_value + 32_117
	cluster_noise.seed = seed_value + 75_913
	cluster_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	cluster_noise.frequency = 0.045

	for y in range(2, map_height - 1):
		for x in range(1, map_width - 1):
			var cell := Vector2i(x, y)

			# Soil remains clear in this first version.
			if bool(ground_cells[y][x]):
				continue

			var distance_from_camp := Vector2(
				cell
			).distance_to(
				Vector2(map_center)
			)

			if (
				distance_from_camp
				<= camp_clear_radius + camp_clearance
			):
				continue

			if _is_near_blocked_cell(
				cell,
				blocked_cells
			):
				continue

			var cluster_value := (
				cluster_noise.get_noise_2d(
					cell.x,
					cell.y
				)
			)

			var local_density := clampf(
				decoration_density
					+ absf(cluster_value) * 0.16
					- 0.04,
				0.05,
				0.65
			)

			if random.randf() > local_density:
				continue

			var decoration_type := _choose_decoration_type(
				cell,
				ground_cells,
				tree_cells,
				cluster_value
			)

			_add_decoration(
				cell,
				tile_size,
				decoration_type
			)

			if random.randf() < 0.12:
				_add_decoration(
					cell,
					tile_size,
					decoration_type
				)

	queue_redraw()


func _add_decoration(
	cell: Vector2i,
	tile_size: int,
	decoration_type: DecorationType
) -> void:
	var cell_center := Vector2(
		(cell.x + 0.5) * tile_size,
		(cell.y + 0.5) * tile_size
	)

	var offset := Vector2(
		random.randi_range(-11, 11),
		random.randi_range(-11, 11)
	)

	decorations.append({
		"type": decoration_type,
		"position": (cell_center + offset).round(),
		"variant": random.randi_range(0, 2)
	})

func get_flower_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []

	for decoration: Dictionary in decorations:
		var decoration_type := int(
			decoration["type"]
		)

		if decoration_type != DecorationType.FLOWER:
			continue

		positions.append(
			decoration["position"] as Vector2
		)

	return positions


func get_sheltered_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []

	for decoration: Dictionary in decorations:
		var decoration_type := int(
			decoration["type"]
		)

		if (
			decoration_type != DecorationType.FERN
			and decoration_type != DecorationType.MUSHROOM
		):
			continue

		positions.append(
			decoration["position"] as Vector2
		)

	return positions


func _is_near_blocked_cell(
	cell: Vector2i,
	blocked_cells: Dictionary
) -> bool:
	for offset_y in range(
		-resource_clearance,
		resource_clearance + 1
	):
		for offset_x in range(
			-resource_clearance,
			resource_clearance + 1
		):
			var nearby_cell := (
				cell
				+ Vector2i(offset_x, offset_y)
			)

			if blocked_cells.has(nearby_cell):
				return true

	return false


func _draw() -> void:
	for decoration in decorations:
		var decoration_type := int(
			decoration["type"]
		)

		var draw_position := (
			decoration["position"] as Vector2
		)

		var variant := int(
			decoration["variant"]
		)

		match decoration_type:
			DecorationType.GRASS:
				_draw_grass(
					draw_position,
					variant
				)

			DecorationType.FLOWER:
				_draw_flower(
					draw_position,
					variant
				)

			DecorationType.PEBBLE:
				_draw_pebble(
					draw_position,
					variant
				)

			DecorationType.BRANCH:
				_draw_branch(
					draw_position,
					variant
				)

			DecorationType.MUSHROOM:
				_draw_mushroom(
					draw_position,
					variant
				)
			
			DecorationType.FERN:
				_draw_fern(
					draw_position,
					variant
				)

func _get_wind_offset(
	draw_position: Vector2,
	movement_scale: float = 1.0
) -> Vector2:
	var position_phase := (
		draw_position.x * 0.018
		+ draw_position.y * 0.011
	)

	var movement := sin(
		animation_time * wind_speed
		+ position_phase
	)

	return Vector2(
		movement * wind_strength * movement_scale,
		0.0
	)



func _draw_grass(
	draw_position: Vector2,
	variant: int
) -> void:
	var wind_offset := _get_wind_offset(
		draw_position,
		1.0
	)

	var selected_color := (
		grass_light
		if variant == 0
		else grass_dark
	)

	draw_line(
		draw_position,
		draw_position
			+ Vector2(-2.0, -5.0)
			+ wind_offset,
		selected_color,
		1.0
	)

	draw_line(
		draw_position,
		draw_position
			+ Vector2(0.0, -6.0)
			+ wind_offset,
		selected_color,
		1.0
	)

	draw_line(
		draw_position,
		draw_position
			+ Vector2(3.0, -4.0)
			+ wind_offset,
		selected_color,
		1.0
	)


func _draw_flower(
	draw_position: Vector2,
	variant: int
) -> void:
	var wind_offset := _get_wind_offset(
		draw_position,
		0.75
	)

	var selected_color := flower_yellow

	if variant == 1:
		selected_color = flower_blue
	elif variant == 2:
		selected_color = flower_white

	draw_line(
		draw_position + Vector2(0.0, 1.0),
		draw_position
			+ Vector2(0.0, -3.0)
			+ wind_offset,
		grass_dark,
		1.0
	)

	draw_rect(
		Rect2(
			draw_position
				+ Vector2(-1.0, -5.0)
				+ wind_offset,
			Vector2(3.0, 3.0)
		),
		selected_color
	)


func _draw_pebble(
	draw_position: Vector2,
	variant: int
) -> void:
	var pebble_size := Vector2(3.0, 2.0)

	if variant == 2:
		pebble_size = Vector2(4.0, 3.0)

	draw_rect(
		Rect2(
			draw_position,
			pebble_size
		),
		pebble_color
	)


func _draw_branch(
	draw_position: Vector2,
	variant: int
) -> void:
	var branch_end := (
		draw_position
		+ Vector2(6.0, 2.0)
	)

	if variant == 1:
		branch_end = (
			draw_position
			+ Vector2(5.0, -2.0)
		)

	draw_line(
		draw_position,
		branch_end,
		branch_color,
		2.0
	)


func _draw_mushroom(
	draw_position: Vector2,
	variant: int
) -> void:
	draw_rect(
		Rect2(
			draw_position + Vector2(0.0, -1.0),
			Vector2(2.0, 3.0)
		),
		Color("#d7c29e")
	)

	var cap_width := 4.0

	if variant == 2:
		cap_width = 5.0

	draw_rect(
		Rect2(
			draw_position + Vector2(
				-(cap_width - 2.0) / 2.0,
				-3.0
			),
			Vector2(cap_width, 2.0)
		),
		mushroom_cap
	)


func _choose_decoration_type(
	cell: Vector2i,
	ground_cells: Array,
	tree_cells: Array[Vector2i],
	cluster_value: float
) -> DecorationType:
	var roll := random.randi_range(0, 99)

	if _is_near_tree(cell, tree_cells):
		if roll < 50:
			return DecorationType.FERN

		if roll < 75:
			return DecorationType.MUSHROOM

		if roll < 90:
			return DecorationType.GRASS

		return DecorationType.BRANCH

	if _is_next_to_soil(cell, ground_cells):
		if roll < 45:
			return DecorationType.PEBBLE

		if roll < 70:
			return DecorationType.BRANCH

		return DecorationType.GRASS

	if cluster_value > 0.3:
		if roll < 70:
			return DecorationType.FLOWER

		return DecorationType.GRASS

	if cluster_value < -0.3:
		if roll < 65:
			return DecorationType.FERN

		return DecorationType.GRASS

	if roll < 72:
		return DecorationType.GRASS

	if roll < 84:
		return DecorationType.FLOWER

	if roll < 92:
		return DecorationType.PEBBLE

	if roll < 97:
		return DecorationType.BRANCH

	return DecorationType.MUSHROOM


func _is_near_tree(
	cell: Vector2i,
	tree_cells: Array[Vector2i]
) -> bool:
	for tree_cell in tree_cells:
		var distance := Vector2(cell).distance_to(
			Vector2(tree_cell)
		)

		if distance >= 2.0 and distance <= 4.0:
			return true

	return false


func _is_next_to_soil(
	cell: Vector2i,
	ground_cells: Array
) -> bool:
	var neighbours: Array[Vector2i] = [
		Vector2i.UP,
		Vector2i.RIGHT,
		Vector2i.DOWN,
		Vector2i.LEFT
	]

	for direction: Vector2i in neighbours:
		var neighbour: Vector2i = (
			cell + direction
		)

		if neighbour.y < 0:
			continue

		if neighbour.y >= ground_cells.size():
			continue

		var row: Array = ground_cells[
			neighbour.y
		]

		if (
			neighbour.x < 0
			or neighbour.x >= row.size()
		):
			continue

		if bool(row[neighbour.x]):
			return true

	return false


func _draw_fern(
	draw_position: Vector2,
	variant: int
) -> void:
	var height := 6.0

	if variant == 2:
		height = 8.0

	var wind_offset := _get_wind_offset(
		draw_position,
		0.65
	)

	var fern_tip := (
		draw_position
		+ Vector2(0.0, -height)
		+ wind_offset
	)

	draw_line(
		draw_position,
		fern_tip,
		fern_color,
		1.0
	)

	for leaf_index in range(1, 4):
		var leaf_y := float(leaf_index * 2)
		var movement_ratio := leaf_y / height
		var leaf_offset := wind_offset * movement_ratio

		var leaf_origin := (
			draw_position
			+ Vector2(0.0, -leaf_y)
			+ leaf_offset
		)

		draw_line(
			leaf_origin,
			leaf_origin + Vector2(-3.0, -2.0),
			fern_color,
			1.0
		)

		draw_line(
			leaf_origin,
			leaf_origin + Vector2(3.0, -2.0),
			fern_color,
			1.0
		)

func _process(delta: float) -> void:
	animation_time += delta
	queue_redraw()
