class_name PlayerInteraction
extends Area2D


signal interaction_completed(result: Dictionary)
signal interaction_prompt_changed(text: String)


var nearby_targets: Array[InteractionTarget] = []

var highlighted_target: InteractionTarget = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact()


func interact() -> void:
	var target := _get_closest_target()

	if target == null:
		return

	var result := target.interact()

	if not result.is_empty():
		interaction_completed.emit(result)

	if target.is_queued_for_deletion():
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


func _on_body_exited(body: Node2D) -> void:
	if body is InteractionTarget:
		nearby_targets.erase(body)
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
