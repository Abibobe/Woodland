class_name PlayerBackpack
extends Node


signal resource_changed(
	resource_type: int,
	new_amount: int
)

signal weight_changed(
	current_weight: int,
	maximum_weight: int
)

signal backpack_full(resource_type: int)


const RESOURCE_WEIGHTS := {
	ResourceTypes.Type.WOOD: 2,
	ResourceTypes.Type.STONE: 3,
	ResourceTypes.Type.FOOD: 1
}


@export_range(1, 100, 1)
var maximum_weight: int = 12


var carried_resources: Dictionary = {}


func _ready() -> void:
	carried_resources = {
		ResourceTypes.Type.WOOD: 0,
		ResourceTypes.Type.STONE: 0,
		ResourceTypes.Type.FOOD: 0
	}

	_emit_weight_changed()


func get_current_weight() -> int:
	var total_weight := 0

	for resource_type in carried_resources:
		var amount := get_amount(
			int(resource_type)
		)

		var resource_weight := get_resource_weight(
			int(resource_type)
		)

		total_weight += amount * resource_weight

	return total_weight


func get_available_weight() -> int:
	return maximum_weight - get_current_weight()


func get_resource_weight(
	resource_type: int
) -> int:
	return int(
		RESOURCE_WEIGHTS.get(
			resource_type,
			0
		)
	)


func can_add(
	resource_type: int,
	amount: int = 1
) -> bool:
	if amount <= 0:
		return false

	var resource_weight := get_resource_weight(
		resource_type
	)

	if resource_weight <= 0:
		push_warning(
			"Unknown backpack resource type: %s"
			% resource_type
		)
		return false

	var added_weight := resource_weight * amount

	return (
		get_current_weight() + added_weight
		<= maximum_weight
	)


func add_resource(
	resource_type: int,
	amount: int = 1
) -> bool:
	if not can_add(resource_type, amount):
		backpack_full.emit(resource_type)
		return false

	var new_amount := (
		get_amount(resource_type) + amount
	)

	carried_resources[resource_type] = new_amount

	resource_changed.emit(
		resource_type,
		new_amount
	)

	_emit_weight_changed()
	return true


func get_amount(resource_type: int) -> int:
	return int(
		carried_resources.get(
			resource_type,
			0
		)
	)

func has_resource(
	resource_type: ResourceTypes.Type,
	amount: int = 1
) -> bool:
	return get_amount(resource_type) >= amount


func remove_resource(
	resource_type: ResourceTypes.Type,
	amount: int = 1
) -> bool:
	if amount <= 0:
		return false

	if not has_resource(resource_type, amount):
		return false

	carried_resources[resource_type] -= amount

	resource_changed.emit(
		resource_type,
		carried_resources[resource_type]
	)

	_emit_weight_changed()

	return true


func get_all_resources() -> Dictionary:
	return carried_resources.duplicate()


func is_empty() -> bool:
	for amount in carried_resources.values():
		if int(amount) > 0:
			return false

	return true


func take_all() -> Dictionary:
	var delivered_resources := (
		carried_resources.duplicate()
	)

	for resource_type in carried_resources:
		carried_resources[resource_type] = 0

		resource_changed.emit(
			int(resource_type),
			0
		)

	_emit_weight_changed()

	return delivered_resources


func _emit_weight_changed() -> void:
	weight_changed.emit(
		get_current_weight(),
		maximum_weight
	)
