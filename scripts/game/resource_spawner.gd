class_name ResourceSpawner
extends Node2D


@export_category("Resource Scene")
@export var resource_scene: PackedScene

@export_category("Resource Counts")
@export_range(0, 200) var tree_count: int = 75
@export_range(0, 100) var rock_count: int = 14
@export_range(0, 100) var bush_count: int = 18

@export_category("Starting Area")
@export_range(1, 10) var clear_radius: int = 4

var random := RandomNumberGenerator.new()
var occupied_cells: Dictionary = {}


func generate_resources(
	seed_value: int,
	map_width: int,
	map_height: int,
	tile_size: int
) -> void:
	_clear_existing_resources()

	random.seed = seed_value + 9187
	occupied_cells.clear()

	var map_center := Vector2i(
		map_width / 2,
		map_height / 2
	)

	_spawn_resource_type(
		ResourceNode.ResourceType.WOOD,
		tree_count,
		map_width,
		map_height,
		tile_size,
		map_center
	)

	_spawn_resource_type(
		ResourceNode.ResourceType.STONE,
		rock_count,
		map_width,
		map_height,
		tile_size,
		map_center
	)

	_spawn_resource_type(
		ResourceNode.ResourceType.FOOD,
		bush_count,
		map_width,
		map_height,
		tile_size,
		map_center
	)


func _spawn_resource_type(
	resource_type: int,
	amount: int,
	map_width: int,
	map_height: int,
	tile_size: int,
	map_center: Vector2i
) -> void:
	for resource_index in range(amount):
		var cell := _find_available_cell(
			map_width,
			map_height,
			map_center
		)

		if cell == Vector2i(-1, -1):
			push_warning(
				"Could not find space for resource %s."
				% resource_index
			)
			return

		_spawn_resource(resource_type, cell, tile_size)


func _find_available_cell(
	map_width: int,
	map_height: int,
	map_center: Vector2i
) -> Vector2i:
	var maximum_attempts := 100

	for attempt in range(maximum_attempts):
		var candidate := Vector2i(
			random.randi_range(1, map_width - 2),
			random.randi_range(2, map_height - 2)
		)

		if occupied_cells.has(candidate):
			continue

		if Vector2(candidate).distance_to(Vector2(map_center)) < clear_radius:
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

	add_child(resource)

	resource.position = Vector2(
		(cell.x + 0.5) * tile_size,
		(cell.y + 0.5) * tile_size
	)


func _clear_existing_resources() -> void:
	for child in get_children():
		child.queue_free()
