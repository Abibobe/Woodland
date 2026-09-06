class_name ResourceSpawner
extends Node2D


@export_category("Resource Scene")
@export var resource_scene: PackedScene

@export_category("Resource Counts")
@export_range(0, 200) var tree_count: int = 28
@export_range(0, 100) var rock_count: int = 10
@export_range(0, 100) var bush_count: int = 8

@export_category("Winnability Guarantees")
@export_range(1, 100) var required_wood := 35
@export_range(1, 100) var required_stone := 15
@export_range(1, 100) var required_food := 7

@export_range(1.0, 3.0, 0.1) var safety_multiplier := 1.5
@export_range(1, 10) var units_per_resource := 3

@export_category("Starting Area")
@export_range(1, 10) var clear_radius: int = 4

@export_category("Resource Distribution")
@export_range(0, 50) var nearby_tree_count := 12
@export_range(0, 30) var nearby_bush_count := 6
@export_range(5, 30) var nearby_maximum_distance := 10
@export_range(5, 40) var stone_minimum_distance := 12

@export_category("Spawn Destination")
@export var resource_parent: Node2D

@export_range(0, 3) var minimum_resource_spacing := 1 #1 == no resources adjacent 


var spawned_resources: Array[ResourceNode] = []
var random := RandomNumberGenerator.new()
var occupied_cells: Dictionary = {}
var resource_cells_by_type: Dictionary = {}



func generate_resources(
	seed_value: int,
	map_width: int,
	map_height: int,
	tile_size: int
) -> void:
	_clear_existing_resources()

	random.seed = seed_value + 9187
	occupied_cells.clear()

	resource_cells_by_type = {
		ResourceTypes.Type.WOOD: [],
		ResourceTypes.Type.STONE: [],
		ResourceTypes.Type.FOOD: []
	}

	var map_center := Vector2i(
		map_width / 2,
		map_height / 2
	)

	var final_tree_count := maxi(
		tree_count,
		_get_guaranteed_node_count(required_wood)
	)

	var final_rock_count := maxi(
		rock_count,
		_get_guaranteed_node_count(required_stone)
	)

	var final_bush_count := maxi(
		bush_count,
		_get_guaranteed_node_count(required_food)
	)

	var guaranteed_trees := mini(
		nearby_tree_count,
		final_tree_count
	)

	var guaranteed_bushes := mini(
		nearby_bush_count,
		final_bush_count
	)

	# Starter wood near camp.
	_spawn_resource_type(
		ResourceTypes.Type.WOOD,
		guaranteed_trees,
		map_width,
		map_height,
		tile_size,
		map_center,
		float(clear_radius),
		float(nearby_maximum_distance)
	)

	# Starter food near camp.
	_spawn_resource_type(
		ResourceTypes.Type.FOOD,
		guaranteed_bushes,
		map_width,
		map_height,
		tile_size,
		map_center,
		float(clear_radius),
		float(nearby_maximum_distance)
	)

	# Remaining trees can appear throughout the forest.
	_spawn_resource_type(
		ResourceTypes.Type.WOOD,
		final_tree_count - guaranteed_trees,
		map_width,
		map_height,
		tile_size,
		map_center,
		float(clear_radius),
		-1.0
	)

	# Remaining bushes can appear throughout the forest.
	_spawn_resource_type(
		ResourceTypes.Type.FOOD,
		final_bush_count - guaranteed_bushes,
		map_width,
		map_height,
		tile_size,
		map_center,
		float(clear_radius),
		-1.0 # -1 === no upper distance
	)

	# Stone begins farther from camp.
	_spawn_resource_type(
		ResourceTypes.Type.STONE,
		final_rock_count,
		map_width,
		map_height,
		tile_size,
		map_center,
		float(stone_minimum_distance),
		-1.0
	)


func _spawn_resource_type(
	resource_type: int,
	amount: int,
	map_width: int,
	map_height: int,
	tile_size: int,
	map_center: Vector2i,
	minimum_distance: float,
	maximum_distance: float
) -> void:
	for resource_index in range(amount):
		var cell := _find_available_cell(
			map_width,
			map_height,
			map_center,
			minimum_distance,
			maximum_distance
		)

		if cell == Vector2i(-1, -1):
			push_warning(
				"Could not find space for resource %s."
				% resource_index
			)
			return

		_spawn_resource(
			resource_type,
			cell,
			tile_size
		)


func _find_available_cell(
	map_width: int,
	map_height: int,
	map_center: Vector2i,
	minimum_distance: float,
	maximum_distance: float
) -> Vector2i:
	var maximum_attempts := 2000

	for attempt in range(maximum_attempts):
		var candidate := Vector2i(
			random.randi_range(1, map_width - 2),
			random.randi_range(2, map_height - 2)
		)

		if not _has_required_spacing(candidate):
			continue

		var distance_from_camp := Vector2(
			candidate
		).distance_to(
			Vector2(map_center)
		)

		if distance_from_camp < minimum_distance:
			continue

		if (
			maximum_distance >= 0.0
			and distance_from_camp > maximum_distance
		):
			continue

		occupied_cells[candidate] = true
		return candidate

	return Vector2i(-1, -1)


func _spawn_resource(
	resource_type: int,
	cell: Vector2i,
	tile_size: int
) -> void:
	if resource_scene == null:
		push_error("ResourceSpawner has no Resource Scene.")
		return

	var resource := resource_scene.instantiate() as ResourceNode

	if resource == null:
		push_error("The assigned scene is not a ResourceNode.")
		return

	resource.resource_type = resource_type
	resource.resource_amount = units_per_resource
	
	resource.visual_variant = posmod(
		cell.x * 31
			+ cell.y * 17
			+ resource_type * 13,
		3
	)
	
	var stored_cells: Array = (
		resource_cells_by_type.get(
			resource_type,
			[]
		)
	)

	stored_cells.append(cell)

	resource_cells_by_type[resource_type] = stored_cells
	
	
	var destination := resource_parent

	if destination == null:
		destination = self

	destination.add_child(resource)
	spawned_resources.append(resource)

	resource.position = Vector2(
		(cell.x + 0.5) * tile_size,
		(cell.y + 0.5) * tile_size
	)


func _clear_existing_resources() -> void:
	for resource in spawned_resources:
		if is_instance_valid(resource):
			resource.queue_free()

	spawned_resources.clear()


func _get_guaranteed_node_count(
	required_amount: int
) -> int:
	var safe_amount := ceili(
		required_amount * safety_multiplier
	)

	return ceili(
		float(safe_amount) / float(units_per_resource)
	)

func _has_required_spacing(
	candidate: Vector2i
) -> bool:
	for offset_y in range(
		-minimum_resource_spacing,
		minimum_resource_spacing + 1
	):
		for offset_x in range(
			-minimum_resource_spacing,
			minimum_resource_spacing + 1
		):
			var nearby_cell := (
				candidate
				+ Vector2i(offset_x, offset_y)
			)

			if occupied_cells.has(nearby_cell):
				return false

	return true


func get_occupied_cells() -> Dictionary:
	return occupied_cells.duplicate()


func get_resource_cells(
	resource_type: int
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	var stored_cells: Array = (
		resource_cells_by_type.get(
			resource_type,
			[]
		)
	)

	for cell in stored_cells:
		result.append(
			Vector2i(cell)
		)

	return result
