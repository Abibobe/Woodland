class_name ForestDecorator
extends Node2D


enum DecorationType {
	GRASS,
	FLOWER,
	PEBBLE,
	BRANCH,
	MUSHROOM,
	FERN,
	SAPLING,
	SHRUB,
	STUMP,
	FALLEN_LOG,
	MOSS,
	LEAF_LITTER
}

@export_category("Decoration Sprites")
@export var decoration_atlas: Texture2D

@export_category("Decoration Density")
@export_range(0.0, 1.0, 0.01) var decoration_density := 0.32
@export_range(0, 3) var resource_clearance := 1
@export_range(0, 3) var camp_clearance := 1

@export_category("Forest Floor")
@export_range(0.0, 0.4, 0.01) var forest_floor_density := 0.10
@export_range(0.0, 1.0, 0.05) var woodland_floor_bias := 0.65

@export_category("Decorative Undergrowth")
@export_range(0.0, 0.5, 0.01) var undergrowth_density := 0.18
@export_range(0.0, 1.0, 0.05) var shrub_probability := 0.62
@export_range(0.0, 1.0, 0.05) var cluster_probability := 0.55
@export_range(1, 5) var maximum_cluster_size := 3


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
@export var sapling_trunk_color := Color("#65462d")
@export var sapling_dark_color := Color("#285437")
@export var sapling_light_color := Color("#487a43")
@export var shrub_dark_color := Color("#315f39")
@export var shrub_light_color := Color("#568447")

@export_category("Performance")
@export_range(4.0, 30.0, 1.0) var animation_fps := 12.0

var decorations: Array[Dictionary] = []
var random := RandomNumberGenerator.new()
var cluster_noise := FastNoiseLite.new()

const ATLAS_CELL_SIZE := Vector2(32.0, 32.0)

const ATLAS_SAPLING_A := Vector2i(0, 0)
const ATLAS_SAPLING_B := Vector2i(1, 0)
const ATLAS_SHRUB_A := Vector2i(2, 0)
const ATLAS_SHRUB_B := Vector2i(3, 0)

const ATLAS_STUMP := Vector2i(0, 1)
const ATLAS_LOG := Vector2i(1, 1)
const ATLAS_MOSS := Vector2i(2, 1)
const ATLAS_LEAVES := Vector2i(3, 1)

const ATLAS_FERN := Vector2i(0, 2)
const ATLAS_FLOWERS := Vector2i(1, 2)
const ATLAS_MUSHROOMS := Vector2i(2, 2)
const ATLAS_GRASS := Vector2i(3, 2)


#var animation_time := 0.0
#var redraw_elapsed := 0.0


