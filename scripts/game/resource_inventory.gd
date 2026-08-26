class_name ResourceInventory
extends Node


signal resource_changed(
	resource_type: int,
	new_amount: int
)


@export_category("Starting Resources")
@export_range(0, 100) var starting_wood: int = 0
@export_range(0, 100) var starting_stone: int = 0
@export_range(0, 100) var starting_food: int = 0


var resources: Dictionary = {}


func _ready() -> void:
	resources = {
		ResourceNode.ResourceType.WOOD: starting_wood,
		ResourceNode.ResourceType.STONE: starting_stone,
		ResourceNode.ResourceType.FOOD: starting_food
	}


func add_resource(
	resource_type: int,
	amount: int
) -> void:
	if amount <= 0:
		return

	var current_amount := get_amount(resource_type)
	var new_amount := current_amount + amount

	resources[resource_type] = new_amount

	resource_changed.emit(
		resource_type,
		new_amount
	)


func get_amount(resource_type: int) -> int:
	return resources.get(resource_type, 0)


func has_resources(
	resource_type: int,
	required_amount: int
) -> bool:
	return get_amount(resource_type) >= required_amount


func remove_resource(
	resource_type: int,
	amount: int
) -> bool:
	if amount <= 0:
		return false

	if not has_resources(resource_type, amount):
		return false

	resources[resource_type] -= amount

	resource_changed.emit(
		resource_type,
		resources[resource_type]
	)

	return true


func get_all_resources() -> Dictionary:
	return resources.duplicate()
