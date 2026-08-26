class_name ResourceTypes
extends RefCounted


enum Type {
	WOOD,
	STONE,
	FOOD
}


static func get_display_name(
	resource_type: Type
) -> String:
	match resource_type:
		Type.WOOD:
			return "Wood"

		Type.STONE:
			return "Stone"

		Type.FOOD:
			return "Food"

	return "Unknown"