func _ready() -> void:
	z_index = -50
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(false)


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

			if _is_blocked_for_undergrowth(
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
	
	_generate_undergrowth(
		ground_cells,
		map_width,
		map_height,
		tile_size,
		map_center,
		camp_clear_radius,
		blocked_cells
	)
	
	_generate_forest_floor(
		ground_cells,
		map_width,
		map_height,
		tile_size,
		map_center,
		camp_clear_radius,
		blocked_cells,
		tree_cells
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
	if decoration_atlas == null:
		return

	for decoration: Dictionary in decorations:
		var decoration_type := int(
			decoration["type"]
		)

		var draw_position := (
			decoration["position"] as Vector2
		)

		var variant := int(
			decoration["variant"]
		)

		var atlas_cell := _get_atlas_cell(
			decoration_type,
			variant
		)

		_draw_atlas_sprite(
			draw_position,
			atlas_cell
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

	
	var fern_tip := (
		draw_position
		+ Vector2(0.0, -height)
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
		
		var leaf_origin := (
			draw_position
			+ Vector2(0.0, -leaf_y)
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


func _generate_undergrowth(
	ground_cells: Array,
	map_width: int,
	map_height: int,
	tile_size: int,
	map_center: Vector2i,
	camp_clear_radius: int,
	blocked_cells: Dictionary
) -> void:
	for y in range(2, map_height - 1):
		for x in range(1, map_width - 1):
			var cell := Vector2i(x, y)

			# Keep soil paths and clearings unobstructed.
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
				undergrowth_density
					+ maxf(-cluster_value, 0.0) * 0.12,
				0.0,
				0.28
			)

			if random.randf() > local_density:
				continue

			var decoration_type: DecorationType

			_add_undergrowth_cluster(
				cell,
				tile_size
			)


func _add_undergrowth_cluster(
	cell: Vector2i,
	tile_size: int
) -> void:
	var cluster_size := 1

	if random.randf() < cluster_probability:
		cluster_size = random.randi_range(
			2,
			maximum_cluster_size
		)

	for cluster_index in range(cluster_size):
		var decoration_type: DecorationType

		if random.randf() < shrub_probability:
			decoration_type = DecorationType.SHRUB
		else:
			decoration_type = DecorationType.SAPLING

		_add_decoration(
			cell,
			tile_size,
			decoration_type
		)

func _is_blocked_for_undergrowth(
	cell: Vector2i,
	blocked_cells: Dictionary
) -> bool:
	return blocked_cells.has(cell)


func _get_atlas_cell(
	decoration_type: int,
	variant: int
) -> Vector2i:
	match decoration_type:
		DecorationType.GRASS:
			return ATLAS_GRASS

		DecorationType.FLOWER:
			return ATLAS_FLOWERS

		DecorationType.PEBBLE:
			return ATLAS_MOSS

		DecorationType.BRANCH:
			return ATLAS_LOG

		DecorationType.MUSHROOM:
			return ATLAS_MUSHROOMS

		DecorationType.FERN:
			return ATLAS_FERN

		DecorationType.SAPLING:
			if variant % 2 == 0:
				return ATLAS_SAPLING_A

			return ATLAS_SAPLING_B

		DecorationType.SHRUB:
			if variant % 2 == 0:
				return ATLAS_SHRUB_A

			return ATLAS_SHRUB_B

		DecorationType.STUMP:
			return ATLAS_STUMP

		DecorationType.FALLEN_LOG:
			return ATLAS_LOG

		DecorationType.MOSS:
			return ATLAS_MOSS

		DecorationType.LEAF_LITTER:
			return ATLAS_LEAVES
	return ATLAS_GRASS

func _draw_atlas_sprite(
	draw_position: Vector2,
	atlas_cell: Vector2i
) -> void:
	var source_position := Vector2(
		atlas_cell.x * ATLAS_CELL_SIZE.x,
		atlas_cell.y * ATLAS_CELL_SIZE.y
	)

	var source_rect := Rect2(
		source_position,
		ATLAS_CELL_SIZE
	)

	# The generated position represents the point where the
	# decoration meets the ground.
	var destination_rect := Rect2(
		draw_position - Vector2(16.0, 28.0),
		ATLAS_CELL_SIZE
	)

	draw_texture_rect_region(
		decoration_atlas,
		destination_rect,
		source_rect
	)

func _generate_forest_floor(
	ground_cells: Array,
	map_width: int,
	map_height: int,
	tile_size: int,
	map_center: Vector2i,
	camp_clear_radius: int,
	blocked_cells: Dictionary,
	tree_cells: Array[Vector2i]
) -> void:
	for y in range(2, map_height - 1):
		for x in range(1, map_width - 1):
			var cell := Vector2i(x, y)

			# Keep soil areas visually distinct.
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

			# Do not place scenery directly beneath resources.
			if blocked_cells.has(cell):
				continue

			var near_tree := _is_near_tree(
				cell,
				tree_cells
			)

			var cluster_value := (
				cluster_noise.get_noise_2d(
					cell.x,
					cell.y
				)
			)

			var local_density := forest_floor_density

			if near_tree:
				local_density += 0.08

			if cluster_value < -0.2:
				local_density += 0.04

			local_density = clampf(
				local_density,
				0.0,
				0.25
			)

			if random.randf() > local_density:
				continue

			var decoration_type := (
				_choose_forest_floor_type(
					near_tree,
					cluster_value
				)
			)

			_add_decoration(
				cell,
				tile_size,
				decoration_type
			)

func _choose_forest_floor_type(
	near_tree: bool,
	cluster_value: float
) -> DecorationType:
	var roll := random.randi_range(0, 99)

	if near_tree:
		if roll < 38:
			return DecorationType.LEAF_LITTER

		if roll < 66:
			return DecorationType.MOSS

		if roll < 78:
			return DecorationType.FALLEN_LOG

		if roll < 86:
			return DecorationType.STUMP

		if roll < 94:
			return DecorationType.MUSHROOM

		return DecorationType.FERN

	if cluster_value < -0.25:
		if roll < 55:
			return DecorationType.MOSS

		if roll < 82:
			return DecorationType.LEAF_LITTER

		return DecorationType.FERN

	if roll < 50:
		return DecorationType.LEAF_LITTER

	if roll < 75:
		return DecorationType.MOSS

	if roll < 89:
		return DecorationType.GRASS

	return DecorationType.FLOWER
