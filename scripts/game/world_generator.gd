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
