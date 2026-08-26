class_name GameManager
extends Node2D


@onready var inventory: ResourceInventory = $ResourceInventory

@onready var player_interaction: PlayerInteraction = (
	$Actors/Player/PlayerInteraction
)
@onready var hud: HUD = $Interface/HUD

@onready var player: Player = $Actors/Player
@onready var camp_menu: CampMenu = $Interface/CampMenu

var active_camp: Camp


func _ready() -> void:
	player_interaction.interaction_completed.connect(
		_on_interaction_completed
	)

	inventory.resource_changed.connect(
		_on_inventory_resource_changed
	)
	
	player_interaction.interaction_prompt_changed.connect(
		_on_interaction_prompt_changed
	)
	
	camp_menu.build_requested.connect(
		_on_camp_build_requested
	)

	camp_menu.close_requested.connect(
		_close_camp_menu
	)
	
	_update_entire_hud()


func _on_interaction_completed(
	result: Dictionary
) -> void:
	var action: String = result.get(
		"action",
		""
	)

	match action:
		"resource_collected":
			var resource_type := int(
				result.get("resource_type", -1)
			)

			var amount := int(
				result.get("amount", 0)
			)

			inventory.add_resource(
				resource_type,
				amount
			)

		"camp_opened":
			var camp := result.get("camp") as Camp

			if camp != null:
				_open_camp_menu(camp)
		_:
			push_warning(
				"Unknown interaction action: %s"
				% action
			)


func _on_inventory_resource_changed(
	resource_type: int,
	new_amount: int
) -> void:
	hud.set_resource_amount(
		resource_type,
		new_amount
	)


func _update_entire_hud() -> void:
	hud.set_resource_amount(
		ResourceNode.ResourceType.WOOD,
		inventory.get_amount(ResourceNode.ResourceType.WOOD)
	)

	hud.set_resource_amount(
		ResourceNode.ResourceType.STONE,
		inventory.get_amount(ResourceNode.ResourceType.STONE)
	)

	hud.set_resource_amount(
		ResourceNode.ResourceType.FOOD,
		inventory.get_amount(ResourceNode.ResourceType.FOOD)
	)


func _on_interaction_prompt_changed(text: String) -> void:
	if text.is_empty():
		hud.hide_interaction_prompt()
		return

	hud.show_interaction_prompt(text)


func _open_camp_menu(camp: Camp) -> void:
	active_camp = camp
	print("CCC")
	hud.hide_interaction_prompt()
	
	player.set_movement_enabled(false)
	player_interaction.set_process_unhandled_input(false)
	

	_refresh_camp_menu()


func _refresh_camp_menu() -> void:
	if active_camp == null:
		return

	var costs := active_camp.get_next_stage_cost()
	var is_complete := costs.is_empty()

	camp_menu.open_menu(
		active_camp.get_next_stage_name(),
		_format_cost(costs),
		_can_afford(costs),
		is_complete
	)


func _on_camp_build_requested() -> void:
	if active_camp == null:
		return

	var costs := active_camp.get_next_stage_cost()

	if not _can_afford(costs):
		camp_menu.show_message("Not enough resources")
		return

	_pay_cost(costs)
	active_camp.advance_construction()

	_refresh_camp_menu()


func _can_afford(costs: Dictionary) -> bool:
	for resource_type in costs:
		var required_amount := int(costs[resource_type])

		if not inventory.has_resources(
			int(resource_type),
			required_amount
		):
			return false

	return true


func _pay_cost(costs: Dictionary) -> void:
	for resource_type in costs:
		inventory.remove_resource(
			int(resource_type),
			int(costs[resource_type])
		)


func _format_cost(costs: Dictionary) -> String:
	if costs.is_empty():
		return ""

	var parts := PackedStringArray()

	for resource_type in costs:
		var resource_name := _get_resource_name(
			int(resource_type)
		)

		parts.append(
			"%s %s" % [
				costs[resource_type],
				resource_name
			]
		)

	return ", ".join(parts)


func _get_resource_name(resource_type: int) -> String:
	match resource_type:
		ResourceNode.ResourceType.WOOD:
			return "Wood"

		ResourceNode.ResourceType.STONE:
			return "Stone"

		ResourceNode.ResourceType.FOOD:
			return "Food"

	return "Unknown"


func _close_camp_menu() -> void:
	camp_menu.close_menu()
	active_camp = null

	player.set_movement_enabled(true)
	player_interaction.set_process_unhandled_input(true)
	player_interaction.refresh_prompt()
	
	
