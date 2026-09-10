class_name WorldGenerator
extends Node2D


@export_category("Map Size")
@export var map_width: int = 40 
@export var map_height: int = 23
@export var tile_size: int = 32

@export_category("Generation")
@export var world_seed: int = 0
@export_range(-1.0, 1.0, 0.05) var soil_threshold: float = 0.25


@onready var ground_renderer: GroundRenderer = $GroundRenderer
@onready var resource_spawner: ResourceSpawner = $ResourceSpawner
@onready var forest_decorator: ForestDecorator = (
	$ForestDecorator
)
@onready var forest_life: ForestLife = (
	$ForestLife
)

@onready var forest_cluster_layer: ForestClusterLayer = (
	$ForestClusterLayer
)



var noise := FastNoiseLite.new()
var generated_seed: int
var ground_cells: Array = []


func _ready() -> void:
	generate_world()


func generate_world() -> void:
	generated_seed = world_seed

	if generated_seed == 0:
		generated_seed = randi_range(
			1,
			2_000_000_000
		)

	noise.seed = generated_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.08

	_generate_ground_data()

	ground_renderer.render_ground(
		ground_cells,
		tile_size
	)

	resource_spawner.generate_resources(
		generated_seed,
		map_width,
		map_height,
		tile_size
	)
	
	var map_center := Vector2i(
		map_width / 2,
		map_height / 2
	)
	
	forest_cluster_layer.generate_clusters(
		generated_seed,
		ground_cells,
		map_width,
		map_height,
		tile_size,
		map_center,
		resource_spawner.clear_radius,
		resource_spawner.get_occupied_cells()
	)


	forest_decorator.generate_decorations(
		generated_seed,
		ground_cells,
		map_width,
		map_height,
		tile_size,
		map_center,
		resource_spawner.clear_radius,
		resource_spawner.get_occupied_cells(),
		resource_spawner.get_resource_cells(
			ResourceTypes.Type.WOOD
		)
	)

	forest_life.generate_life(
		generated_seed,
		map_width,
		map_height,
		tile_size,
		forest_decorator.get_flower_positions(),
		forest_decorator.get_sheltered_positions()
	)

	print("Generated world with seed: ", generated_seed)


func _generate_ground_data() -> void:
	ground_cells.clear()

	for y in range(map_height):
		var row: Array[bool] = []

		for x in range(map_width):
			row.append(
				_is_soil_tile(x, y)
			)

		ground_cells.append(row)


func _is_soil_tile(x: int, y: int) -> bool:
	var noise_value := noise.get_noise_2d(x, y)

	return noise_value > soil_threshold
