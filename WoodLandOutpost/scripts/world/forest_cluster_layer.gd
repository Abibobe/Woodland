class_name ForestClusterLayer
extends Node2D


@export_category("Cluster Textures")
@export var small_clusters: Array[Texture2D] = []
@export var large_clusters: Array[Texture2D] = []
@export var sapling_clusters: Array[Texture2D] = []
@export var log_clusters: Array[Texture2D] = []

@export_category("Cluster Counts")
@export_range(0, 200) var small_cluster_count := 78
@export_range(0, 100) var large_cluster_count := 34
@export_range(0, 50) var sapling_cluster_count := 14
@export_range(0, 50) var log_cluster_count := 12

@export_category("Placement")
@export_range(0, 5) var resource_clearance := 1
@export_range(0, 6) var additional_camp_clearance := 2
@export_range(-1.0, 1.0, 0.05) var cluster_noise_threshold := -0.10

@export_category("Visual Hierarchy")
@export var cluster_tint := Color(
	0.72,
	0.78,
	0.68,
	1.0
)

@export var decoration_tint := Color(
	0.68,
	0.76,
	0.66,
	1.0
)

@export_category("Woodland Islands")
@export_range(0.5, 4.0, 0.1) var core_spacing := 1.5
@export_range(1.0, 6.0, 0.1) var edge_spacing := 3.2
@export_range(0.1, 3.0, 0.1) var island_contrast := 1.4

var clusters: Array[Dictionary] = []

var random := RandomNumberGenerator.new()
var cluster_noise := FastNoiseLite.new()


func _ready() -> void:
	z_index = -45
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(false)


func generate_clusters(
	seed_value: int,
	ground_cells: Array,
	map_width: int,
	map_height: int,
	tile_size: int,
	map_center: Vector2i,
	camp_clear_radius: int,
	blocked_cells: Dictionary
) -> void:
	clusters.clear()

	random.seed = seed_value + 481_337

	cluster_noise.seed = seed_value + 723_119
	cluster_noise.noise_type = (
		FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	)
	cluster_noise.frequency = 0.055

	# Place visually important groups first.
	_place_cluster_group(
		large_clusters,
		large_cluster_count,
		ground_cells,
		map_width,
		map_height,
		tile_size,
		map_center,
		camp_clear_radius,
		blocked_cells
	)

	_place_cluster_group(
		sapling_clusters,
		sapling_cluster_count,
		ground_cells,
		map_width,
		map_height,
		tile_size,
		map_center,
		camp_clear_radius,
		blocked_cells
	)

	_place_cluster_group(
		log_clusters,
		log_cluster_count,
		ground_cells,
		map_width,
		map_height,
		tile_size,
		map_center,
		camp_clear_radius,
		blocked_cells
	)

	_place_cluster_group(
		small_clusters,
		small_cluster_count,
		ground_cells,
		map_width,
		map_height,
		tile_size,
		map_center,
		camp_clear_radius,
		blocked_cells
	)

	queue_redraw()


func _place_cluster_group(
	textures: Array[Texture2D],
	requested_count: int,
	ground_cells: Array,
	map_width: int,
	map_height: int,
	tile_size: int,
	map_center: Vector2i,
	camp_clear_radius: int,
	blocked_cells: Dictionary
) -> void:
	if textures.is_empty():
		return

	var placed_count := 0
	var attempts := 0
	var maximum_attempts := requested_count * 150

	while (
		placed_count < requested_count
		and attempts < maximum_attempts
	):
		attempts += 1

		var cell := Vector2i(
			random.randi_range(2, map_width - 3),
			random.randi_range(3, map_height - 3)
		)

		if not _is_valid_cluster_cell(
			cell,
			ground_cells,
			map_center,
			camp_clear_radius,
			blocked_cells
		):
			continue

		var texture_index := random.randi_range(
			0,
			textures.size() - 1
		)

		var cell_center := Vector2(
			(cell.x + 0.5) * tile_size,
			(cell.y + 0.5) * tile_size
		)

		var visual_offset := Vector2(
			random.randi_range(-8, 8),
			random.randi_range(-6, 6)
		)

		clusters.append({
			"cell": cell,
			"position": (
				cell_center + visual_offset
			).round(),
			"texture": textures[texture_index]
		})

		placed_count += 1

	if placed_count < requested_count:
		push_warning(
			"Placed %d of %d requested forest clusters."
			% [
				placed_count,
				requested_count
			]
		)


func _is_valid_cluster_cell(
	cell: Vector2i,
	ground_cells: Array,
	map_center: Vector2i,
	camp_clear_radius: int,
	blocked_cells: Dictionary
) -> bool:
	# Keep soil clear so it forms natural visual routes.
	if bool(ground_cells[cell.y][cell.x]):
		return false

	var distance_from_camp := Vector2(
		cell
	).distance_to(
		Vector2(map_center)
	)

	if (
		distance_from_camp
		<= camp_clear_radius + additional_camp_clearance
	):
		return false

	if _is_near_resource(
		cell,
		blocked_cells
	):
		return false

	var noise_value := cluster_noise.get_noise_2d(
		cell.x,
		cell.y
	)

	if noise_value < cluster_noise_threshold:
		return false

	var island_strength := inverse_lerp(
		cluster_noise_threshold,
		1.0,
		noise_value
	)

	island_strength = pow(
		clampf(island_strength, 0.0, 1.0),
		island_contrast
	)

	if not _has_cluster_spacing(
		cell,
		island_strength
	):
		return false

	return true


func _is_near_resource(
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


func _has_cluster_spacing(
	candidate: Vector2i,
	island_strength: float
) -> bool:
	var required_spacing := lerpf(
		edge_spacing,
		core_spacing,
		island_strength
	)

	for cluster: Dictionary in clusters:
		var existing_cell := (
			cluster["cell"] as Vector2i
		)

		var distance := Vector2(
			candidate
		).distance_to(
			Vector2(existing_cell)
		)

		if distance < required_spacing:
			return false

	return true


func _draw() -> void:
	for cluster: Dictionary in clusters:
		var texture := (
			cluster["texture"] as Texture2D
		)

		if texture == null:
			continue

		var draw_position := (
			cluster["position"] as Vector2
		)

		var texture_size := texture.get_size()

		draw_texture(
			texture,
			draw_position - texture_size / 2.0,
			cluster_tint
		)
