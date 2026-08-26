class_name PlayerInteraction
extends Area2D


signal resource_collected(
	resource_type: int,
	amount: int
)


var nearby_resources: Array[ResourceNode] = []


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact()


func interact() -> void:
	var resource := _get_closest_resource()

	if resource == null:
		return

	var collected_amount := resource.gather(1)

	if collected_amount <= 0:
		return

	resource_collected.emit(
		resource.resource_type,
		collected_amount
	)

	print(
		"Collected ",
		collected_amount,
		" ",
		resource.get_resource_name()
	)


func _get_closest_resource() -> ResourceNode:
	var closest_resource: ResourceNode = null
	var closest_distance := INF

	for resource in nearby_resources:
		if not is_instance_valid(resource):
			continue

		var distance := global_position.distance_to(
			resource.global_position
		)

		if distance < closest_distance:
			closest_distance = distance
			closest_resource = resource

	return closest_resource


func _on_body_entered(body: Node2D) -> void:
	if body is ResourceNode:
		nearby_resources.append(body)


func _on_body_exited(body: Node2D) -> void:
	if body is ResourceNode:
		nearby_resources.erase(body)
