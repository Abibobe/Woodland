class_name GameManager
extends Node2D


@onready var inventory: ResourceInventory = $ResourceInventory

@onready var player_interaction: PlayerInteraction = (
	$Actors/Player/PlayerInteraction
)
@onready var hud: HUD = $Interface/HUD

func _ready() -> void:
	player_interaction.resource_collected.connect(
		_on_resource_collected
	)

	inventory.resource_changed.connect(
		_on_inventory_resource_changed
	)
	_update_entire_hud()


func _on_resource_collected(
	resource_type: int,
	amount: int
) -> void:
	inventory.add_resource(
		resource_type,
		amount
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
