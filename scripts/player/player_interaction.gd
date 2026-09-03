class_name PlayerInteraction
extends Area2D


signal interaction_completed(result: Dictionary)
signal interaction_prompt_changed(text: String)
signal interaction_target_entered(
	target: InteractionTarget
)

signal interaction_target_exited(
	target: InteractionTarget
)

var nearby_targets: Array[InteractionTarget] = []

var highlighted_target: InteractionTarget = null
var active_gathering_resource: ResourceNode
var gathering_request_sent := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if not is_processing_unhandled_input():
		_stop_gathering()
		return

	if not Input.is_action_pressed("interact"):
		_stop_gathering()
		return

	# Automatically begin the next available resource while E
	# remains held.
	if not is_instance_valid(active_gathering_resource):
		var next_target := _get_closest_target()

		if next_target is ResourceNode:
			_start_gathering(
				next_target as ResourceNode
			)

		return

	if not has_target(active_gathering_resource):
		_stop_gathering()
		return

	var player := get_parent() as Player

	if player == null:
		_stop_gathering()
		return

	if player.velocity.length_squared() > 0.0:
		active_gathering_resource.set_gathering_active(
			false
		)
		return

	active_gathering_resource.set_gathering_active(true)

	interaction_prompt_changed.emit(
		active_gathering_resource.get_interaction_text()
	)

	if gathering_request_sent:
		return

	if active_gathering_resource.advance_gathering(delta):
		_request_gathering_completion()

func _start_gathering(resource: ResourceNode) -> void:
	if resource == null:
		return

	if resource.is_depleted:
		return

	active_gathering_resource = resource
	gathering_request_sent = false
	
	resource.set_gathering_active(true)

func _stop_gathering() -> void:
	if is_instance_valid(active_gathering_resource):
		active_gathering_resource.set_gathering_active(
			false
		)

	active_gathering_resource = null
	gathering_request_sent = false


func _request_gathering_completion() -> void:
	if not is_instance_valid(active_gathering_resource):
		return

	gathering_request_sent = true

	var resource := active_gathering_resource
	var result := resource.interact()

	if not result.is_empty():
		interaction_completed.emit(result)

	# The resource may have been depleted and queued for deletion
	# by GameManager during the signal.
	if not is_instance_valid(resource):
		active_gathering_resource = null
		return

	if resource.is_depleted:
		resource.set_gathering_active(false)
		active_gathering_resource = null
		return

	# A successful collection resets progress to zero. Unlocking
	# here lets the next unit begin while E remains held.
	if not resource.is_gathering_complete():
		gathering_request_sent = false
		resource.set_gathering_active(true)



func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if event is InputEventKey and event.echo:
			return

		var target := _get_closest_target()

		if target is ResourceNode:
			_start_gathering(target as ResourceNode)
			get_viewport().set_input_as_handled()
			return

		# Camps and other targets still use a single press.
		interact()
		return

	if event.is_action_released("interact"):
		_stop_gathering()



func interact() -> void:
	var target := _get_closest_target()

	if target == null:
		return

	var result := target.interact()

	if not result.is_empty():
		interaction_completed.emit(result)

	var target_depleted := bool(
		result.get("target_depleted", false)
	)

	if (
		target_depleted
		or target.is_queued_for_deletion()
	):
		nearby_targets.erase(target)
	
	# Opening the camp menu disables interaction.
	# In that case, do not show the prompt again.
	if not is_processing_unhandled_input():
		return

	_refresh_interaction_prompt()


func _get_closest_target() -> InteractionTarget:
	var closest_target: InteractionTarget = null
	var closest_distance := INF

	for target in nearby_targets:
		if not is_instance_valid(target):
			continue

		if target.is_queued_for_deletion():
			continue

		var distance := global_position.distance_to(
			target.global_position
		)

		if distance < closest_distance:
			closest_distance = distance
			closest_target = target

	return closest_target


func _on_body_entered(body: Node2D) -> void:
	if body is InteractionTarget:
		if not nearby_targets.has(body):
			nearby_targets.append(body)

		_refresh_interaction_prompt()

		interaction_target_entered.emit(
			body
		)


func _on_body_exited(body: Node2D) -> void:
	if body is InteractionTarget:
		nearby_targets.erase(body)

		interaction_target_exited.emit(
			body
		)

		_refresh_interaction_prompt()


func _refresh_interaction_prompt() -> void:
	var target := _get_closest_target()
	
	_set_highlighted_target(target)

	if target == null:
		interaction_prompt_changed.emit("")
		return

	interaction_prompt_changed.emit(
		target.get_interaction_text()
	)


func refresh_prompt() -> void:
	_refresh_interaction_prompt()


func _set_highlighted_target(
	new_target: InteractionTarget
) -> void:
	if highlighted_target == new_target:
		return

	if (
		is_instance_valid(highlighted_target)
		and highlighted_target.has_method("set_highlighted")
	):
		highlighted_target.set_highlighted(false)

	highlighted_target = new_target

	if (
		is_instance_valid(highlighted_target)
		and highlighted_target.has_method("set_highlighted")
	):
		highlighted_target.set_highlighted(true)

func remove_target(
	target: InteractionTarget
) -> void:
	nearby_targets.erase(target)

	if highlighted_target == target:
		_set_highlighted_target(null)

	_refresh_interaction_prompt()


func has_target(
	target: InteractionTarget
) -> bool:
	return (
		is_instance_valid(target)
		and nearby_targets.has(target)
	)
